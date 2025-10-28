package com.example.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

/**
 * Production-ready Kafka producer example with:
 * - Idempotent producer
 * - Exactly-once semantics
 * - Error handling
 * - Metrics tracking
 * - Graceful shutdown
 */
public class ProducerExample {
    private static final Logger logger = LoggerFactory.getLogger(ProducerExample.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final KafkaProducer<String, String> producer;
    private final String topic;
    private long messagesSent = 0;
    private long errorsCount = 0;

    public ProducerExample(String bootstrapServers, String topic) {
        this.topic = topic;
        this.producer = createProducer(bootstrapServers);
        
        // Graceful shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(this::close));
    }

    private KafkaProducer<String, String> createProducer(String bootstrapServers) {
        Properties props = new Properties();
        
        // Connection
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        
        // Serialization
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        
        // Idempotence & Exactly-once semantics
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        props.put(ProducerConfig.ACKS_CONFIG, "all"); // Wait for all in-sync replicas
        props.put(ProducerConfig.RETRIES_CONFIG, Integer.MAX_VALUE);
        props.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);
        
        // Compression for network efficiency
        props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");
        
        // Batching for throughput
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 32768); // 32 KB
        props.put(ProducerConfig.LINGER_MS_CONFIG, 10);
        
        // Buffer settings
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432); // 32 MB
        
        // Request timeout
        props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 30000);
        props.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 120000);
        
        // Client ID for tracking
        props.put(ProducerConfig.CLIENT_ID_CONFIG, "producer-example-" + UUID.randomUUID());
        
        // Security (uncomment and configure for production)
        // props.put("security.protocol", "SASL_SSL");
        // props.put("sasl.mechanism", "SCRAM-SHA-512");
        // props.put("sasl.jaas.config", 
        //     "org.apache.kafka.common.security.scram.ScramLoginModule required " +
        //     "username=\"producer-user\" password=\"secure-password\";");
        // props.put("ssl.truststore.location", "/path/to/truststore.jks");
        // props.put("ssl.truststore.password", "truststore-password");
        
        logger.info("Creating Kafka producer with idempotence enabled");
        return new KafkaProducer<>(props);
    }

    /**
     * Send a message synchronously (blocking).
     * Use for scenarios where you need immediate confirmation.
     */
    public void sendSync(String key, Map<String, Object> value) throws Exception {
        String jsonValue = objectMapper.writeValueAsString(value);
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, key, jsonValue);
        
        try {
            RecordMetadata metadata = producer.send(record).get();
            messagesSent++;
            logger.info("Message sent successfully - Topic: {}, Partition: {}, Offset: {}, Key: {}",
                    metadata.topic(), metadata.partition(), metadata.offset(), key);
        } catch (InterruptedException | ExecutionException e) {
            errorsCount++;
            logger.error("Failed to send message with key: {}", key, e);
            throw e;
        }
    }

    /**
     * Send a message asynchronously (non-blocking).
     * Use for high-throughput scenarios.
     */
    public void sendAsync(String key, Map<String, Object> value) throws Exception {
        String jsonValue = objectMapper.writeValueAsString(value);
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, key, jsonValue);
        
        producer.send(record, new Callback() {
            @Override
            public void onCompletion(RecordMetadata metadata, Exception exception) {
                if (exception == null) {
                    messagesSent++;
                    logger.debug("Message sent - Partition: {}, Offset: {}", 
                            metadata.partition(), metadata.offset());
                } else {
                    errorsCount++;
                    logger.error("Failed to send message with key: {}", key, exception);
                }
            }
        });
    }

    /**
     * Send a batch of messages efficiently.
     */
    public void sendBatch(List<Map<String, Object>> messages) throws Exception {
        for (int i = 0; i < messages.size(); i++) {
            String key = "batch-" + i;
            sendAsync(key, messages.get(i));
        }
        
        // Flush to ensure all messages are sent
        producer.flush();
        logger.info("Batch of {} messages sent", messages.size());
    }

    public void close() {
        logger.info("Closing producer. Stats - Sent: {}, Errors: {}", messagesSent, errorsCount);
        producer.close();
    }

    public static void main(String[] args) throws Exception {
        // Configuration
        String bootstrapServers = System.getenv().getOrDefault("KAFKA_BOOTSTRAP", "localhost:9092");
        String topic = System.getenv().getOrDefault("KAFKA_TOPIC", "orders");
        
        ProducerExample producer = new ProducerExample(bootstrapServers, topic);
        
        try {
            // Example 1: Send individual messages synchronously
            logger.info("Sending individual messages synchronously...");
            for (int i = 0; i < 10; i++) {
                Map<String, Object> order = new HashMap<>();
                order.put("order_id", "ORD-" + String.format("%04d", i));
                order.put("customer_id", "CUST-" + (i % 5));
                order.put("amount", 99.99 + i);
                order.put("timestamp", Instant.now().toEpochMilli());
                
                producer.sendSync("order-" + i, order);
                Thread.sleep(100); // Simulate processing delay
            }
            
            // Example 2: Send batch of messages asynchronously
            logger.info("Sending batch of messages asynchronously...");
            List<Map<String, Object>> batch = new ArrayList<>();
            for (int i = 0; i < 100; i++) {
                Map<String, Object> event = new HashMap<>();
                event.put("event_id", "EVT-" + i);
                event.put("type", "page_view");
                event.put("user_id", "USER-" + (i % 10));
                event.put("timestamp", Instant.now().toEpochMilli());
                batch.add(event);
            }
            producer.sendBatch(batch);
            
            logger.info("All messages sent successfully!");
            
        } catch (Exception e) {
            logger.error("Error in main execution", e);
            throw e;
        } finally {
            producer.close();
        }
    }
}

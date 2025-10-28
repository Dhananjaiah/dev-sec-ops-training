"""
Kafka Producer Example with Best Practices
- Idempotent producer
- Compression
- Error handling
- Metrics
"""

import json
import time
from typing import Dict, Any
from kafka import KafkaProducer
from kafka.errors import KafkaError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class KafkaProducerExample:
    def __init__(self, bootstrap_servers: str, topic: str):
        """
        Initialize Kafka producer with production-ready settings.
        
        Args:
            bootstrap_servers: Comma-separated list of broker addresses
            topic: Topic to produce to
        """
        self.topic = topic
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers.split(','),
            
            # Serialization
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None,
            
            # Idempotence & Exactly-once semantics
            enable_idempotence=True,
            acks='all',  # Wait for all in-sync replicas
            retries=3,
            max_in_flight_requests_per_connection=5,
            
            # Compression for network efficiency
            compression_type='snappy',
            
            # Batching for throughput
            batch_size=16384,
            linger_ms=10,
            
            # Buffer settings
            buffer_memory=33554432,  # 32MB
            
            # Request timeout
            request_timeout_ms=30000,
            
            # Security (uncomment and configure for production)
            # security_protocol='SASL_SSL',
            # sasl_mechanism='SCRAM-SHA-512',
            # sasl_plain_username='producer-user',
            # sasl_plain_password='secure-password',
            # ssl_cafile='/path/to/ca-cert',
        )
        
        self.messages_sent = 0
        self.errors = 0
        
    def send_message(self, key: str, value: Dict[str, Any]) -> None:
        """
        Send a message to Kafka with error handling.
        
        Args:
            key: Message key for partitioning
            value: Message value (will be JSON serialized)
        """
        try:
            future = self.producer.send(
                self.topic,
                key=key,
                value=value
            )
            
            # Wait for send to complete (synchronous for example)
            # In production, use async callbacks for better throughput
            record_metadata = future.get(timeout=10)
            
            self.messages_sent += 1
            logger.info(
                f"Message sent successfully: "
                f"topic={record_metadata.topic}, "
                f"partition={record_metadata.partition}, "
                f"offset={record_metadata.offset}"
            )
            
        except KafkaError as e:
            self.errors += 1
            logger.error(f"Failed to send message: {e}")
            raise
    
    def send_batch(self, messages: list) -> None:
        """
        Send multiple messages efficiently.
        
        Args:
            messages: List of (key, value) tuples
        """
        for key, value in messages:
            try:
                # Async send for better throughput
                self.producer.send(self.topic, key=key, value=value)
            except Exception as e:
                logger.error(f"Error queuing message: {e}")
        
        # Flush all pending messages
        self.producer.flush()
        logger.info(f"Batch of {len(messages)} messages sent")
    
    def close(self):
        """Gracefully close the producer."""
        logger.info(f"Closing producer. Stats: sent={self.messages_sent}, errors={self.errors}")
        self.producer.close()


def main():
    """Example usage"""
    bootstrap_servers = "localhost:9092"
    topic = "orders"
    
    producer = KafkaProducerExample(bootstrap_servers, topic)
    
    try:
        # Send individual messages
        for i in range(10):
            order = {
                "order_id": f"ORD-{i:04d}",
                "customer_id": f"CUST-{i % 5}",
                "amount": 99.99 + i,
                "timestamp": int(time.time() * 1000)
            }
            producer.send_message(key=f"order-{i}", value=order)
            time.sleep(0.1)
        
        # Send batch
        batch_messages = [
            (f"batch-{i}", {"batch_id": i, "data": f"value-{i}"})
            for i in range(100)
        ]
        producer.send_batch(batch_messages)
        
    finally:
        producer.close()


if __name__ == "__main__":
    main()

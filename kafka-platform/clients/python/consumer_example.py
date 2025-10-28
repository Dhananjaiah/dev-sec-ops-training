"""
Kafka Consumer Example with Best Practices
- Consumer group coordination
- Error handling
- Offset management
- Graceful shutdown
"""

import json
import signal
import sys
from kafka import KafkaConsumer
from kafka.errors import KafkaError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class KafkaConsumerExample:
    def __init__(self, bootstrap_servers: str, topic: str, group_id: str):
        """
        Initialize Kafka consumer with production-ready settings.
        
        Args:
            bootstrap_servers: Comma-separated list of broker addresses
            topic: Topic to consume from
            group_id: Consumer group ID
        """
        self.topic = topic
        self.running = True
        
        self.consumer = KafkaConsumer(
            topic,
            bootstrap_servers=bootstrap_servers.split(','),
            group_id=group_id,
            
            # Deserialization
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda k: k.decode('utf-8') if k else None,
            
            # Offset management
            auto_offset_reset='earliest',  # Start from beginning if no offset
            enable_auto_commit=False,  # Manual commit for reliability
            
            # Consumer settings
            max_poll_records=500,
            max_poll_interval_ms=300000,  # 5 minutes
            session_timeout_ms=30000,     # 30 seconds
            heartbeat_interval_ms=10000,  # 10 seconds
            
            # Fetch settings for throughput
            fetch_min_bytes=1,
            fetch_max_wait_ms=500,
            max_partition_fetch_bytes=1048576,  # 1MB
            
            # Security (uncomment and configure for production)
            # security_protocol='SASL_SSL',
            # sasl_mechanism='SCRAM-SHA-512',
            # sasl_plain_username='consumer-user',
            # sasl_plain_password='secure-password',
            # ssl_cafile='/path/to/ca-cert',
        )
        
        self.messages_processed = 0
        self.errors = 0
        
        # Handle graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully."""
        logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
    
    def process_message(self, message):
        """
        Process a single message.
        Override this method with your business logic.
        
        Args:
            message: Kafka consumer record
        """
        logger.info(
            f"Processing message: "
            f"topic={message.topic}, "
            f"partition={message.partition}, "
            f"offset={message.offset}, "
            f"key={message.key}, "
            f"value={message.value}"
        )
        
        # Add your business logic here
        # Example: validate, transform, store, etc.
        
        self.messages_processed += 1
    
    def consume(self):
        """
        Main consumption loop with error handling and manual commits.
        """
        logger.info(f"Starting consumer for topic: {self.topic}")
        
        try:
            while self.running:
                # Poll for messages
                records = self.consumer.poll(timeout_ms=1000, max_records=100)
                
                if not records:
                    continue
                
                # Process messages
                for topic_partition, messages in records.items():
                    for message in messages:
                        try:
                            self.process_message(message)
                        except Exception as e:
                            self.errors += 1
                            logger.error(f"Error processing message: {e}")
                            # Decide on error handling strategy:
                            # - Skip and continue
                            # - Retry
                            # - Send to DLQ
                            # - Stop consumer
                            continue
                    
                    # Commit offsets after processing batch
                    try:
                        self.consumer.commit()
                        logger.debug(f"Committed offsets for {topic_partition}")
                    except KafkaError as e:
                        logger.error(f"Failed to commit offsets: {e}")
                
        except Exception as e:
            logger.error(f"Unexpected error in consume loop: {e}")
            raise
        
        finally:
            self.close()
    
    def close(self):
        """Gracefully close the consumer."""
        logger.info(
            f"Closing consumer. Stats: "
            f"processed={self.messages_processed}, errors={self.errors}"
        )
        self.consumer.close()


def main():
    """Example usage"""
    bootstrap_servers = "localhost:9092"
    topic = "orders"
    group_id = "order-processor"
    
    consumer = KafkaConsumerExample(bootstrap_servers, topic, group_id)
    
    # Start consuming
    consumer.consume()


if __name__ == "__main__":
    main()

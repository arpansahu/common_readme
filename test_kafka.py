from kafka import KafkaAdminClient
import ssl

# Create SSL context - certificate covers *.arpansahu.space so hostname checking works
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = True  # Safe because cert covers kafka-server.arpansahu.space
ssl_context.verify_mode = ssl.CERT_REQUIRED  # Verify the certificate

admin_client = KafkaAdminClient(
    bootstrap_servers='kafka-server.arpansahu.space:9092',
    security_protocol='SASL_SSL',
    sasl_mechanism='PLAIN',
    sasl_plain_username='arpansahu',
    sasl_plain_password='Kafka@2026',
    ssl_context=ssl_context,
    request_timeout_ms=10000,
    api_version_auto_timeout_ms=5000
)

print("Connecting to Kafka...")
topics = admin_client.list_topics()
print(f"Connected! Topics: {topics}")
admin_client.close()
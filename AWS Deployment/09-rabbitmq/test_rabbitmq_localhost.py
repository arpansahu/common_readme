#!/usr/bin/env python3
"""
RabbitMQ Server Connection Test (Localhost)
Tests RabbitMQ connectivity from the server using localhost connection
Run this script ON THE SERVER
"""

import sys

try:
    import pika
except ImportError:
    print("✗ Error: pika not installed")
    print("Install with: pip3 install pika")
    sys.exit(1)

def test_rabbitmq():
    try:
        print("=== Testing RabbitMQ Connection from Server (Localhost) ===\n")
        
        # Connection parameters for localhost
        host = 'localhost'
        port = 5672
        username = '${RABBITMQ_USER}'
        password = '${RABBITMQ_PASS}'
        
        print(f"Connecting to RabbitMQ at {host}:{port}...")
        
        # Create credentials
        credentials = pika.PlainCredentials(username, password)
        
        # Create connection parameters
        parameters = pika.ConnectionParameters(
            host=host,
            port=port,
            credentials=credentials,
            connection_attempts=3,
            retry_delay=2
        )
        
        # Establish connection
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        print("✓ Connection successful\n")
        
        # Test queue declaration
        queue_name = 'test_queue_server'
        channel.queue_declare(queue=queue_name, durable=False, auto_delete=True)
        print(f"✓ Queue declared: {queue_name}\n")
        
        # Test message publishing
        test_message = 'Hello from Server!'
        channel.basic_publish(
            exchange='',
            routing_key=queue_name,
            body=test_message
        )
        print(f"✓ Message published: {test_message}\n")
        
        # Test message consumption
        method_frame, header_frame, body = channel.basic_get(queue=queue_name, auto_ack=True)
        if method_frame:
            print(f"✓ Message received: {body.decode()}\n")
        else:
            print("✗ No message received\n")
            return 1
        
        # Clean up
        channel.queue_delete(queue=queue_name)
        print(f"✓ Queue deleted: {queue_name}\n")
        
        # Get server properties
        print(f"✓ RabbitMQ server version: {connection.server_properties.get('version', 'unknown')}\n")
        
        connection.close()
        
        print("✓ All tests passed!")
        print("✓ RabbitMQ is working correctly on localhost\n")
        return 0
        
    except pika.exceptions.AMQPConnectionError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if RabbitMQ is running: docker ps | grep rabbitmq")
        return 1
    except pika.exceptions.ProbableAuthenticationError as e:
        print(f"✗ Authentication Error: {e}")
        print("  Check username and password in .env file")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_rabbitmq())

#!/usr/bin/env python3
"""
RabbitMQ Server Connection Test
Tests RabbitMQ connectivity from the server using Python pika
"""

import pika
import sys

def test_rabbitmq():
    try:
        print("=== Testing RabbitMQ Connection from Server ===\n")
        
        # Connection parameters
        credentials = pika.PlainCredentials('${RABBITMQ_USER}', '${RABBITMQ_PASS}')
        parameters = pika.ConnectionParameters(
            host='127.0.0.1',
            port=5672,
            credentials=credentials
        )
        
        # Connect
        print("Connecting to RabbitMQ...")
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        print("✓ Connection successful\n")
        
        # Declare queue
        queue_name = 'test_queue'
        channel.queue_declare(queue=queue_name)
        print(f"✓ Queue declared: {queue_name}\n")
        
        # Send message
        message = 'Hello from Server!'
        channel.basic_publish(
            exchange='',
            routing_key=queue_name,
            body=message
        )
        print(f"✓ Message sent: {message}\n")
        
        # Get message
        method_frame, header_frame, body = channel.basic_get(queue=queue_name, auto_ack=True)
        if body:
            print(f"✓ Message received: {body.decode()}\n")
        
        # Clean up
        channel.queue_delete(queue=queue_name)
        connection.close()
        
        print("✓ All tests passed!")
        print("✓ RabbitMQ is working correctly\n")
        return 0
        
    except pika.exceptions.AMQPConnectionError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if RabbitMQ container is running: docker ps | grep rabbitmq")
        return 1
    except pika.exceptions.ProbableAuthenticationError as e:
        print(f"✗ Authentication Error: {e}")
        print("  Check your credentials in .env file")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_rabbitmq())

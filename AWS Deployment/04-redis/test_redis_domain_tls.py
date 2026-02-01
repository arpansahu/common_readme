#!/usr/bin/env python3
"""
Redis Mac Connection Test (Domain with TLS)
Tests Redis connectivity from your Mac through domain with TLS encryption
Run this script FROM YOUR MAC
"""

import sys
import ssl

try:
    import redis
except ImportError:
    print("✗ Error: redis package not installed")
    print("Install with: pip3 install redis")
    sys.exit(1)

def test_redis():
    try:
        print("=== Testing Redis Connection from Mac (Domain with TLS) ===\n")
        
        # Connection parameters for domain with TLS
        host = 'redis.arpansahu.space'
        port = 9551
        password = '${REDIS_PASSWORD}'
        
        print(f"Connecting to Redis at {host}:{port} (TLS)...")
        
        # Create SSL context
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        client = redis.Redis(
            host=host,
            port=port,
            password=password,
            decode_responses=True,
            ssl=True,
            ssl_cert_reqs='none',
            socket_connect_timeout=10
        )
        
        # Test connection
        client.ping()
        print("✓ Connection successful (TLS encrypted)\n")
        
        # Test SET
        test_key = 'test:mac:tls:key'
        test_value = 'Hello from Mac via TLS!'
        client.set(test_key, test_value, ex=60)
        print(f"✓ SET: {test_key} = {test_value}\n")
        
        # Test GET
        retrieved = client.get(test_key)
        print(f"✓ GET: {test_key} = {retrieved}\n")
        
        # Test DELETE
        client.delete(test_key)
        print(f"✓ DEL: {test_key}\n")
        
        # Get server info
        info = client.info('server')
        print(f"✓ Redis version: {info['redis_version']}\n")
        
        client.close()
        
        print("✓ All tests passed!")
        print("✓ Redis is working correctly via domain with TLS\n")
        print(f"Connection: {host}:{port} (TLS encrypted via nginx)")
        return 0
        
    except redis.ConnectionError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if nginx stream is configured and port 9551 is accessible")
        return 1
    except redis.AuthenticationError as e:
        print(f"✗ Authentication Error: {e}")
        print("  Check password")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_redis())

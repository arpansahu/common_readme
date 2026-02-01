#!/usr/bin/env python3
"""
Redis Server Connection Test (Localhost)
Tests Redis connectivity from the server using localhost connection
Run this script ON THE SERVER
"""

import sys

try:
    import redis
except ImportError:
    print("✗ Error: redis package not installed")
    print("Install with: pip3 install redis")
    sys.exit(1)

def test_redis():
    try:
        print("=== Testing Redis Connection from Server (Localhost) ===\n")
        
        # Connection parameters for localhost
        host = 'localhost'
        port = 6380
        password = '${REDIS_PASSWORD}'
        
        print(f"Connecting to Redis at {host}:{port}...")
        client = redis.Redis(
            host=host,
            port=port,
            password=password,
            decode_responses=True,
            socket_connect_timeout=5
        )
        
        # Test connection
        client.ping()
        print("✓ Connection successful\n")
        
        # Test SET
        test_key = 'test:server:key'
        test_value = 'Hello from Server!'
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
        print(f"✓ Uptime: {info['uptime_in_days']} days\n")
        
        client.close()
        
        print("✓ All tests passed!")
        print("✓ Redis is working correctly on localhost\n")
        return 0
        
    except redis.ConnectionError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if Redis is running: docker ps | grep redis")
        return 1
    except redis.AuthenticationError as e:
        print(f"✗ Authentication Error: {e}")
        print("  Check password in .env file")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_redis())

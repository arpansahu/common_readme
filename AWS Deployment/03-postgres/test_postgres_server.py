#!/usr/bin/env python3
"""
PostgreSQL Server Connection Test
Tests PostgreSQL connectivity from the server using psycopg2
"""

import sys

try:
    import psycopg2
except ImportError:
    print("✗ Error: psycopg2 not installed")
    print("Install with: pip3 install psycopg2-binary")
    sys.exit(1)

def test_postgres():
    try:
        print("=== Testing PostgreSQL Connection from Server ===\n")
        
        # Connection parameters - replace with your values
        conn_params = {
            'host': 'localhost',
            'port': 5432,
            'user': 'postgres',
            'password': '${POSTGRES_PASSWORD}',
            'database': 'postgres'
        }
        
        print(f"Connecting to PostgreSQL at {conn_params['host']}:{conn_params['port']}...")
        conn = psycopg2.connect(**conn_params)
        print("✓ Connection successful\n")
        
        # Get version
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✓ PostgreSQL version: {version.split(',')[0]}\n")
        
        # Test database operations
        cursor.execute("CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, data TEXT);")
        print("✓ Table created: test_table\n")
        
        cursor.execute("INSERT INTO test_table (data) VALUES (%s) RETURNING id;", ("Hello from Server!",))
        test_id = cursor.fetchone()[0]
        conn.commit()
        print(f"✓ Record inserted with ID: {test_id}\n")
        
        cursor.execute("SELECT * FROM test_table WHERE id = %s;", (test_id,))
        record = cursor.fetchone()
        print(f"✓ Record retrieved: ID={record[0]}, Data={record[1]}\n")
        
        # Clean up
        cursor.execute("DROP TABLE test_table;")
        conn.commit()
        print("✓ Test table dropped\n")
        
        cursor.close()
        conn.close()
        
        print("✓ All tests passed!")
        print("✓ PostgreSQL is working correctly\n")
        return 0
        
    except psycopg2.OperationalError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if PostgreSQL is running: sudo systemctl status postgresql")
        return 1
    except psycopg2.Error as e:
        print(f"✗ Database Error: {e}")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_postgres())

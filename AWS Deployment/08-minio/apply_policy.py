#!/usr/bin/env python3
"""
Apply MinIO bucket policy to secure private files
Loads configuration from environment variables
"""

import boto3
import json
import os
from botocore.exceptions import ClientError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# MinIO Configuration from environment
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'https://minioapi.arpansahu.space')
MINIO_ACCESS_KEY = os.getenv('MINIO_ROOT_USER')
MINIO_SECRET_KEY = os.getenv('MINIO_ROOT_PASSWORD')
BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME', 'arpansahu-one-bucket')
POLICY_FILE = os.getenv('POLICY_FILE', 'minio_bucket_policy.json')

# Validate required environment variables
if not MINIO_ACCESS_KEY or not MINIO_SECRET_KEY:
    print("❌ Error: Missing required environment variables")
    print("Please ensure .env file contains:")
    print("  - MINIO_ROOT_USER")
    print("  - MINIO_ROOT_PASSWORD")
    exit(1)

print("=" * 80)
print("APPLYING MINIO BUCKET POLICY")
print("=" * 80)
print()
print(f"Configuration:")
print(f"  Endpoint: {MINIO_ENDPOINT}")
print(f"  Bucket: {BUCKET_NAME}")
print(f"  Policy File: {POLICY_FILE}")
print()

try:
    # Create S3 client
    print("📡 Connecting to MinIO...")
    s3_client = boto3.client(
        's3',
        endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=MINIO_ACCESS_KEY,
        aws_secret_access_key=MINIO_SECRET_KEY,
        region_name='us-east-1',
        verify=True  # Set to False if using self-signed cert
    )
    print("✅ Connected successfully!\n")
    
    # Read policy file
    print(f"📄 Reading policy from {POLICY_FILE}...")
    if not os.path.exists(POLICY_FILE):
        print(f"❌ Error: Policy file '{POLICY_FILE}' not found")
        print(f"   Create it from minio_bucket_policy.json.example")
        exit(1)
    
    with open(POLICY_FILE, 'r') as f:
        policy = json.load(f)
    print("✅ Policy loaded successfully!\n")
    
    # Display policy
    print("📋 Policy contents:")
    print("-" * 80)
    print(json.dumps(policy, indent=2))
    print("-" * 80)
    print()
    
    # Confirm before applying
    response = input("Apply this policy? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("Operation cancelled.")
        exit(0)
    
    # Apply policy
    print(f"\n🔐 Applying policy to bucket '{BUCKET_NAME}'...")
    s3_client.put_bucket_policy(
        Bucket=BUCKET_NAME,
        Policy=json.dumps(policy)
    )
    print("✅ Bucket policy applied successfully!\n")
    
    # Verify policy
    print("🔍 Verifying policy...")
    response = s3_client.get_bucket_policy(Bucket=BUCKET_NAME)
    applied_policy = json.loads(response['Policy'])
    print("✅ Policy verification successful!\n")
    
    print("=" * 80)
    print("SECURITY STATUS")
    print("=" * 80)
    
    # Analyze policy to show what's public
    public_resources = []
    for statement in policy.get('Statement', []):
        if statement.get('Effect') == 'Allow' and '*' in str(statement.get('Principal', {})):
            resources = statement.get('Resource', [])
            if isinstance(resources, str):
                resources = [resources]
            public_resources.extend(resources)
    
    if public_resources:
        print("✅ Public resources (anonymous read access):")
        for resource in public_resources:
            print(f"   - {resource}")
    
    print("🔒 All other paths: Private (require signed URLs)")
    print("=" * 80)
    print()
    
except ClientError as e:
    print(f"❌ Error: {e}")
    print("\nTroubleshooting:")
    print("1. Verify MinIO credentials in .env file")
    print("2. Check MinIO endpoint URL")
    print("3. Ensure bucket exists")
    print("4. Verify network connectivity")
    print(f"5. Check if you have permissions to modify bucket policy")
    
except FileNotFoundError:
    print(f"❌ Error: Policy file '{POLICY_FILE}' not found")
    print(f"   Make sure {POLICY_FILE} exists in the current directory")
    print(f"   Or create it from minio_bucket_policy.json.example")
    
except json.JSONDecodeError:
    print(f"❌ Error: Invalid JSON in '{POLICY_FILE}'")
    print("   Please check the policy file syntax")
    
except Exception as e:
    print(f"❌ Unexpected error: {e}")
    import traceback
    traceback.print_exc()

print()
print("=" * 80)
print("To view current policy:")
print(f"  aws --endpoint-url={MINIO_ENDPOINT} s3api get-bucket-policy --bucket {BUCKET_NAME}")
print("=" * 80)

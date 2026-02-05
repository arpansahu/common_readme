#!/bin/bash
# Script to apply MinIO bucket policy
# This secures private files while keeping public files accessible
# Loads configuration from .env file

set -e

# Load environment variables from .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
else
    echo "❌ Error: .env file not found"
    echo "Please create .env from .env.example"
    exit 1
fi

# Configuration from environment
BUCKET_NAME="${AWS_STORAGE_BUCKET_NAME:-arpansahu-one-bucket}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-https://minioapi.arpansahu.space}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD}"
POLICY_FILE="${POLICY_FILE:-minio_bucket_policy.json}"

echo "=========================================="
echo "Applying MinIO Bucket Policy"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Endpoint: $MINIO_ENDPOINT"
echo "  Bucket: $BUCKET_NAME"
echo "  Policy File: $POLICY_FILE"
echo ""

# Check if policy file exists
if [ ! -f "$POLICY_FILE" ]; then
    echo "❌ Error: Policy file '$POLICY_FILE' not found"
    echo "Please create it from minio_bucket_policy.json.example"
    exit 1
fi

# Method 1: Using mc (MinIO Client)
echo "Method 1: Using MinIO Client (mc)"
echo "----------------------------------"
echo ""
echo "1. Install mc if not already installed:"
echo "   brew install minio/stable/mc  # macOS"
echo "   wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc  # Linux"
echo ""
echo "2. Configure mc alias:"
echo "   mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY <SECRET_KEY>"
echo ""
echo "3. Apply the policy:"
echo "   mc anonymous set-json $POLICY_FILE myminio/$BUCKET_NAME"
echo ""

# Method 2: Using AWS CLI
echo "Method 2: Using AWS CLI"
echo "-----------------------"
echo ""
echo "1. Install AWS CLI if not already installed:"
echo "   brew install awscli  # macOS"
echo "   pip install awscli   # Python"
echo ""
echo "2. Apply the policy:"
echo "   aws --endpoint-url=$MINIO_ENDPOINT \\"
echo "       s3api put-bucket-policy \\"
echo "       --bucket $BUCKET_NAME \\"
echo "       --policy file://$POLICY_FILE"
echo ""

# Method 3: Using Python script
echo "Method 3: Using Python (boto3)"
echo "------------------------------"
echo "Use the apply_policy.py script:"
echo "   python3 apply_policy.py"
echo ""

echo "=========================================="
echo "Would you like to apply the policy now?"
echo "=========================================="
echo ""
read -p "Enter method number (1-3) or 'skip': " method

case $method in
    1)
        echo "Applying policy using mc..."
        if ! command -v mc &> /dev/null; then
            echo "❌ Error: mc not installed"
            echo "Install: brew install minio/stable/mc"
            exit 1
        fi
        mc alias set myminio "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
        mc anonymous set-json "$POLICY_FILE" "myminio/$BUCKET_NAME"
        echo "✅ Policy applied successfully!"
        ;;
    2)
        echo "Applying policy using AWS CLI..."
        if ! command -v aws &> /dev/null; then
            echo "❌ Error: AWS CLI not installed"
            echo "Install: brew install awscli"
            exit 1
        fi
        aws --endpoint-url="$MINIO_ENDPOINT" \
            s3api put-bucket-policy \
            --bucket "$BUCKET_NAME" \
            --policy file://"$POLICY_FILE"
        echo "✅ Policy applied successfully!"
        ;;
    3)
        echo "Applying policy using Python..."
        if [ ! -f "apply_policy.py" ]; then
            echo "❌ Error: apply_policy.py not found"
            exit 1
        fi
        python3 apply_policy.py
        ;;
    *)
        echo "Skipping policy application."
        echo ""
        echo "To apply later, run this script again or use one of the methods above."
        ;;
esac

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "To verify the policy:"
echo "  mc anonymous get myminio/$BUCKET_NAME"
echo ""
echo "Or:"
echo "  aws --endpoint-url=$MINIO_ENDPOINT s3api get-bucket-policy --bucket $BUCKET_NAME"

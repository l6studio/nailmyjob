#!/bin/bash
# =============================================================================
# Pull Secrets from Bitwarden Secrets Manager
# =============================================================================
# This script fetches secrets from Bitwarden and creates a .env file
#
# Prerequisites:
#   - Kamal CLI installed (https://kamal-deploy.org/)
#   - BWS_PROJECT_ID environment variable set
#
# Usage:
#   export BWS_PROJECT_ID="your-project-id"
#   ./scripts/pull-secrets.sh
# =============================================================================

set -e

# Check for Kamal CLI
if ! command -v kamal &> /dev/null; then
    echo "❌ Error: Kamal CLI not found"
    echo "Install it from: https://kamal-deploy.org/"
    exit 1
fi

# Check for access token
if [ -z "$BWS_ACCESS_TOKEN" ]; then
    echo "❌ Error: BWS_ACCESS_TOKEN environment variable not set"
    echo "Get your access token from Bitwarden Secrets Manager"
    exit 1
fi

# Check for project ID
if [ -z "$BWS_PROJECT_ID" ]; then
    echo "❌ Error: BWS_PROJECT_ID environment variable not set"
    echo "Get your project ID from Bitwarden Secrets Manager"
    exit 1
fi

echo "🔐 Fetching secrets from Bitwarden..."

# Fetch all secrets from Bitwarden Secrets Manager project
SECRETS=$(kamal secrets fetch --adapter bitwarden-sm "$BWS_PROJECT_ID/all")

# Create .env file
ENV_FILE="${1:-.env}"
echo "# Auto-generated from Bitwarden Secrets Manager" > "$ENV_FILE"
echo "# Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$ENV_FILE"
echo "" >> "$ENV_FILE"

# Function to extract a secret
extract_secret() {
    local env_name=$1
    local required=${2:-false}
    
    local value=$(kamal secrets extract "$env_name" "$SECRETS" 2>/dev/null)
    
    if [ -n "$value" ] && [ "$value" != "" ]; then
        echo "$env_name=$value" >> "$ENV_FILE"
        echo "✅ $env_name"
    else
        if [ "$required" = true ]; then
            echo "❌ Error: Failed to fetch required secret $env_name"
            exit 1
        else
            echo "⚠️  $env_name (not found, skipping)"
        fi
    fi
}

# =============================================================================
# Extract secrets from Bitwarden (matching .kamal/secrets)
# =============================================================================

# Registry credentials
echo "🔐 Extracting registry credentials..."
extract_secret "REGISTRY_USERNAME"
extract_secret "REGISTRY_PASSWORD"

# Rails
echo "⚙️  Extracting Rails secrets..."
extract_secret "RAILS_MASTER_KEY" true

# Database (use DATABASE_URL for Supabase, or individual vars for local)
echo "🗄️  Extracting database secrets..."
extract_secret "DATABASE_URL" true
extract_secret "DATABASE_USERNAME"
extract_secret "DATABASE_PASSWORD"
extract_secret "DATABASE_HOST"
extract_secret "DATABASE_PORT"
extract_secret "DATABASE_NAME"

# Email (Mailgun API)
echo "📧 Extracting email secrets..."
extract_secret "MAILGUN_API_KEY"
extract_secret "MAILGUN_DOMAIN"
extract_secret "MAILER_FROM_ADDRESS"

# AI Services (optional)
echo "🤖 Extracting AI service secrets..."
extract_secret "DEEPGRAM_API_KEY"
extract_secret "OPENAI_API_KEY"

# =============================================================================
# Static configuration (not secrets)
# =============================================================================
echo "" >> "$ENV_FILE"
echo "# Application Configuration" >> "$ENV_FILE"
echo "RAILS_ENV=production" >> "$ENV_FILE"
echo "RAILS_LOG_TO_STDOUT=true" >> "$ENV_FILE"
echo "RAILS_SERVE_STATIC_FILES=true" >> "$ENV_FILE"

# Add APP_HOST if provided
if [ -n "$APP_HOST" ]; then
    echo "APP_HOST=$APP_HOST" >> "$ENV_FILE"
fi

echo ""
echo "✅ Secrets written to $ENV_FILE"
echo ""
echo "⚠️  Remember to:"
echo "   1. Set APP_HOST in your .env file (if not already set)"
echo "   2. Keep this file secure and never commit it to git!"

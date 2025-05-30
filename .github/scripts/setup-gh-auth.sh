#!/bin/bash

# GitHub CLI Authentication Setup Script
# This script sets up automated GitHub CLI authentication for the Magnify project

set -e

echo "🔐 Setting up GitHub CLI authentication..."

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install gh
    else
        echo "❌ Homebrew not found. Please install GitHub CLI manually: https://cli.github.com/"
        exit 1
    fi
fi

# Method 1: Check if already authenticated
if gh auth status &> /dev/null; then
    echo "✅ GitHub CLI already authenticated"
    gh auth status
    exit 0
fi

# Method 2: Test SSH connection to GitHub
echo "🔑 Testing SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH key authentication to GitHub is working"
    echo "🚀 Setting up GitHub CLI with SSH..."
    
    # Use SSH for GitHub CLI authentication
    echo "📋 Please complete the GitHub CLI setup:"
    echo "   1. Choose 'Upload your SSH public key' when prompted"
    echo "   2. Select your preferred SSH key"
    echo "   3. Follow the web browser authentication"
    echo ""
    
    # Start SSH-based authentication
    gh auth login --git-protocol ssh --web
    
    if gh auth status &> /dev/null; then
        echo "✅ GitHub CLI authenticated successfully with SSH!"
        gh auth status
        exit 0
    fi
fi

# Method 3: Use environment variable GITHUB_TOKEN (fallback)
if [ ! -z "$GITHUB_TOKEN" ]; then
    echo "✅ Found GITHUB_TOKEN environment variable"
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    echo "✅ GitHub CLI authenticated successfully with token"
    gh auth status
    exit 0
fi

# Method 4: Check for token file (fallback)
if [ -f ~/.config/gh/token ]; then
    echo "✅ Found token file at ~/.config/gh/token"
    cat ~/.config/gh/token | gh auth login --with-token
    echo "✅ GitHub CLI authenticated successfully with token file"
    gh auth status
    exit 0
fi

# Method 5: Interactive setup with instructions
echo "📋 GitHub CLI authentication required. Choose an option:"
echo ""
echo "Option A: SSH Key Authentication (Recommended - you have SSH keys!)"
echo "   1. Run: gh auth login --git-protocol ssh --web"
echo "   2. Choose 'Upload your SSH public key'"
echo "   3. Follow the web browser prompts"
echo ""
echo "Option B: Set GITHUB_TOKEN environment variable"
echo "   1. Go to GitHub.com -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)"
echo "   2. Generate new token with 'repo', 'workflow', 'admin:public_key' scopes"
echo "   3. Export the token: export GITHUB_TOKEN=your_token_here"
echo "   4. Run this script again"
echo ""
echo "Option C: Use existing token file"
echo "   1. Save your token to ~/.config/gh/token"
echo "   2. Run this script again"

echo ""
echo "⚠️  No automatic authentication method found."
echo "Since you have SSH keys working with GitHub, we recommend Option A (SSH authentication)."

exit 1 
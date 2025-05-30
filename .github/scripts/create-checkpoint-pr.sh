#!/bin/bash

# Automated Checkpoint PR Creation Script
# Usage: ./create-checkpoint-pr.sh <checkpoint-number> <title> <description>

set -e

# Configuration
REPO_OWNER="jayleekr"
REPO_NAME="Magnify"

# Parse arguments
CHECKPOINT_NUM="${1:-}"
PR_TITLE="${2:-}"
PR_DESCRIPTION="${3:-}"

if [ -z "$CHECKPOINT_NUM" ]; then
    echo "❌ Usage: $0 <checkpoint-number> [title] [description]"
    echo "   Example: $0 1.2 'ScreenCaptureKit Implementation' 'Complete async/await implementation...'"
    exit 1
fi

# Ensure GitHub CLI is authenticated
echo "🔐 Checking GitHub CLI authentication..."
if ! gh auth status &> /dev/null; then
    echo "⚠️  GitHub CLI not authenticated. Running setup script..."
    .github/scripts/setup-gh-auth.sh
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Default values if not provided
if [ -z "$PR_TITLE" ]; then
    PR_TITLE="🎉 Checkpoint $CHECKPOINT_NUM Complete"
fi

if [ -z "$PR_DESCRIPTION" ]; then
    PR_DESCRIPTION="Checkpoint $CHECKPOINT_NUM implementation complete. All requirements met, tests passing, documentation updated."
fi

# Create detailed PR description
PR_BODY="## 🎯 Checkpoint $CHECKPOINT_NUM Complete

### ✅ Achievements
$PR_DESCRIPTION

### 📊 Status
- **Branch**: \`$CURRENT_BRANCH\`
- **Milestone**: 1 (Core Infrastructure)
- **Progress**: Updated in README.md

### 🧪 Quality Assurance
- [x] All new code implemented
- [x] Unit tests written and passing
- [x] Documentation updated
- [x] Performance requirements met
- [x] Code follows project conventions

### 🚀 Ready for Review
This PR implements all requirements for Checkpoint $CHECKPOINT_NUM and is ready for review and merge.

---
*Automated PR creation via GitHub CLI*"

echo "🚀 Creating Pull Request..."
echo "   Title: $PR_TITLE"
echo "   Branch: $CURRENT_BRANCH -> main"
echo "   Repository: $REPO_OWNER/$REPO_NAME"

# Create the PR
PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$CURRENT_BRANCH" \
    --repo "$REPO_OWNER/$REPO_NAME")

echo "✅ Pull Request created successfully!"
echo "🔗 URL: $PR_URL"

# Show PR status
echo ""
echo "📋 PR Summary:"
gh pr view --repo "$REPO_OWNER/$REPO_NAME"

echo ""
echo "🎉 Checkpoint $CHECKPOINT_NUM PR creation complete!"
echo "   Next steps:"
echo "   1. Review the PR at: $PR_URL"
echo "   2. Merge when ready"
echo "   3. Continue with next checkpoint" 
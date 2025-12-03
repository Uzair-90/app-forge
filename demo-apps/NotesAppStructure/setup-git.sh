#!/bin/bash
echo "Setting up Git repository..."
git init
git add .
git commit -m "Initial commit: $APP_NAME iOS app structure"
echo ""
echo "✅ Git repository initialized"
echo "Run: git remote add origin <your-repo-url>"
echo "Then: git push -u origin main"

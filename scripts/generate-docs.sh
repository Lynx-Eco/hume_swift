#!/bin/bash

# Generate documentation for Hume Swift SDK

set -e

echo "Generating documentation for Hume Swift SDK..."

# Build documentation
swift package generate-documentation \
    --target HumeSDK \
    --output-path ./docs \
    --hosting-base-path hume-swift-sdk \
    --source-service github \
    --source-service-base-url https://github.com/HumeAI/hume-swift-sdk

# Generate static site
swift package --disable-sandbox preview-documentation \
    --target HumeSDK

echo "Documentation generation complete!"
echo "Preview available at: http://localhost:8080/documentation/humesdk"
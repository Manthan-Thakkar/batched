#!/bin/bash

# Build script for Go Lambda Extension

set -e

echo "🔨 Building Go Lambda Extension..."

# Determine architecture - AWS Lambda supports linux/amd64 and linux/arm64
ARCH=${1:-"amd64"}

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "❌ Unsupported architecture: $ARCH"
    echo "📝 Supported architectures: amd64, arm64"
    echo "📝 Usage: ./build.sh [amd64|arm64]"
    exit 1
fi

echo "🎯 Building for architecture: linux/$ARCH"

# Initialize Go module if go.sum doesn't exist
if [ ! -f "go.sum" ]; then
    echo "📦 Initializing Go modules..."
    go mod tidy
fi

# Build for Linux with specified architecture
echo "🚀 Building Go binary for linux/$ARCH..."
GOOS=linux GOARCH=$ARCH CGO_ENABLED=0 go build -ldflags="-s -w" -o parameter-store-extension main.go

# Check if build was successful
if [ -f "./parameter-store-extension" ]; then
    echo "✅ Build successful!"
    
    # Make it executable
    chmod +x "./parameter-store-extension"
    echo "🔧 Made binary executable"
    
    # Show file size
    SIZE=$(du -h "./parameter-store-extension" | cut -f1)
    echo "📏 Binary size: $SIZE"
    echo "🏗️  Architecture: linux/$ARCH"
    
    # Create Lambda layer structure
    echo ""
    echo "📦 Creating Lambda layer zip..."
    LAYER_DIR="./lambda-layer"
    EXTENSIONS_DIR="$LAYER_DIR/extensions"
    
    # Clean and create layer directory structure
    rm -rf "$LAYER_DIR"
    mkdir -p "$EXTENSIONS_DIR"
    
    # Copy extension binary to layer structure
    cp "./parameter-store-extension" "$EXTENSIONS_DIR/"
    
    # Create zip file with architecture suffix
    ZIP_NAME="parameter-store-extension-layer-linux-${ARCH}.zip"
    rm -f "$ZIP_NAME"
    
    # Create zip from layer directory (preserving directory structure)
    cd "$LAYER_DIR"
    zip -r "../$ZIP_NAME" . > /dev/null
    cd ..
    
    # Clean up temporary layer directory
    rm -rf "$LAYER_DIR"
    
    # Show zip file info
    ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
    echo "✅ Lambda layer created: $ZIP_NAME"
    echo "📏 Layer zip size: $ZIP_SIZE"
    echo "📁 Layer structure: extensions/parameter-store-extension"
    
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🎯 Next steps:"
echo "1. Upload '$ZIP_NAME' as a Lambda layer in AWS Console or CLI"
echo "2. Add the layer to your Lambda function (any runtime)"
echo "3. Set environment variables: PARAMETER_NAME, CONFIG_FILE (optional)"
echo "4. Ensure Lambda execution role has 'ssm:GetParameter' permission"
echo "5. Deploy your Lambda function"
echo ""
echo "💡 AWS CLI command to create layer:"
echo "   aws lambda publish-layer-version \\"
echo "     --layer-name parameter-store-extension \\"
echo "     --description 'Parameter Store Extension for Lambda (Go)' \\"
echo "     --zip-file fileb://$ZIP_NAME \\"
echo "     --compatible-runtimes python3.9 python3.10 python3.11 python3.12 nodejs18.x nodejs20.x java11 java17 java21 dotnet6 dotnet8 ruby3.2 provided.al2 provided.al2023 \\"
echo "     --compatible-architectures ${ARCH/amd64/x86_64}"
echo ""
echo "💡 To build for different architecture:"
echo "   ./build.sh amd64    # For Intel/AMD 64-bit (default)"
echo "   ./build.sh arm64    # For ARM 64-bit (AWS Graviton)"

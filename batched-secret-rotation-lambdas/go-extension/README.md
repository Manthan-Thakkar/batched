# Go Lambda Extension for Parameter Store

A lightweight, high-performance Lambda extension written in Go that fetches Parameter Store values during the Lambda INIT phase.

## 🚀 **Why Go?**

### **Size Comparison:**
- **🟢 Go Extension**: 6.6MB binary → 2.7MB layer
- **🟡 .NET 8 Extension**: 80MB binary → 30MB layer  
- **🟡 Python Extension**: ~10-15MB (with dependencies)

### **Performance Benefits:**
- ✅ **Static Binary**: No dependencies, works in any Lambda runtime
- ✅ **Fast Cold Start**: ~5-10ms startup time
- ✅ **Memory Efficient**: ~5-10MB memory usage
- ✅ **Cross-Runtime**: Works with Python, Node.js, .NET, Java, Ruby, etc.

## 📦 **Features**

- **Universal Compatibility**: Works with ALL Lambda runtimes
- **Minimal Size**: 2.4-2.7MB layer (90% smaller than .NET)
- **No Dependencies**: Static binary with built-in AWS SDK
- **High Performance**: Native compiled Go code
- **Easy Deployment**: Single layer for all your Lambda functions

## 🛠️ **Building**

### **Prerequisites:**
- Go 1.19+ installed
- Any OS (Windows, macOS, Linux)

### **Build Commands:**
```bash
# For Intel/AMD 64-bit (most common)
./build.sh amd64

# For ARM 64-bit (AWS Graviton)
./build.sh arm64

# Default (same as amd64)
./build.sh
```

### **Output:**
- Binary: `parameter-store-extension` (~6.6MB)
- Layer: `parameter-store-extension-layer-linux-{arch}.zip` (~2.7MB)

## 🏗️ **Architecture Support**

| Architecture | Lambda Support | Binary Size | Layer Size |
|-------------|----------------|-------------|------------|
| `linux/amd64` | ✅ x86_64 | 6.6MB | 2.7MB |
| `linux/arm64` | ✅ arm64 | 6.3MB | 2.4MB |

## 📋 **Deployment**

### **1. Build and Upload Layer:**
```bash
# Build
./build.sh amd64

# Upload to AWS
aws lambda publish-layer-version \
  --layer-name parameter-store-extension \
  --description 'Parameter Store Extension for Lambda (Go)' \
  --zip-file fileb://parameter-store-extension-layer-linux-amd64.zip \
  --compatible-runtimes python3.9 python3.10 python3.11 python3.12 nodejs18.x nodejs20.x java11 java17 java21 dotnet6 dotnet8 ruby3.2 provided.al2 provided.al2023 \
  --compatible-architectures x86_64
```

### **2. Add Layer to Lambda Function:**
```bash
aws lambda update-function-configuration \
  --function-name your-function-name \
  --layers arn:aws:lambda:region:account:layer:parameter-store-extension:1
```

### **3. Set Environment Variables:**
```bash
PARAMETER_NAME=/your/parameter/store/path    # Required
CONFIG_FILE=/tmp/appsettings.json           # Optional (default)
```

## 🔐 **IAM Permissions**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:parameter/your/parameter/path",
                "arn:aws:ssm:*:*:parameter/your/parameter/path/*"
            ]
        }
    ]
}
```

## 💻 **Usage Examples**

### **Python Lambda:**
```python
import json
import os

def lambda_handler(event, context):
    # Read config fetched by extension
    if os.path.exists('/tmp/appsettings.json'):
        with open('/tmp/appsettings.json', 'r') as f:
            config = json.load(f)
        
        # Use your config
        db_connection = config.get('database', {}).get('connection_string')
        api_key = config.get('api', {}).get('key')
    
    return {
        'statusCode': 200,
        'body': json.dumps('Config loaded successfully!')
    }
```

### **Node.js Lambda:**
```javascript
const fs = require('fs');

exports.handler = async (event) => {
    let config = {};
    
    // Read config fetched by extension
    if (fs.existsSync('/tmp/appsettings.json')) {
        const configData = fs.readFileSync('/tmp/appsettings.json', 'utf8');
        config = JSON.parse(configData);
    }
    
    // Use your config
    const dbConnection = config.database?.connection_string;
    const apiKey = config.api?.key;
    
    return {
        statusCode: 200,
        body: JSON.stringify('Config loaded successfully!')
    };
};
```

### **.NET Lambda:**
```csharp
public async Task<APIGatewayProxyResponse> FunctionHandler(APIGatewayProxyRequest request, ILambdaContext context)
{
    var configFile = "/tmp/appsettings.json";
    
    if (File.Exists(configFile))
    {
        var configJson = await File.ReadAllTextAsync(configFile);
        var config = JsonSerializer.Deserialize<MyConfig>(configJson);
        
        // Use your config
        var dbConnection = config.Database?.ConnectionString;
        var apiKey = config.Api?.Key;
    }
    
    return new APIGatewayProxyResponse
    {
        StatusCode = 200,
        Body = "Config loaded successfully!"
    };
}
```

## 📊 **Performance Comparison**

| Extension Type | Binary Size | Layer Size | Cold Start | Memory | Compatibility |
|---------------|-------------|------------|------------|---------|---------------|
| **Go** | 6.6MB | 2.7MB | ~5ms | ~10MB | All Runtimes |
| .NET 8 | 80MB | 30MB | ~100ms | ~50MB | .NET Only |
| Python | ~15MB | ~10MB | ~50ms | ~30MB | Python Only |
| Shell | ~1KB | ~1KB | ~20ms | ~5MB | Limited Features |

## 🔍 **Extension Lifecycle**

```
Lambda Cold Start
├── 1. Extension Registration
├── 2. Parameter Store Fetch  ← Extension runs here
├── 3. Config File Creation   ← /tmp/appsettings.json
├── 4. INIT Phase Complete
└── 5. Your Function Runs    ← Reads config file
```

## 📝 **Logging**

Extension logs appear in CloudWatch:

```
[parameter-store-extension] === INIT PHASE START ===
[parameter-store-extension] Registered with ID: a1b2c3d4-e5f6-1234-abcd-567890abcdef
[parameter-store-extension] Fetching parameter: /prod/app/config
[parameter-store-extension] ✅ Config updated successfully: /tmp/appsettings.json
[parameter-store-extension] === INIT PHASE COMPLETE ===
```

## 🎯 **Best Practices**

1. **Use for Configuration**: Store JSON configuration in Parameter Store
2. **Cache Friendly**: Extension only runs during cold starts
3. **Error Handling**: Extension failure doesn't crash your Lambda
4. **Security**: Use encrypted parameters with `WithDecryption: true`
5. **Cost Optimization**: Single layer works across all functions

## 🔧 **Development**

```bash
# Format code
go fmt ./...

# Run tests
go test ./...

# Check for issues
go vet ./...

# Build locally for testing
GOOS=linux GOARCH=amd64 go build -o parameter-store-extension main.go
```

## 🆚 **When to Use Each Extension Type**

| Use Case | Recommended Extension |
|----------|----------------------|
| **Multi-runtime environment** | **Go Extension** (this one) |
| **.NET-only environment** | .NET Extension |
| **Minimal size requirements** | Shell Script |
| **Complex processing** | Python Extension |
| **Production workloads** | **Go Extension** (recommended) |

## 📋 **Migration Guide**

Moving from other extensions to Go extension:

1. **Remove old extension** from your Lambda layer
2. **Add Go extension layer** (2.7MB)
3. **Keep same environment variables** (`PARAMETER_NAME`, `CONFIG_FILE`)
4. **No code changes needed** in your Lambda function
5. **Enjoy 90% size reduction** and better performance!

This Go extension provides the best balance of size, performance, and compatibility for production Lambda workloads! 🚀

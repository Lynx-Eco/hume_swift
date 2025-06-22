# Hume Swift SDK

Official Swift SDK for Hume AI APIs, providing easy access to:
- 🎙️ **Text-to-Speech (TTS)** - Convert text to expressive speech
- 🎭 **Empathic Voice Interface (EVI)** - Real-time conversational AI
- 📊 **Expression Measurement** - Analyze emotional expressions

## Requirements

- Swift 5.9+
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/HumeAI/hume-swift-sdk", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/HumeAI/hume-swift-sdk`
3. Select version 1.0.0 or later

## Quick Start

### Initialize the Client

```swift
import HumeSDK

// Using API key
let client = try HumeClient(apiKey: "your-api-key")

// Using OAuth2
let client = try HumeClient(apiKey: "your-api-key", secretKey: "your-secret-key")

// Using environment variables
// Set HUME_API_KEY and optionally HUME_SECRET_KEY
let client = try HumeClient.fromEnvironment()
```

### Text-to-Speech (TTS)

```swift
let tts = TTSClient(client: client)

// Simple synthesis
let response = try await tts.synthesize(text: "Hello, world!")
print("Audio URL: \(response.audioUrl ?? "N/A")")

// Synthesis with options
let audioData = try await tts.synthesizeAudio(
    text: "Welcome to Hume AI",
    voice: .name("ITO"),
    format: .mp3
)

// Save to file
try audioData.write(to: audioFileURL)

// Using builder pattern
let request = tts.request(text: "Advanced synthesis")
    .voiceName("KORA")
    .sampleRate(.hz44100)
    .speed(1.2)
    .volume(0.8)
    .build()

let result = try await tts.synthesize(request)
```

### List Available Voices

```swift
// Get all voices
let voices = try await tts.listVoices()
for voice in voices.voices {
    print("\(voice.name) - \(voice.provider?.rawValue ?? "Unknown")")
}

// Paginated iteration
for try await voice in tts.voices(pageSize: 50) {
    print("Voice: \(voice.name)")
}
```

## API Reference

### HumeClient

The main client for all Hume APIs.

#### Initialization Options

```swift
// Builder pattern for advanced configuration
let client = try HumeClient.Builder()
    .apiKey("your-api-key")
    .timeout(30.0)
    .retryPolicy(RetryPolicy(maxRetries: 5))
    .baseURL("https://custom.api.hume.ai")
    .build()
```

#### Authentication

The SDK supports multiple authentication methods:

1. **API Key**: Direct API key authentication
2. **OAuth2**: Automatic token management with API key + secret key
3. **Access Token**: Direct access token usage

### Error Handling

The SDK provides comprehensive error handling:

```swift
do {
    let response = try await tts.synthesize(text: "Hello")
} catch let error as HumeError {
    switch error {
    case .api(let status, let message, _, _):
        print("API Error (\(status)): \(message)")
        
    case .rateLimit(let retryAfter):
        if let retryAfter = retryAfter {
            print("Rate limited. Retry after \(retryAfter)s")
        }
        
    case .timeout:
        print("Request timed out")
        
    case .authenticationFailed:
        print("Authentication failed")
        
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

### Retry Configuration

The SDK includes automatic retry logic with exponential backoff:

```swift
let retryPolicy = RetryPolicy(
    maxRetries: 5,
    initialDelay: 0.5,
    maxDelay: 10.0,
    backoffMultiplier: 2.0,
    jitterFactor: 0.1,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
)

let client = try HumeClient.Builder()
    .apiKey("your-api-key")
    .retryPolicy(retryPolicy)
    .build()
```

### Request Options

Customize individual requests:

```swift
let options = RequestOptions(
    headers: ["X-Custom-Header": "value"],
    queryParameters: ["param": "value"],
    timeout: 10.0,
    maxRetries: 1
)

let response = try await tts.synthesize(
    text: "Custom request",
    options: options
)
```

## Sample Rates

The SDK provides convenient sample rate constants:

```swift
SampleRate.hz8000   // 8 kHz
SampleRate.hz16000  // 16 kHz
SampleRate.hz22050  // 22.05 kHz
SampleRate.hz24000  // 24 kHz
SampleRate.hz44100  // 44.1 kHz (CD quality)
SampleRate.hz48000  // 48 kHz (Professional)
```

## Audio Formats

Supported audio formats:

```swift
AudioFormatDetails.mp3
AudioFormatDetails.wav(sampleRate: 44100)
AudioFormatDetails.pcm(encoding: .int16, sampleRate: 48000)
```

## Advanced Features

### Async/Await Support

All API calls use Swift's modern async/await pattern:

```swift
// Sequential calls
let voice1 = try await tts.synthesize(text: "First")
let voice2 = try await tts.synthesize(text: "Second")

// Concurrent calls
async let audio1 = tts.synthesizeAudio(text: "First")
async let audio2 = tts.synthesizeAudio(text: "Second")
let results = try await [audio1, audio2]
```

### Pagination

The SDK provides async sequences for paginated endpoints:

```swift
// Automatic pagination handling
for try await voice in tts.voices(pageSize: 100) {
    // Process each voice
}
```

## Environment Variables

Configure the SDK using environment variables:

- `HUME_API_KEY` - Your Hume API key
- `HUME_SECRET_KEY` - Your secret key for OAuth2 (optional)
- `HUME_BASE_URL` - Custom API base URL (optional)

## Current Status

This SDK is currently in development. The following features are implemented:

✅ **Core Infrastructure**
- Authentication (API Key, OAuth2, Access Token)
- HTTP client with retry logic
- WebSocket client for streaming
- Comprehensive error handling
- Request customization
- Builder patterns

✅ **Text-to-Speech (TTS)**
- Basic synthesis (JSON and audio)
- Voice management
- Builder pattern for requests
- Sample rate enums
- Audio format support

✅ **Empathic Voice Interface (EVI)**
- Configuration management (CRUD operations)
- Tool management (CRUD operations)
- WebSocket chat sessions
- Real-time messaging
- Audio streaming support

✅ **Expression Measurement**
- Batch job API
- Job status tracking
- Predictions retrieval
- WebSocket streaming sessions
- Real-time analysis

🚧 **Future Enhancements**
- Streaming support for TTS
- Additional examples
- Comprehensive test suite
- Performance optimizations

## Best Practices

1. **Reuse Clients**: Create one `HumeClient` instance and reuse it
2. **Handle Errors**: Always handle `HumeError` cases appropriately
3. **Respect Rate Limits**: Check for rate limit errors and retry after the specified delay
4. **Use Builders**: Leverage builder patterns for complex configurations
5. **Environment Variables**: Use environment variables for credentials in production

## Examples

See the [Examples](Examples/) directory for complete usage examples:
- [BasicUsage.swift](Examples/BasicUsage.swift) - Common use cases
- [MinimalTest.swift](Examples/MinimalTest.swift) - Minimal working example

## Contributing

This SDK is under active development. Contributions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- 📖 [Documentation](https://dev.hume.ai/docs)
- 🐛 [Issues](https://github.com/HumeAI/hume-swift-sdk/issues)
- 💬 [Discord](https://discord.gg/hume)

## License

This SDK is licensed under the MIT License. See [LICENSE](LICENSE) for details.
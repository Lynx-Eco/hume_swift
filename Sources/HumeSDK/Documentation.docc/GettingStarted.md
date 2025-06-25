# Getting Started

Learn how to integrate the Hume Swift SDK into your project and make your first API call.

## Installation

### Swift Package Manager

Add the Hume SDK to your project using Swift Package Manager:

1. In Xcode, select **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/HumeAI/hume-swift-sdk`
3. Select version 0.9.0 or later

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/HumeAI/hume-swift-sdk", from: "0.9.0")
]
```

## Basic Setup

### Import the SDK

```swift
import HumeSDK
```

### Create a Client

```swift
// Using an API key
let client = try HumeClient(apiKey: "your-api-key-here")

// Using environment variable (HUME_API_KEY)
let client = try HumeClient()
```

## Your First Request

### Text-to-Speech Example

```swift
import HumeSDK

@main
struct MyApp {
    static func main() async throws {
        // Create client
        let client = try HumeClient()
        
        // Create TTS client
        let tts = client.tts
        
        // Generate speech
        let request = TTSRequest(
            utterances: [
                Utterance(text: "Hello, welcome to Hume AI!")
            ]
        )
        
        let response = try await tts.synthesize(request)
        
        // Save audio data
        let audioData = response.generations[0].data
        try audioData.write(to: URL(fileURLWithPath: "welcome.mp3"))
        
        print("Audio saved to welcome.mp3")
    }
}
```

### Expression Measurement Example

```swift
// Analyze text for emotions
let expression = client.expression

let request = BatchRequest(
    models: ["language"],
    text: [TextInput(text: "I'm so excited about this new SDK!")]
)

let jobId = try await expression.batch.createJob(request)
print("Job created: \(jobId)")

// Wait for completion
let result = try await expression.batch.waitForCompletion(
    jobId: jobId,
    pollInterval: 2.0
)

print("Analysis complete!")
```

### Empathic Voice Interface Example

```swift
// Start a chat session
let evi = client.evi

let chat = try await evi.chat()
    .configId("your-config-id")
    .connect()

// Send a message
try await chat.sendText("Hello, how are you today?")

// Listen for responses
Task {
    for try await message in chat.messages {
        switch message {
        case .assistantMessage(let text, _):
            print("Assistant: \(text)")
        case .audioOutput(let data):
            // Handle audio response
            break
        default:
            break
        }
    }
}
```

## Next Steps

- Explore the <doc:Authentication> guide for different authentication methods
- Learn about <doc:ErrorHandling> to handle errors gracefully
- Check out the API reference for detailed documentation
- See the Examples directory for more comprehensive examples
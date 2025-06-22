import Foundation
import HumeSDK

// MARK: - Basic Usage Examples

/// Example 1: Simple TTS Synthesis
func simpleTTSExample() async throws {
    // Initialize client with API key
    let client = try HumeClient(apiKey: "your-api-key")
    
    // Create TTS client
    let tts = TTSClient(client: client)
    
    // Synthesize speech with default voice
    let response = try await tts.synthesize(text: "Hello, world!")
    print("Audio URL: \(response.audioUrl ?? "N/A")")
    print("Duration: \(response.duration ?? 0) seconds")
    
    // Synthesize with specific voice
    let audioData = try await tts.synthesizeAudio(
        text: "Welcome to Hume AI",
        voice: .name("ITO"),
        format: .mp3
    )
    print("Received \(audioData.count) bytes of audio data")
}

/// Example 2: Using Builder Pattern
func builderExample() async throws {
    // Build client with custom configuration
    let client = try HumeClient.Builder()
        .apiKey("your-api-key")
        .timeout(30.0)
        .retryPolicy(RetryPolicy(maxRetries: 5))
        .build()
    
    let tts = TTSClient(client: client)
    
    // Build TTS request
    let request = tts.request(text: "This is a test message")
        .voiceName("KORA")
        .sampleRate(.hz44100)
        .speed(1.2)
        .volume(0.8)
        .build()
    
    let response = try await tts.synthesize(request)
    print("Synthesis completed")
}

/// Example 3: List Available Voices
func listVoicesExample() async throws {
    let client = try HumeClient(apiKey: "your-api-key")
    let tts = TTSClient(client: client)
    
    // List all voices
    let voicesResponse = try await tts.listVoices()
    print("Available voices:")
    for voice in voicesResponse.voices {
        print("- \(voice.name) (ID: \(voice.id))")
        if let provider = voice.provider {
            print("  Provider: \(provider.rawValue)")
        }
        if let description = voice.description {
            print("  Description: \(description)")
        }
    }
    
    // Iterate through paginated voices
    print("\nIterating through all voices:")
    for try await voice in tts.voices(pageSize: 50) {
        print("- \(voice.name)")
    }
}

/// Example 4: Error Handling
func errorHandlingExample() async {
    do {
        let client = try HumeClient(apiKey: "invalid-key")
        let tts = TTSClient(client: client)
        
        _ = try await tts.synthesize(text: "Test")
    } catch let error as HumeError {
        switch error {
        case .api(let status, let message, _, _):
            print("API Error (\(status)): \(message)")
            
        case .missingAPIKey:
            print("Please provide an API key")
            
        case .rateLimit(let retryAfter):
            if let retryAfter = retryAfter {
                print("Rate limited. Retry after \(retryAfter) seconds")
            }
            
        case .timeout:
            print("Request timed out")
            
        default:
            print("Error: \(error.localizedDescription)")
        }
        
        // Check if error is retryable
        if error.isRetryable {
            print("This error is retryable")
        }
        
        // Check if authentication error
        if error.isAuthenticationError {
            print("Authentication failed - check your credentials")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}

/// Example 5: OAuth2 Authentication
func oauth2Example() async throws {
    // Initialize with OAuth2 credentials
    let client = try HumeClient(
        apiKey: "your-api-key",
        secretKey: "your-secret-key"
    )
    
    let tts = TTSClient(client: client)
    
    // The SDK will automatically fetch and manage access tokens
    let response = try await tts.synthesize(text: "OAuth2 authenticated request")
    print("Success with OAuth2!")
}

/// Example 6: Environment Variables
func environmentExample() async throws {
    // Set environment variables:
    // HUME_API_KEY=your-api-key
    // HUME_SECRET_KEY=your-secret-key (optional)
    // HUME_BASE_URL=https://custom.api.hume.ai (optional)
    
    let client = try HumeClient.fromEnvironment()
    let tts = TTSClient(client: client)
    
    let response = try await tts.synthesize(text: "Environment-based configuration")
    print("Success with environment configuration!")
}

/// Example 7: Custom Request Options
func customOptionsExample() async throws {
    let client = try HumeClient(apiKey: "your-api-key")
    let tts = TTSClient(client: client)
    
    // Custom headers and timeout
    let options = RequestOptions(
        headers: ["X-Custom-Header": "custom-value"],
        timeout: 10.0,
        maxRetries: 1
    )
    
    let response = try await tts.synthesize(
        text: "Custom request options",
        options: options
    )
    print("Success with custom options!")
}

/// Example 8: Saving Audio to File
func saveAudioExample() async throws {
    let client = try HumeClient(apiKey: "your-api-key")
    let tts = TTSClient(client: client)
    
    // Get audio data
    let audioData = try await tts.synthesizeAudio(
        text: "This audio will be saved to a file",
        format: .mp3
    )
    
    // Save to file
    let documentsPath = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    let audioURL = documentsPath.appendingPathComponent("output.mp3")
    try audioData.write(to: audioURL)
    
    print("Audio saved to: \(audioURL.path)")
}

// MARK: - Main Example Runner

@main
struct ExampleRunner {
    static func main() async {
        print("Hume Swift SDK Examples")
        print("=======================\n")
        
        do {
            // Run examples (comment out those requiring real API key)
            
            print("Example 1: Simple TTS")
            // try await simpleTTSExample()
            
            print("\nExample 4: Error Handling")
            await errorHandlingExample()
            
            print("\nDone!")
            
        } catch {
            print("Error running examples: \(error)")
        }
    }
}
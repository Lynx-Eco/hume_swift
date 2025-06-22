import Foundation
import HumeSDK

@main
struct MinimalTest {
    static func main() async {
        do {
            print("Testing Hume Swift SDK")
            print("======================")
            
            // Test client creation
            let client = try HumeClient(apiKey: "test-api-key")
            print("✓ Created HumeClient")
            
            // Test TTS client
            let tts = TTSClient(client: client)
            print("✓ Created TTSClient")
            
            // Test request builder
            let request = tts.request(text: "Hello, world!")
                .voiceName("ITO")
                .sampleRate(.hz44100)
                .build()
            print("✓ Built TTS request")
            
            print("\nCore components working!")
            
        } catch {
            print("Error: \(error)")
        }
    }
}
import Foundation
import HumeSDK
import ExampleUtils

@main
struct EVIConnectionTest {
    static func main() async {
        // Load environment variables
        EnvLoader.loadEnv()
        
        print("🔗 EVI WebSocket Connection Test")
        print("=" * 50)
        
        do {
            // Create client
            let client = try HumeClient.fromEnvironment()
            let evi = client.evi
            
            // Step 1: List available configurations
            print("\n📋 Available Configurations:")
            do {
                let configs = try await evi.listConfigs(pageSize: 5)
                if configs.configsPage.isEmpty {
                    print("  No custom configurations found")
                } else {
                    for config in configs.configsPage.prefix(3) {
                        print("  - \(config.name) (ID: \(config.id))")
                    }
                }
            } catch {
                print("  ❌ Error listing configs: \(error)")
            }
            
            // Step 2: Create a test configuration (fixed for API requirements)
            print("\n🔧 Creating Test Configuration:")
            let testConfigName = "swift-sdk-test-\(Int(Date().timeIntervalSince1970))"
            
            var testConfig: EVIConfig?
            do {
                // Note: The API might require prompt to be an object, not a string
                // For now, we'll skip creation if it fails
                let request = CreateConfigRequest(
                    name: testConfigName,
                    prompt: "You are a helpful AI assistant testing the Swift SDK WebSocket connection. Be concise and friendly.",
                    language: .en
                )
                
                testConfig = try await evi.createConfig(request)
                print("  ✅ Created config: \(testConfig!.name) (ID: \(testConfig!.id))")
            } catch {
                print("  ⚠️  Skipping config creation due to API requirements: \(error)")
                // Try to use a built-in config instead
                do {
                    let builtInConfigs = try await evi.listBuiltInConfigs()
                    if let firstConfig = builtInConfigs.configsPage.first {
                        testConfig = firstConfig
                        print("  📋 Using built-in config: \(firstConfig.name)")
                    }
                } catch {
                    print("  ❌ Could not get built-in configs either")
                }
            }
            
            // Step 3: Test WebSocket connection
            print("\n🌐 Testing WebSocket Connection:")
            
            let session = try await evi.createChatSession(
                configId: testConfig?.id
            )
            
            // Set up message handlers
            var receivedMessages = 0
            var sessionStarted = false
            
            session.onMessage { message in
                receivedMessages += 1
                
                switch message {
                case .userMessage(let msg):
                    print("  👤 User echo: \(msg.text)")
                    
                case .assistantMessage(let msg):
                    print("  🤖 Assistant: \(msg.text)")
                    if msg.isFinal {
                        print("     (Message complete)")
                    }
                    
                case .audioOutput(let audio):
                    print("  🔊 Audio output (message: \(audio.messageId ?? "unknown"))")
                    if audio.isFinal {
                        print("     (Audio complete)")
                    }
                    
                case .userInterruption:
                    print("  🛑 User interruption detected")
                    
                case .error(let err):
                    print("  ❌ Error: \(err.message) (code: \(err.code ?? "unknown"))")
                }
            }
            
            session.onError { error in
                print("  ❌ WebSocket error: \(error)")
            }
            
            session.onDisconnect { reason in
                print("  🔌 Disconnected: \(reason ?? "unknown reason")")
            }
            
            // Connect to the session
            do {
                try await session.connect()
                print("  ✅ WebSocket connected successfully!")
                sessionStarted = true
            } catch {
                print("  ❌ Failed to connect: \(error)")
                
                // Clean up config if created
                if let config = testConfig, config.name.hasPrefix("swift-sdk-test-") {
                    try? await evi.deleteConfig(id: config.id)
                }
                return
            }
            
            // Step 4: Test message exchange
            print("\n💬 Testing Message Exchange:")
            
            // Send initial message
            print("  📤 Sending: 'Hello, can you hear me?'")
            do {
                try await session.sendText("Hello, can you hear me?")
            } catch {
                print("  ❌ Failed to send message: \(error)")
            }
            
            // Wait for responses
            print("  ⏳ Waiting for responses (5s)...")
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            // Send another message
            if receivedMessages > 0 {
                print("\n  📤 Sending: 'What's 2+2?'")
                try? await session.sendText("What's 2+2?")
                
                // Wait for response
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            
            // Step 5: Test session settings update
            print("\n⚙️  Testing Session Settings:")
            let settings = SessionSettings(
                systemPrompt: "Be extra cheerful in your responses!",
                temperature: 0.8,
                maxTokens: 150,
                audioEncoding: .pcmLinear16,
                sampleRate: 16000,
                channelCount: 1,
                language: .en
            )
            
            do {
                try await session.updateSettings(settings)
                print("  ✅ Session settings updated")
            } catch {
                print("  ❌ Failed to update settings: \(error)")
            }
            
            // Step 6: Test audio streaming
            print("\n🎤 Testing Audio Streaming:")
            
            // Create a small audio sample (100ms of silence at 16kHz)
            let audioData = Data(repeating: 0, count: 1600)
            print("  📤 Sending audio data (100ms silence)")
            
            do {
                try await session.sendAudio(audioData)
                print("  ✅ Audio sent successfully")
            } catch {
                print("  ❌ Failed to send audio: \(error)")
            }
            
            // Wait for any audio-related responses
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Step 7: Test graceful disconnect
            print("\n🔌 Testing Graceful Disconnect:")
            await session.disconnect(reason: "Test complete")
            print("  ✅ Disconnect command sent")
            
            // Wait a moment for disconnect to process
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Step 8: Clean up test configuration
            if let config = testConfig, config.name.hasPrefix("swift-sdk-test-") {
                print("\n🧹 Cleaning Up:")
                do {
                    try await evi.deleteConfig(id: config.id)
                    print("  ✅ Test configuration deleted")
                } catch {
                    print("  ❌ Error deleting config: \(error)")
                }
            }
            
            print("\n✨ Connection test complete!")
            print("\n📊 Summary:")
            print("  - WebSocket connection: \(sessionStarted ? "✅" : "❌")")
            print("  - Message exchange: \(receivedMessages > 0 ? "✅" : "❌")")
            print("  - Received \(receivedMessages) messages")
            
        } catch {
            print("❌ Fatal error: \(error)")
        }
    }
}

// Helper extension
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
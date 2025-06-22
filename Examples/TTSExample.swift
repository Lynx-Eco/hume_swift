import Foundation
import HumeSDK
import ExampleUtils

@main
struct TTSExample {
    static func main() async {
        // Load environment variables
        EnvLoader.loadEnv()
        
        do {
            print("🎙️  Hume TTS Example")
            print("=" * 50)
            
            // Initialize client
            let client = try HumeClient.fromEnvironment()
            print("Client initialized with base URL: \(client.baseURL)")
            let tts = client.tts
            
            // Example 1: List voices
            print("\n1. Available Voices:")
            print("-" * 30)
            
            do {
                let voicesResponse = try await tts.listVoices(provider: .humeAI, pageSize: 10)
                print("Found \(voicesResponse.voices.count) voices")
                
                for (index, voice) in voicesResponse.voices.enumerated() {
                    print("\n  Voice \(index + 1):")
                    print("  - Name: \(voice.name)")
                    print("  - Provider: \(voice.provider?.rawValue ?? "Unknown")")
                    // Additional voice properties can be added here
                }
            } catch {
                print("  ❌ Error listing voices: \(error)")
            }
            
            // Example 2: Simple synthesis
            print("\n\n2. Simple Synthesis:")
            print("-" * 30)
            
            do {
                let response = try await tts.synthesize(text: "Hello! This is a test of the Hume Swift SDK text-to-speech functionality.")
                
                if let audioUrl = response.audioUrl {
                    print("  ✅ Audio URL: \(audioUrl)")
                }
                
                if let duration = response.duration {
                    print("  ⏱️  Duration: \(String(format: "%.2f", duration)) seconds")
                }
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            // Example 3: Synthesis with voice selection
            print("\n\n3. Synthesis with Voice Selection:")
            print("-" * 30)
            
            do {
                let audioData = try await tts.synthesizeAudio(
                    text: "This message is synthesized with a specific voice and custom settings.",
                    voice: .name("Colton Rivers"),
                    format: .mp3
                )
                
                print("  ✅ Audio data size: \(audioData.count) bytes")
                print("  📝 Format: MP3")
                print("  🎤 Voice: ITO")
                
                // Save to file
                let url = URL(fileURLWithPath: "tts_output_ito.mp3")
                try audioData.write(to: url)
                print("  💾 Saved to: \(url.path)")
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            // Example 4: Advanced synthesis with builder
            print("\n\n4. Advanced Synthesis with Builder:")
            print("-" * 30)
            
            do {
                let request = tts.request(text: "This is an advanced example with custom sample rate, speed, and volume settings.")
                    .voiceName("Geraldine Wallace")
                    .sampleRate(.hz44100)
                    .speed(1.2)
                    .volume(0.8)
                    .build()
                
                let audioData = try await tts.synthesizeAudio(request)
                
                print("  ✅ Audio data size: \(audioData.count) bytes")
                print("  📝 Format: WAV")
                print("  🎤 Voice: KORA")
                print("  🎵 Sample rate: 44.1 kHz")
                print("  ⚡ Speed: 1.2x")
                print("  🔊 Volume: 80%")
                
                // Save to file
                let url = URL(fileURLWithPath: "tts_output_advanced.wav")
                try audioData.write(to: url)
                print("  💾 Saved to: \(url.path)")
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            // Example 5: Multiple voices comparison
            print("\n\n5. Multiple Voices Comparison:")
            print("-" * 30)
            
            let testVoices = ["Colton Rivers", "Dungeon Master", "Female Meditation Guide", "Friendly Troll"]
            let testText = "Hello, this is a test of different voices."
            
            for voiceName in testVoices {
                print("\n  Testing voice: \(voiceName)")
                do {
                    let audioData = try await tts.synthesizeAudio(
                        text: testText,
                        voice: .name(voiceName),
                        format: .mp3
                    )
                    
                    let url = URL(fileURLWithPath: "tts_output_\(voiceName.lowercased()).mp3")
                    try audioData.write(to: url)
                    print("  ✅ Saved to: \(url.path) (\(audioData.count) bytes)")
                } catch {
                    print("  ❌ Error with \(voiceName): \(error)")
                }
            }
            
            // Example 6: Iterate through all voices using AsyncSequence
            print("\n\n6. Voice Iteration with AsyncSequence:")
            print("-" * 30)
            
            do {
                var voiceCount = 0
                for try await voice in tts.voices(pageSize: 20) {
                    voiceCount += 1
                    if voiceCount <= 5 {
                        print("  Voice: \(voice.name) - \(voice.provider?.rawValue ?? "Unknown")")
                    }
                }
                print("  ... and \(voiceCount - 5) more voices")
                print("  ✅ Total voices iterated: \(voiceCount)")
            } catch {
                print("  ❌ Error iterating voices: \(error)")
            }
            
            print("\n✨ TTS Example Complete!")
            
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
    
    static func -(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
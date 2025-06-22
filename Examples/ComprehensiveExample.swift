import Foundation
import HumeSDK

@main
struct ComprehensiveExample {
    static func main() async {
        do {
            // Initialize client from environment
            let client = try HumeClient.fromEnvironment()
            
            print("=== Hume Swift SDK Comprehensive Example ===\n")
            
            // Example 1: Text-to-Speech
            await demonstrateTTS(client: client)
            
            // Example 2: EVI Configurations
            await demonstrateEVI(client: client)
            
            // Example 3: Expression Measurement
            await demonstrateExpressionMeasurement(client: client)
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: - TTS Demo
    
    static func demonstrateTTS(client: HumeClient) async {
        print("📢 Text-to-Speech Demo")
        print("=" * 50)
        
        let tts = client.tts
        
        do {
            // List available voices
            print("\n1. Available Voices:")
            let voicesResponse = try await tts.listVoices(pageSize: 5)
            for voice in voicesResponse.voices.prefix(5) {
                print("  - \(voice.name) (\(voice.provider?.rawValue ?? "Unknown"))")
            }
            
            // Simple synthesis
            print("\n2. Simple Synthesis:")
            let response = try await tts.synthesize(text: "Hello from Hume Swift SDK!")
            print("  ✓ Audio URL: \(response.audioUrl ?? "N/A")")
            
            // Synthesis with options
            print("\n3. Advanced Synthesis:")
            let request = tts.request(text: "This is an advanced synthesis example with custom settings.")
                .voiceName("ITO")
                .sampleRate(.hz44100)
                .speed(1.1)
                .volume(0.9)
                .build()
            
            let audioData = try await tts.synthesizeAudio(request)
            print("  ✓ Audio data size: \(audioData.count) bytes")
            print("  ✓ Sample rate: 44100 Hz")
            print("  ✓ Speed: 1.1x")
            print("  ✓ Volume: 90%")
            
        } catch {
            print("  ❌ TTS Error: \(error)")
        }
        
        print("\n")
    }
    
    // MARK: - EVI Demo
    
    static func demonstrateEVI(client: HumeClient) async {
        print("🎭 Empathic Voice Interface Demo")
        print("=" * 50)
        
        let evi = client.evi
        
        do {
            // List built-in configurations
            print("\n1. Built-in Configurations:")
            let builtInConfigs = try await evi.listBuiltInConfigs()
            for config in builtInConfigs.configsPage.prefix(3) {
                print("  - \(config.name) (v\(config.version))")
                if let prompt = config.prompt?.prefix(50) {
                    print("    Prompt: \(prompt)...")
                }
            }
            
            // List tools
            print("\n2. Available Tools:")
            let tools = try await evi.listTools(pageSize: 5)
            if tools.toolsPage.isEmpty {
                print("  No custom tools configured")
            } else {
                for tool in tools.toolsPage {
                    print("  - \(tool.name): \(tool.description ?? "No description")")
                }
            }
            
            // Create a chat session (demo only - requires WebSocket)
            print("\n3. Chat Session:")
            print("  ℹ️ Chat sessions require WebSocket connection")
            print("  ℹ️ Use createChatSession() to start a real-time conversation")
            
        } catch {
            print("  ❌ EVI Error: \(error)")
        }
        
        print("\n")
    }
    
    // MARK: - Expression Measurement Demo
    
    static func demonstrateExpressionMeasurement(client: HumeClient) async {
        print("📊 Expression Measurement Demo")
        print("=" * 50)
        
        let expression = client.expressionMeasurement
        
        do {
            // Create a batch job for text analysis
            print("\n1. Creating Batch Job for Text Analysis:")
            
            let models = ModelConfiguration(
                language: LanguageConfiguration(
                    granularity: .sentence,
                    emotions: EmotionConfiguration()
                )
            )
            
            let request = BatchJobRequest(
                models: models,
                text: [
                    "I'm so excited about this new SDK!",
                    "This makes me feel a bit nervous.",
                    "What a wonderful day it has been!"
                ]
            )
            
            let job = try await expression.createBatchJob(request)
            print("  ✓ Job created: \(job.jobId)")
            print("  ✓ Status: \(job.status.rawValue)")
            
            // Poll for completion (in real usage, implement proper polling)
            print("\n2. Checking Job Status:")
            var currentJob = job
            var attempts = 0
            
            while currentJob.status != .completed && currentJob.status != .failed && attempts < 10 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                currentJob = try await expression.getBatchJob(job.jobId)
                attempts += 1
                print("  Status: \(currentJob.status.rawValue)")
            }
            
            // Get predictions if completed
            if currentJob.status == .completed {
                print("\n3. Job Predictions:")
                let predictions = try await expression.getBatchJobPredictions(job.jobId)
                
                for (index, prediction) in predictions.predictions.enumerated() {
                    print("\n  Text \(index + 1) emotions:")
                    if let language = prediction.models.language {
                        for group in language.groupedPredictions {
                            for emotion in group.predictions.sorted(by: { $0.score > $1.score }).prefix(3) {
                                print("    - \(emotion.name): \(String(format: "%.2f%%", emotion.score * 100))")
                            }
                        }
                    }
                }
            }
            
            // Streaming demo
            print("\n4. Streaming Analysis:")
            print("  ℹ️ Streaming requires WebSocket connection")
            print("  ℹ️ Use createStreamingSession() for real-time analysis")
            
        } catch {
            print("  ❌ Expression Measurement Error: \(error)")
        }
        
        print("\n")
    }
}

// Helper extension for string repetition
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
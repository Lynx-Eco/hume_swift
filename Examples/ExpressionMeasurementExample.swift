import Foundation
import HumeSDK
import ExampleUtils

@main
struct ExpressionMeasurementExample {
    static func main() async {
        // Load environment variables
        EnvLoader.loadEnv()
        
        do {
            print("📊 Hume Expression Measurement Example")
            print("=" * 50)
            
            // Initialize client
            let client = try HumeClient.fromEnvironment()
            let expression = client.expressionMeasurement
            
            // Example 1: Create batch job for text analysis
            print("\n1. Batch Text Analysis:")
            print("-" * 30)
            
            let texts = [
                "I'm absolutely thrilled about this new opportunity! This is the best day ever!",
                "I feel a bit nervous about the upcoming presentation, but I think it will go well.",
                "The weather is gloomy today and it's making me feel a bit down.",
                "This SDK is amazing! I love how easy it is to use.",
                "I'm frustrated that the documentation isn't clearer about this feature."
            ]
            
            do {
                let models = ModelConfiguration(
                    language: LanguageConfiguration(
                        granularity: .sentence,
                        emotions: EmotionConfiguration()
                    )
                )
                
                let request = BatchJobRequest(
                    models: models,
                    text: texts
                )
                
                print("  📤 Creating batch job...")
                let job = try await expression.createBatchJob(request)
                
                print("  ✅ Job created!")
                print("  - Job ID: \(job.jobId)")
                print("  - Status: \(job.status.rawValue)")
                print("  - Created: \(Date(timeIntervalSince1970: Double(job.createdTimestampMs) / 1000))")
                
                // Poll for completion
                print("\n  ⏳ Waiting for job to complete...")
                var currentJob = job
                var attempts = 0
                let maxAttempts = 30
                
                while currentJob.status != .completed && currentJob.status != .failed && attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    currentJob = try await expression.getBatchJob(job.jobId)
                    attempts += 1
                    
                    if attempts % 5 == 0 || currentJob.status == .completed || currentJob.status == .failed {
                        print("  Status: \(currentJob.status.rawValue) (attempt \(attempts)/\(maxAttempts))")
                    }
                }
                
                if currentJob.status == .completed {
                    print("\n  ✅ Job completed!")
                    
                    // Get predictions
                    let predictions = try await expression.getBatchJobPredictions(job.jobId)
                    
                    print("\n  📊 Analysis Results:")
                    print("  -" * 25)
                    
                    for (index, prediction) in predictions.predictions.enumerated() {
                        print("\n  Text \(index + 1): \"\(texts[index])\"")
                        
                        if let language = prediction.models.language {
                            for group in language.groupedPredictions {
                                print("\n    Top emotions:")
                                let topEmotions = group.predictions
                                    .sorted { $0.score > $1.score }
                                    .prefix(5)
                                
                                for emotion in topEmotions {
                                    let percentage = emotion.score * 100
                                    let bar = String(repeating: "█", count: Int(percentage / 5))
                                    print("    - \(emotion.name): \(String(format: "%.1f%%", percentage)) \(bar)")
                                }
                            }
                        }
                    }
                    
                    if !predictions.errors.isEmpty {
                        print("\n  ⚠️  Errors:")
                        for error in predictions.errors {
                            print("  - \(error.file): \(error.message)")
                        }
                    }
                } else if currentJob.status == .failed {
                    print("  ❌ Job failed!")
                } else {
                    print("  ⏱️  Job timed out (still \(currentJob.status.rawValue))")
                }
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            // Example 2: List recent jobs
            print("\n\n2. Recent Jobs:")
            print("-" * 30)
            
            do {
                let jobs = try await expression.listBatchJobs(limit: 5)
                
                if jobs.isEmpty {
                    print("  No jobs found")
                } else {
                    print("  Found \(jobs.count) recent job(s):")
                    for job in jobs {
                        let date = Date(timeIntervalSince1970: Double(job.createdTimestampMs) / 1000)
                        let formatter = DateFormatter()
                        formatter.dateStyle = .short
                        formatter.timeStyle = .short
                        
                        print("\n  - Job ID: \(job.jobId)")
                        print("    Status: \(job.status.rawValue)")
                        print("    Created: \(formatter.string(from: date))")
                        
                        if let startTime = job.startedTimestampMs {
                            let startDate = Date(timeIntervalSince1970: Double(startTime) / 1000)
                            print("    Started: \(formatter.string(from: startDate))")
                        }
                        
                        if let endTime = job.endedTimestampMs {
                            let endDate = Date(timeIntervalSince1970: Double(endTime) / 1000)
                            print("    Ended: \(formatter.string(from: endDate))")
                        }
                    }
                }
            } catch {
                print("  ❌ Error listing jobs: \(error)")
            }
            
            // Example 3: Different model configurations
            print("\n\n3. Multi-Model Analysis:")
            print("-" * 30)
            
            do {
                let models = ModelConfiguration(
                    face: nil, // Would require image/video input
                    prosody: nil, // Would require audio input
                    language: LanguageConfiguration(
                        granularity: .word, // Analyze at word level
                        emotions: EmotionConfiguration()
                    ),
                    ner: NERConfiguration(
                        identifyEmotions: true
                    )
                )
                
                let request = BatchJobRequest(
                    models: models,
                    text: ["I love visiting Paris in the spring! The Eiffel Tower is magnificent."]
                )
                
                print("  📤 Creating job with NER and word-level analysis...")
                let job = try await expression.createBatchJob(request)
                print("  ✅ Job created: \(job.jobId)")
                print("  ℹ️  This would analyze emotions at word level and identify named entities")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            // Example 4: Streaming session info
            print("\n\n4. Streaming API Info:")
            print("-" * 30)
            
            print("  ℹ️  The Expression Measurement API supports real-time streaming")
            print("  📡 Use createStreamingSession() to analyze text/audio in real-time")
            print("  🔄 Send data continuously and receive predictions as they're generated")
            print("\n  Example usage:")
            print("  ```swift")
            print("  let session = try await expression.createStreamingSession(task: task)")
            print("  try await session.connect()")
            print("  try await session.sendText(\"Analyze this text\")")
            print("  ```")
            
            print("\n✨ Expression Measurement Example Complete!")
            
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
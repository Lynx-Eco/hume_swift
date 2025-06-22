import Foundation
import HumeSDK
import ExampleUtils

@main
struct EVIExample {
    static func main() async {
        // Load environment variables
        EnvLoader.loadEnv()
        
        do {
            print("🎭 Hume Empathic Voice Interface (EVI) Example")
            print("=" * 50)
            
            // Initialize client
            let client = try HumeClient.fromEnvironment()
            let evi = client.evi
            
            // Example 1: List built-in configurations
            print("\n1. Built-in Configurations:")
            print("-" * 30)
            
            do {
                let builtInConfigs = try await evi.listBuiltInConfigs()
                print("  Found \(builtInConfigs.configsPage.count) built-in configuration(s):")
                
                for config in builtInConfigs.configsPage {
                    print("\n  📋 \(config.name)")
                    print("  - ID: \(config.id)")
                    print("  - Version: \(config.version)")
                    
                    if let language = config.language {
                        print("  - Language: \(language.rawValue)")
                    }
                    
                    if let voiceName = config.voiceName {
                        print("  - Voice: \(voiceName)")
                    }
                    
                    if let prompt = config.prompt {
                        let preview = String(prompt.prefix(100))
                        print("  - Prompt: \(preview)\(prompt.count > 100 ? "..." : "")")
                    }
                }
            } catch {
                print("  ❌ Error listing built-in configs: \(error)")
            }
            
            // Example 2: List custom configurations
            print("\n\n2. Custom Configurations:")
            print("-" * 30)
            
            do {
                let configs = try await evi.listConfigs(pageSize: 10)
                
                if configs.configsPage.isEmpty {
                    print("  No custom configurations found")
                    print("  ℹ️  You can create custom configs to personalize EVI's behavior")
                } else {
                    print("  Found \(configs.totalItems) custom configuration(s):")
                    print("  Page \(configs.pageNumber + 1) of \(configs.totalPages)")
                    
                    for config in configs.configsPage {
                        print("\n  📋 \(config.name)")
                        print("  - ID: \(config.id)")
                        print("  - Version: \(config.version)")
                        
                        if let created = config.createdOn {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            print("  - Created: \(formatter.string(from: created))")
                        }
                    }
                }
            } catch {
                print("  ❌ Error listing custom configs: \(error)")
            }
            
            // Example 3: Create a custom configuration
            print("\n\n3. Create Custom Configuration:")
            print("-" * 30)
            
            do {
                let newConfig = CreateConfigRequest(
                    name: "Swift SDK Test Config",
                    prompt: "You are a helpful AI assistant created to test the Hume Swift SDK. Be friendly and concise.",
                    language: .en,
                    voiceId: nil // Use default voice
                )
                
                print("  📤 Creating new configuration...")
                let created = try await evi.createConfig(newConfig)
                
                print("  ✅ Configuration created!")
                print("  - ID: \(created.id)")
                print("  - Name: \(created.name)")
                print("  - Version: \(created.version)")
                
                // Update the configuration
                print("\n  📝 Updating configuration...")
                let updateRequest = UpdateConfigRequest(
                    prompt: "You are a helpful AI assistant testing the Hume Swift SDK. Be friendly, concise, and enthusiastic about the SDK's capabilities!"
                )
                
                let updated = try await evi.updateConfig(id: created.id, updateRequest)
                print("  ✅ Configuration updated!")
                print("  - New prompt: \(updated.prompt ?? "N/A")")
                
                // Delete the test configuration
                print("\n  🗑️  Cleaning up test configuration...")
                try await evi.deleteConfig(id: created.id)
                print("  ✅ Configuration deleted")
                
            } catch {
                print("  ❌ Error with configuration: \(error)")
            }
            
            // Example 4: List tools
            print("\n\n4. Available Tools:")
            print("-" * 30)
            
            do {
                let tools = try await evi.listTools(pageSize: 10)
                
                if tools.toolsPage.isEmpty {
                    print("  No custom tools configured")
                    print("  ℹ️  Tools allow EVI to perform actions during conversations")
                } else {
                    print("  Found \(tools.totalItems) tool(s):")
                    
                    for tool in tools.toolsPage {
                        print("\n  🔧 \(tool.name)")
                        print("  - ID: \(tool.id)")
                        print("  - Version: \(tool.version)")
                        
                        if let description = tool.description {
                            print("  - Description: \(description)")
                        }
                        
                        // Show parameter structure
                        if let paramsData = tool.parameters.data(using: .utf8),
                           let _ = try? JSONSerialization.jsonObject(with: paramsData) {
                            print("  - Parameters: \(tool.parameters)")
                        }
                    }
                }
            } catch {
                print("  ❌ Error listing tools: \(error)")
            }
            
            // Example 5: Create and manage a tool
            print("\n\n5. Tool Management:")
            print("-" * 30)
            
            do {
                let toolParams = """
                {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The search query"
                        }
                    },
                    "required": ["query"]
                }
                """
                
                let newTool = CreateToolRequest(
                    name: "search_web",
                    description: "Search the web for information",
                    parameters: toolParams,
                    fallbackContent: "I'll search for that information."
                )
                
                print("  📤 Creating new tool...")
                let created = try await evi.createTool(newTool)
                
                print("  ✅ Tool created!")
                print("  - ID: \(created.id)")
                print("  - Name: \(created.name)")
                print("  - Version: \(created.version)")
                
                // Update the tool
                print("\n  📝 Updating tool...")
                let updateRequest = UpdateToolRequest(
                    description: "Search the web for current information and news"
                )
                
                let updated = try await evi.updateTool(id: created.id, updateRequest)
                print("  ✅ Tool updated!")
                print("  - New description: \(updated.description ?? "N/A")")
                
                // Delete the test tool
                print("\n  🗑️  Cleaning up test tool...")
                try await evi.deleteTool(id: created.id)
                print("  ✅ Tool deleted")
                
            } catch {
                print("  ❌ Error with tool: \(error)")
            }
            
            // Example 6: Chat session info
            print("\n\n6. Chat Sessions:")
            print("-" * 30)
            
            print("  ℹ️  EVI Chat enables real-time conversations with emotional intelligence")
            print("  🎤 Features:")
            print("  - Real-time audio streaming")
            print("  - Emotion detection and response")
            print("  - Interruption handling")
            print("  - Custom configurations and tools")
            
            print("\n  Example usage:")
            print("  ```swift")
            print("  // Create a chat session")
            print("  let session = try await evi.createChatSession(")
            print("      configId: \"config-id\",")
            print("      configVersion: 1")
            print("  )")
            print("  ")
            print("  // Connect to the session")
            print("  try await session.connect()")
            print("  ")
            print("  // Send messages")
            print("  try await session.sendText(\"Hello!\")")
            print("  try await session.sendAudio(audioData)")
            print("  ")
            print("  // Handle responses")
            print("  session.onMessage { message in")
            print("      switch message {")
            print("      case .assistantMessage(let msg):")
            print("          print(\"Assistant: \\(msg.text)\")")
            print("      case .audioOutput(let audio):")
            print("          // Play audio.data")
            print("      default:")
            print("          break")
            print("      }")
            print("  }")
            print("  ```")
            
            // Example 7: Get specific configuration details
            print("\n\n7. Configuration Details:")
            print("-" * 30)
            
            do {
                // Try to get a built-in config
                let builtInConfigs = try await evi.listBuiltInConfigs()
                if let firstConfig = builtInConfigs.configsPage.first {
                    print("  📋 Fetching details for: \(firstConfig.name)")
                    
                    let detailed = try await evi.getConfig(id: firstConfig.id)
                    
                    print("  ✅ Configuration details:")
                    print("  - ID: \(detailed.id)")
                    print("  - Name: \(detailed.name)")
                    print("  - Version: \(detailed.version)")
                    
                    if let prompt = detailed.prompt {
                        print("\n  Full prompt:")
                        print("  \"\"\"\n  \(prompt)\n  \"\"\"")
                    }
                }
            } catch {
                print("  ❌ Error getting config details: \(error)")
            }
            
            print("\n✨ EVI Example Complete!")
            
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
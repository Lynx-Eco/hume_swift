import Foundation

/// Simple .env file loader
struct EnvLoader {
    static func loadEnv() {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let envPath = "\(currentPath)/.env"
        
        guard let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            print("Warning: .env file not found at \(envPath)")
            return
        }
        
        let lines = envContent.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }
            
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            
            setenv(key, value, 1)
        }
    }
}
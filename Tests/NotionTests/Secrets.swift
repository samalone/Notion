import Foundation

actor Secrets {
    private var secrets: [String: String] = [:]

    public static let shared = Secrets(from: "/Volumes/Campfire/Projects/Notion/.envrc")

    init(from envFile: String? = nil) {
        // Load secrets from environment variables
        let env = ProcessInfo.processInfo.environment
        for (key, value) in env {
            secrets[key] = value
        }

        // Load secrets from a file
        if let file = envFile {
            // Use the project directory to find the env file
            let fileURL = URL(filePath: file)
            
            do {
                let fileContents = try String(contentsOf: fileURL)
                let lines = fileContents.split(separator: "\n")
                for line in lines {
                    let parts = line.split(separator: "=", maxSplits: 1)
                    if parts.count == 2 {
                        secrets[String(parts[0])] = String(parts[1])
                    }
                }
            } catch {
                print("Error loading environment file at \(fileURL.path): \(error.localizedDescription)")
                // Continue with execution - we'll just use the environment variables we already loaded
            }
        }
    }

    func get(_ key: String) -> String? {
        return secrets[key]
    }
}
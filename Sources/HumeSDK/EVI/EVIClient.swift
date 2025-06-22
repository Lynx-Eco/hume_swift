import Foundation

/// Client for Empathic Voice Interface (EVI) API
public class EVIClient {
    private let client: HumeClient
    
    /// Initialize EVI client
    /// - Parameter client: The Hume client instance
    public init(client: HumeClient) {
        self.client = client
    }
    
    // MARK: - Configurations
    
    /// List all configurations
    /// - Parameters:
    ///   - pageNumber: Page number (0-indexed)
    ///   - pageSize: Number of items per page
    ///   - options: Additional request options
    /// - Returns: Configurations response
    public func listConfigs(
        pageNumber: Int = 0,
        pageSize: Int = 10,
        options: RequestOptions? = nil
    ) async throws -> ConfigurationsResponse {
        var queryParams = [
            "page_number": String(pageNumber),
            "page_size": String(pageSize)
        ]
        
        var requestOptions = options ?? RequestOptions()
        if let existingParams = requestOptions.queryParameters {
            queryParams.merge(existingParams) { _, new in new }
        }
        requestOptions.queryParameters = queryParams
        
        return try await client.http.get(
            "/v0/evi/configs",
            responseType: ConfigurationsResponse.self,
            options: requestOptions
        )
    }
    
    /// List built-in configurations
    /// - Parameter options: Additional request options
    /// - Returns: Built-in configurations response
    public func listBuiltInConfigs(
        options: RequestOptions? = nil
    ) async throws -> ConfigurationsResponseBuiltIn {
        return try await client.http.get(
            "/v0/evi/configs?filter=built-in",
            responseType: ConfigurationsResponseBuiltIn.self,
            options: options
        )
    }
    
    /// Get a specific configuration
    /// - Parameters:
    ///   - id: Configuration ID
    ///   - version: Configuration version (optional)
    ///   - options: Additional request options
    /// - Returns: EVI configuration
    public func getConfig(
        id: String,
        version: Int? = nil,
        options: RequestOptions? = nil
    ) async throws -> EVIConfig {
        var path = "/v0/evi/configs/\(id)"
        if let version = version {
            path += "?version=\(version)"
        }
        
        return try await client.http.get(
            path,
            responseType: EVIConfig.self,
            options: options
        )
    }
    
    /// Create a new configuration
    /// - Parameters:
    ///   - request: Configuration creation request
    ///   - options: Additional request options
    /// - Returns: Created EVI configuration
    public func createConfig(
        _ request: CreateConfigRequest,
        options: RequestOptions? = nil
    ) async throws -> EVIConfig {
        return try await client.http.post(
            "/v0/evi/configs",
            body: request,
            responseType: EVIConfig.self,
            options: options
        )
    }
    
    /// Update a configuration
    /// - Parameters:
    ///   - id: Configuration ID
    ///   - request: Configuration update request
    ///   - options: Additional request options
    /// - Returns: Updated EVI configuration
    public func updateConfig(
        id: String,
        _ request: UpdateConfigRequest,
        options: RequestOptions? = nil
    ) async throws -> EVIConfig {
        return try await client.http.patch(
            "/v0/evi/configs/\(id)",
            body: request,
            responseType: EVIConfig.self,
            options: options
        )
    }
    
    /// Delete a configuration
    /// - Parameters:
    ///   - id: Configuration ID
    ///   - options: Additional request options
    public func deleteConfig(
        id: String,
        options: RequestOptions? = nil
    ) async throws {
        let _: EmptyResponse = try await client.http.delete(
            "/v0/evi/configs/\(id)",
            responseType: EmptyResponse.self,
            options: options
        )
    }
    
    // MARK: - Tools
    
    /// List all tools
    /// - Parameters:
    ///   - pageNumber: Page number (0-indexed)
    ///   - pageSize: Number of items per page
    ///   - options: Additional request options
    /// - Returns: Tools response
    public func listTools(
        pageNumber: Int = 0,
        pageSize: Int = 10,
        options: RequestOptions? = nil
    ) async throws -> ToolsResponse {
        var queryParams = [
            "page_number": String(pageNumber),
            "page_size": String(pageSize)
        ]
        
        var requestOptions = options ?? RequestOptions()
        if let existingParams = requestOptions.queryParameters {
            queryParams.merge(existingParams) { _, new in new }
        }
        requestOptions.queryParameters = queryParams
        
        return try await client.http.get(
            "/v0/evi/tools",
            responseType: ToolsResponse.self,
            options: requestOptions
        )
    }
    
    /// Get a specific tool
    /// - Parameters:
    ///   - id: Tool ID
    ///   - version: Tool version (optional)
    ///   - options: Additional request options
    /// - Returns: EVI tool
    public func getTool(
        id: String,
        version: Int? = nil,
        options: RequestOptions? = nil
    ) async throws -> EVITool {
        var path = "/v0/evi/tools/\(id)"
        if let version = version {
            path += "?version=\(version)"
        }
        
        return try await client.http.get(
            path,
            responseType: EVITool.self,
            options: options
        )
    }
    
    /// Create a new tool
    /// - Parameters:
    ///   - request: Tool creation request
    ///   - options: Additional request options
    /// - Returns: Created EVI tool
    public func createTool(
        _ request: CreateToolRequest,
        options: RequestOptions? = nil
    ) async throws -> EVITool {
        return try await client.http.post(
            "/v0/evi/tools",
            body: request,
            responseType: EVITool.self,
            options: options
        )
    }
    
    /// Update a tool
    /// - Parameters:
    ///   - id: Tool ID
    ///   - request: Tool update request
    ///   - options: Additional request options
    /// - Returns: Updated EVI tool
    public func updateTool(
        id: String,
        _ request: UpdateToolRequest,
        options: RequestOptions? = nil
    ) async throws -> EVITool {
        return try await client.http.patch(
            "/v0/evi/tools/\(id)",
            body: request,
            responseType: EVITool.self,
            options: options
        )
    }
    
    /// Delete a tool
    /// - Parameters:
    ///   - id: Tool ID
    ///   - options: Additional request options
    public func deleteTool(
        id: String,
        options: RequestOptions? = nil
    ) async throws {
        let _: EmptyResponse = try await client.http.delete(
            "/v0/evi/tools/\(id)",
            responseType: EmptyResponse.self,
            options: options
        )
    }
    
    // MARK: - Chat
    
    /// Create a chat WebSocket connection
    /// - Parameters:
    ///   - configId: Configuration ID to use
    ///   - configVersion: Configuration version (optional)
    ///   - options: Additional request options
    /// - Returns: EVI chat session
    public func createChatSession(
        configId: String? = nil,
        configVersion: Int? = nil,
        options: RequestOptions? = nil
    ) async throws -> EVIChatSession {
        var queryParams: [String: String] = [:]
        
        if let configId = configId {
            queryParams["config_id"] = configId
        }
        
        if let configVersion = configVersion {
            queryParams["config_version"] = String(configVersion)
        }
        
        // Build WebSocket URL
        let baseURL = client.getBaseURL()
        guard var components = URLComponents(string: baseURL) else {
            throw HumeError.invalidURL(url: baseURL)
        }
        
        // Change scheme to wss
        components.scheme = "wss"
        components.path = "/v0/evi/chat"
        
        // Add query parameters
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let wsURL = components.url else {
            throw HumeError.invalidURL(url: baseURL)
        }
        
        // Create WebSocket client
        let authProvider = client.getAuthProvider()
        let webSocket = TypedWebSocketClient<AnyChatMessage, ServerMessage>(
            url: wsURL,
            authProvider: authProvider
        )
        
        return EVIChatSession(webSocket: webSocket)
    }
}

// MARK: - Chat Session

/// EVI chat session for real-time communication
public class EVIChatSession {
    private let webSocket: TypedWebSocketClient<AnyChatMessage, ServerMessage>
    private var messageHandlers: [(ServerMessage) async -> Void] = []
    private var errorHandlers: [(Error) async -> Void] = []
    private var disconnectHandlers: [(String?) async -> Void] = []
    
    init(webSocket: TypedWebSocketClient<AnyChatMessage, ServerMessage>) {
        self.webSocket = webSocket
        
        // Set up message handling
        Task { [weak self] in
            await webSocket.onMessage { message in
                await self?.handleMessage(message)
            }
            
            await webSocket.onError { error in
                await self?.handleError(error)
            }
            
            await webSocket.onDisconnect { reason in
                await self?.handleDisconnect(reason)
            }
        }
    }
    
    /// Connect to the chat session
    public func connect() async throws {
        try await webSocket.connect()
    }
    
    /// Disconnect from the chat session
    public func disconnect(reason: String? = nil) async {
        await webSocket.disconnect(reason: reason)
    }
    
    /// Send a text message
    public func sendText(_ text: String) async throws {
        let message = UserMessage(text: text)
        try await webSocket.send(AnyChatMessage(message))
    }
    
    /// Send audio data
    public func sendAudio(_ data: Data) async throws {
        let message = AudioInput(data: data)
        try await webSocket.send(AnyChatMessage(message))
    }
    
    /// Update session settings
    public func updateSettings(_ settings: SessionSettings) async throws {
        try await webSocket.send(AnyChatMessage(settings))
    }
    
    /// Add a message handler
    public func onMessage(_ handler: @escaping (ServerMessage) async -> Void) {
        messageHandlers.append(handler)
    }
    
    /// Add a specific message type handler
    public func onMessageType<T>(_ type: T.Type, handler: @escaping (T) async -> Void) where T: Decodable {
        onMessage { message in
            switch message {
            case .userMessage(let msg) where T.self == UserMessageResponse.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .assistantMessage(let msg) where T.self == AssistantMessageResponse.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .audioOutput(let msg) where T.self == AudioOutputResponse.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .userInterruption(let msg) where T.self == UserInterruptionResponse.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .error(let msg) where T.self == ErrorResponse.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            default:
                break
            }
        }
    }
    
    /// Add an error handler
    public func onError(_ handler: @escaping (Error) async -> Void) {
        errorHandlers.append(handler)
    }
    
    /// Add a disconnect handler
    public func onDisconnect(_ handler: @escaping (String?) async -> Void) {
        disconnectHandlers.append(handler)
    }
    
    // MARK: - Private Methods
    
    private func handleMessage(_ message: ServerMessage) async {
        for handler in messageHandlers {
            await handler(message)
        }
    }
    
    private func handleError(_ error: Error) async {
        for handler in errorHandlers {
            await handler(error)
        }
    }
    
    private func handleDisconnect(_ reason: String?) async {
        for handler in disconnectHandlers {
            await handler(reason)
        }
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {}
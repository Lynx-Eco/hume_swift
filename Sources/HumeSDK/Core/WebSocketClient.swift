import Foundation
import os.log

/// WebSocket client for real-time communication
public actor WebSocketClient {
    // MARK: - Types
    
    /// WebSocket connection state
    public enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
    
    /// WebSocket message
    public enum Message {
        case text(String)
        case data(Data)
    }
    
    // MARK: - Properties
    
    private let url: URL
    private let authProvider: AuthenticationProvider
    private var task: URLSessionWebSocketTask?
    private var session: URLSession
    private let logger: Logger
    
    private var connectionState: ConnectionState = .disconnected
    private var messageHandlers: [(Message) async -> Void] = []
    private var errorHandlers: [(Error) async -> Void] = []
    private var disconnectHandlers: [(String?) async -> Void] = []
    
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        url: URL,
        authProvider: AuthenticationProvider,
        session: URLSession? = nil
    ) {
        self.url = url
        self.authProvider = authProvider
        self.session = session ?? URLSession(configuration: .default)
        self.logger = Logger(subsystem: "ai.hume.sdk", category: "WebSocketClient")
    }
    
    // MARK: - Connection Management
    
    /// Connect to the WebSocket
    public func connect() async throws {
        guard connectionState == .disconnected else {
            logger.warning("Already connected or connecting")
            return
        }
        
        connectionState = .connecting
        
        // Add authentication to URL
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let auth = try await authProvider.getAuthentication()
        
        if let queryParam = auth.queryParameter {
            var queryItems = urlComponents.queryItems ?? []
            queryItems.append(queryParam)
            urlComponents.queryItems = queryItems
        }
        
        guard let authenticatedURL = urlComponents.url else {
            throw HumeError.invalidURL(url: url.absoluteString)
        }
        
        // Create WebSocket task
        var request = URLRequest(url: authenticatedURL)
        request.setValue("HumeSwiftSDK/0.9.0", forHTTPHeaderField: "User-Agent")
        
        task = session.webSocketTask(with: request)
        task?.resume()
        
        // Start receiving messages
        receiveTask = Task { [weak self] in
            await self?.startReceiving()
        }
        
        // Start ping/pong to keep connection alive
        pingTask = Task { [weak self] in
            await self?.startPing()
        }
        
        connectionState = .connected
        logger.info("WebSocket connected to \(self.url)")
    }
    
    /// Disconnect from the WebSocket
    public func disconnect(reason: String? = nil) async {
        guard connectionState == .connected else {
            logger.warning("Not connected")
            return
        }
        
        connectionState = .disconnecting
        
        // Cancel tasks
        receiveTask?.cancel()
        pingTask?.cancel()
        
        // Close WebSocket
        if let reason = reason {
            task?.cancel(with: .goingAway, reason: reason.data(using: .utf8))
        } else {
            task?.cancel(with: .goingAway, reason: nil)
        }
        
        task = nil
        connectionState = .disconnected
        
        // Notify handlers
        for handler in disconnectHandlers {
            await handler(reason)
        }
        
        logger.info("WebSocket disconnected")
    }
    
    /// Get current connection state
    public func getConnectionState() -> ConnectionState {
        return connectionState
    }
    
    // MARK: - Message Handling
    
    /// Send a text message
    public func sendText(_ text: String) async throws {
        guard connectionState == .connected else {
            throw HumeError.webSocketDisconnected(reason: "Not connected")
        }
        
        guard let task = task else {
            throw HumeError.webSocketDisconnected(reason: "No active task")
        }
        
        do {
            try await task.send(.string(text))
            logger.debug("Sent text message: \(text.prefix(100))...")
        } catch {
            logger.error("Failed to send text message: \(error)")
            throw HumeError.webSocketSend(error)
        }
    }
    
    /// Send a data message
    public func sendData(_ data: Data) async throws {
        guard connectionState == .connected else {
            throw HumeError.webSocketDisconnected(reason: "Not connected")
        }
        
        guard let task = task else {
            throw HumeError.webSocketDisconnected(reason: "No active task")
        }
        
        do {
            try await task.send(.data(data))
            logger.debug("Sent data message: \(data.count) bytes")
        } catch {
            logger.error("Failed to send data message: \(error)")
            throw HumeError.webSocketSend(error)
        }
    }
    
    /// Send a Codable message
    public func sendMessage<T: Encodable>(_ message: T) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let text = String(data: data, encoding: .utf8)!
        try await sendText(text)
    }
    
    /// Add a message handler
    public func onMessage(_ handler: @escaping (Message) async -> Void) {
        messageHandlers.append(handler)
    }
    
    /// Add a typed message handler
    public func onMessage<T: Decodable>(
        type: T.Type,
        handler: @escaping (T) async -> Void
    ) {
        onMessage { message in
            guard case .text(let text) = message else { return }
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)
                await handler(decoded)
            } catch {
                // Log but don't crash - message might be of different type
                self.logger.debug("Failed to decode message as \(T.self): \(error)")
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
    
    private func startReceiving() async {
        guard let task = task else { return }
        
        while connectionState == .connected && !Task.isCancelled {
            do {
                let message = try await task.receive()
                
                switch message {
                case .string(let text):
                    logger.debug("Received text message: \(text.prefix(100))...")
                    await handleMessage(.text(text))
                    
                case .data(let data):
                    logger.debug("Received data message: \(data.count) bytes")
                    await handleMessage(.data(data))
                    
                @unknown default:
                    logger.warning("Received unknown message type")
                }
            } catch {
                if connectionState == .connected {
                    logger.error("WebSocket receive error: \(error)")
                    await handleError(error)
                    
                    // Disconnect on error
                    await disconnect(reason: "Receive error: \(error)")
                }
                break
            }
        }
    }
    
    private func startPing() async {
        while connectionState == .connected && !Task.isCancelled {
            do {
                // Send ping every 30 seconds
                try await Task.sleep(nanoseconds: 30_000_000_000)
                
                if let task = task, connectionState == .connected {
                    try await task.sendPing { _ in }
                    logger.debug("Sent ping")
                }
            } catch {
                if connectionState == .connected {
                    logger.error("Ping failed: \(error)")
                }
            }
        }
    }
    
    private func handleMessage(_ message: Message) async {
        for handler in messageHandlers {
            await handler(message)
        }
    }
    
    private func handleError(_ error: Error) async {
        for handler in errorHandlers {
            await handler(error)
        }
    }
}

// MARK: - Typed WebSocket Client

/// Generic WebSocket client for typed messages
public actor TypedWebSocketClient<SendMessage: Encodable, ReceiveMessage: Decodable> {
    private let webSocket: WebSocketClient
    private var messageHandler: ((ReceiveMessage) async -> Void)?
    
    public init(
        url: URL,
        authProvider: AuthenticationProvider,
        session: URLSession? = nil
    ) {
        self.webSocket = WebSocketClient(
            url: url,
            authProvider: authProvider,
            session: session
        )
        
        // Set up message decoding
        Task { [weak self] in
            await self?.webSocket.onMessage { message in
                await self?.handleMessage(message)
            }
        }
    }
    
    /// Connect to the WebSocket
    public func connect() async throws {
        try await webSocket.connect()
    }
    
    /// Disconnect from the WebSocket
    public func disconnect(reason: String? = nil) async {
        await webSocket.disconnect(reason: reason)
    }
    
    /// Send a message
    public func send(_ message: SendMessage) async throws {
        try await webSocket.sendMessage(message)
    }
    
    /// Set the message handler
    public func onMessage(_ handler: @escaping (ReceiveMessage) async -> Void) {
        self.messageHandler = handler
    }
    
    /// Set the error handler
    public func onError(_ handler: @escaping (Error) async -> Void) async {
        await webSocket.onError(handler)
    }
    
    /// Set the disconnect handler
    public func onDisconnect(_ handler: @escaping (String?) async -> Void) async {
        await webSocket.onDisconnect(handler)
    }
    
    private func handleMessage(_ message: WebSocketClient.Message) async {
        guard case .text(let text) = message else { return }
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ReceiveMessage.self, from: data)
            await messageHandler?(decoded)
        } catch {
            // Log decoding error
            print("Failed to decode message: \(error)")
        }
    }
}
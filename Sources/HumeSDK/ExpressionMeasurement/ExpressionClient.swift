import Foundation

/// Client for Expression Measurement API
public class ExpressionMeasurementClient {
    private let client: HumeClient
    
    /// Initialize Expression Measurement client
    /// - Parameter client: The Hume client instance
    public init(client: HumeClient) {
        self.client = client
    }
    
    // MARK: - Batch API
    
    /// Create a batch job
    /// - Parameters:
    ///   - request: Batch job request
    ///   - options: Additional request options
    /// - Returns: Created batch job
    public func createBatchJob(
        _ request: BatchJobRequest,
        options: RequestOptions? = nil
    ) async throws -> BatchJob {
        // First create the job
        let response: JobCreationResponse = try await client.http.post(
            "/v0/batch/jobs",
            body: request,
            responseType: JobCreationResponse.self,
            options: options
        )
        
        // Then fetch the full job details
        return try await getBatchJob(response.jobId, options: options)
    }
    
    /// Get a batch job by ID
    /// - Parameters:
    ///   - jobId: Job ID
    ///   - options: Additional request options
    /// - Returns: Batch job details
    public func getBatchJob(
        _ jobId: String,
        options: RequestOptions? = nil
    ) async throws -> BatchJob {
        return try await client.http.get(
            "/v0/batch/jobs/\(jobId)",
            responseType: BatchJob.self,
            options: options
        )
    }
    
    /// List batch jobs
    /// - Parameters:
    ///   - limit: Maximum number of jobs to return
    ///   - offset: Number of jobs to skip
    ///   - options: Additional request options
    /// - Returns: Array of batch jobs
    public func listBatchJobs(
        limit: Int = 100,
        offset: Int = 0,
        options: RequestOptions? = nil
    ) async throws -> [BatchJob] {
        var queryParams = [
            "limit": String(limit),
            "offset": String(offset)
        ]
        
        var requestOptions = options ?? RequestOptions()
        if let existingParams = requestOptions.queryParameters {
            queryParams.merge(existingParams) { _, new in new }
        }
        requestOptions.queryParameters = queryParams
        
        let response: [BatchJob] = try await client.http.get(
            "/v0/batch/jobs",
            responseType: [BatchJob].self,
            options: requestOptions
        )
        
        return response
    }
    
    /// Get predictions for a batch job
    /// - Parameters:
    ///   - jobId: Job ID
    ///   - options: Additional request options
    /// - Returns: Predictions response
    public func getBatchJobPredictions(
        _ jobId: String,
        options: RequestOptions? = nil
    ) async throws -> PredictionsResponse {
        return try await client.http.get(
            "/v0/batch/jobs/\(jobId)/predictions",
            responseType: PredictionsResponse.self,
            options: options
        )
    }
    
    /// Delete a batch job
    /// - Parameters:
    ///   - jobId: Job ID
    ///   - options: Additional request options
    public func deleteBatchJob(
        _ jobId: String,
        options: RequestOptions? = nil
    ) async throws {
        let _: EmptyResponse = try await client.http.delete(
            "/v0/batch/jobs/\(jobId)",
            responseType: EmptyResponse.self,
            options: options
        )
    }
    
    // MARK: - Streaming API
    
    /// Create a streaming session
    /// - Parameters:
    ///   - task: Stream expression task
    ///   - options: Additional request options
    /// - Returns: Expression streaming session
    public func createStreamingSession(
        task: StreamExpressionTask,
        options: RequestOptions? = nil
    ) async throws -> ExpressionStreamingSession {
        // Build WebSocket URL
        let baseURL = client.getBaseURL()
        guard var components = URLComponents(string: baseURL) else {
            throw HumeError.invalidURL(url: baseURL)
        }
        
        // Change scheme to wss
        components.scheme = "wss"
        components.path = "/v0/stream/models"
        
        guard let wsURL = components.url else {
            throw HumeError.invalidURL(url: baseURL)
        }
        
        // Create WebSocket client
        let authProvider = client.getAuthProvider()
        let webSocket = TypedWebSocketClient<StreamExpressionTask, StreamMessage>(
            url: wsURL,
            authProvider: authProvider
        )
        
        return ExpressionStreamingSession(webSocket: webSocket, task: task)
    }
}

// MARK: - Streaming Session

/// Expression measurement streaming session
public class ExpressionStreamingSession {
    private let webSocket: TypedWebSocketClient<StreamExpressionTask, StreamMessage>
    private let task: StreamExpressionTask
    private var messageHandlers: [(StreamMessage) async -> Void] = []
    private var errorHandlers: [(Error) async -> Void] = []
    private var disconnectHandlers: [(String?) async -> Void] = []
    
    init(
        webSocket: TypedWebSocketClient<StreamExpressionTask, StreamMessage>,
        task: StreamExpressionTask
    ) {
        self.webSocket = webSocket
        self.task = task
        
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
    
    /// Connect to the streaming session
    public func connect() async throws {
        try await webSocket.connect()
        
        // Send the task configuration
        try await webSocket.send(task)
    }
    
    /// Disconnect from the streaming session
    public func disconnect(reason: String? = nil) async {
        await webSocket.disconnect(reason: reason)
    }
    
    /// Send text for analysis
    public func sendText(_ text: String) async throws {
        let payload = ["text": text]
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let json = String(data: data, encoding: .utf8)!
        
        // Send as raw WebSocket message
        let webSocketClient = webSocket as Any
        if let ws = webSocketClient as? WebSocketClient {
            try await ws.sendText(json)
        }
    }
    
    /// Send data for analysis
    public func sendData(_ data: Data) async throws {
        // Send as raw WebSocket message
        let webSocketClient = webSocket as Any
        if let ws = webSocketClient as? WebSocketClient {
            try await ws.sendData(data)
        }
    }
    
    /// Add a message handler
    public func onMessage(_ handler: @escaping (StreamMessage) async -> Void) {
        messageHandlers.append(handler)
    }
    
    /// Add a specific message type handler
    public func onMessageType<T>(_ type: T.Type, handler: @escaping (T) async -> Void) where T: Decodable {
        onMessage { message in
            switch message {
            case .modelPredictions(let msg) where T.self == ModelPredictionsMessage.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .error(let msg) where T.self == StreamErrorMessage.self:
                if let typedMsg = msg as? T {
                    await handler(typedMsg)
                }
            case .jobDetails(let msg) where T.self == JobDetailsMessage.self:
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
    
    private func handleMessage(_ message: StreamMessage) async {
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
import Foundation
import os.log

/// HTTP client for making API requests with retry logic
public actor HTTPClient {
    // MARK: - Properties
    
    private let baseURL: URL
    private let authProvider: AuthenticationProvider
    private let defaultTimeout: TimeInterval
    private let defaultRetryPolicy: RetryPolicy
    private let session: URLSession
    private let logger: Logger
    
    /// SDK version for User-Agent header
    private let sdkVersion = "0.9.0"
    
    // MARK: - Initialization
    
    public init(
        baseURL: URL,
        authProvider: AuthenticationProvider,
        timeout: TimeInterval = 60.0,
        retryPolicy: RetryPolicy = .default,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.authProvider = authProvider
        self.defaultTimeout = timeout
        self.defaultRetryPolicy = retryPolicy
        self.session = session ?? .shared
        self.logger = Logger(subsystem: "ai.hume.sdk", category: "HTTPClient")
    }
    
    // MARK: - Public Methods
    
    /// Perform a GET request
    public func get<T: Decodable>(
        _ path: String,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let data = try await request(
            method: "GET",
            path: path,
            body: nil as Data?,
            options: options
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Perform a GET request returning raw data
    public func getData(
        _ path: String,
        options: RequestOptions? = nil
    ) async throws -> Data {
        return try await request(
            method: "GET",
            path: path,
            body: nil as Data?,
            options: options
        )
    }
    
    /// Perform a POST request
    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B?,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let data = try await request(
            method: "POST",
            path: path,
            body: body,
            options: options
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Perform a POST request returning raw data
    public func postData<B: Encodable>(
        _ path: String,
        body: B?,
        options: RequestOptions? = nil
    ) async throws -> Data {
        return try await request(
            method: "POST",
            path: path,
            body: body,
            options: options
        )
    }
    
    /// Perform a PUT request
    public func put<T: Decodable, B: Encodable>(
        _ path: String,
        body: B?,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let data = try await request(
            method: "PUT",
            path: path,
            body: body,
            options: options
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Perform a PATCH request
    public func patch<T: Decodable, B: Encodable>(
        _ path: String,
        body: B?,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let data = try await request(
            method: "PATCH",
            path: path,
            body: body,
            options: options
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Perform a DELETE request
    public func delete(
        _ path: String,
        options: RequestOptions? = nil
    ) async throws {
        _ = try await request(
            method: "DELETE",
            path: path,
            body: nil as Data?,
            options: options
        )
    }
    
    /// Perform a DELETE request with response
    public func delete<T: Decodable>(
        _ path: String,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let data = try await request(
            method: "DELETE",
            path: path,
            body: nil as Data?,
            options: options
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Upload file with multipart/form-data
    public func uploadFile<T: Decodable>(
        _ path: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String]? = nil,
        responseType: T.Type,
        options: RequestOptions? = nil
    ) async throws -> T {
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var modifiedOptions = options ?? RequestOptions()
        var headers = modifiedOptions.headers ?? [:]
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        modifiedOptions.headers = headers
        
        let data = try await request(
            method: "POST",
            path: path,
            body: body,
            options: modifiedOptions,
            skipJSONEncoding: true
        )
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func request<B: Encodable>(
        method: String,
        path: String,
        body: B?,
        options: RequestOptions?,
        skipJSONEncoding: Bool = false
    ) async throws -> Data {
        // Merge options
        let effectiveOptions = (options ?? RequestOptions()).merged(
            with: RequestOptions(
                timeout: defaultTimeout,
                retryPolicy: defaultRetryPolicy
            )
        )
        
        // Build URL
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            throw HumeError.invalidURL(url: path)
        }
        
        // Add query parameters
        if let queryParams = effectiveOptions.queryParameters {
            var queryItems = urlComponents.queryItems ?? []
            for (key, value) in queryParams {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        }
        
        guard let url = urlComponents.url else {
            throw HumeError.invalidURL(url: path)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = effectiveOptions.timeout ?? defaultTimeout
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HumeSwiftSDK/\(sdkVersion)", forHTTPHeaderField: "User-Agent")
        
        // Add authentication
        let auth = try await authProvider.getAuthentication()
        request.setValue(auth.headerValue, forHTTPHeaderField: auth.headerField)
        
        // Add custom headers
        if let headers = effectiveOptions.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body
        if let body = body {
            if skipJSONEncoding, let bodyData = body as? Data {
                request.httpBody = bodyData
            } else {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(body)
            }
        }
        
        // Execute request with retry
        return try await executeWithRetry(request: request, options: effectiveOptions)
    }
    
    private func request(
        method: String,
        path: String,
        body: Data?,
        options: RequestOptions?,
        skipJSONEncoding: Bool = true
    ) async throws -> Data {
        // This overload handles raw Data bodies
        return try await request(
            method: method,
            path: path,
            body: body.map { DataWrapper(data: $0) },
            options: options,
            skipJSONEncoding: skipJSONEncoding
        )
    }
    
    private func executeWithRetry(
        request: URLRequest,
        options: RequestOptions
    ) async throws -> Data {
        let retryPolicy = options.retryPolicy ?? defaultRetryPolicy
        var retryState = RetryState()
        
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HumeError.invalidResponse(message: "Invalid response type")
                }
                
                // Log response
                logger.debug("Response: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? "")")
                
                // Check for success
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                }
                
                // Parse error response
                let error = try parseError(from: data, statusCode: httpResponse.statusCode, response: httpResponse)
                
                // Check if retryable
                if retryPolicy.isRetryable(statusCode: httpResponse.statusCode) {
                    retryState = retryState.nextAttempt(with: error)
                    
                    if retryState.shouldRetry(with: retryPolicy) {
                        // Calculate delay
                        var delay = retryPolicy.delay(for: retryState.attempt)
                        
                        // Check for Retry-After header
                        if let retryAfterValue = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                           let retryAfter = RetryAfterParser.parse(retryAfterValue) {
                            // Cap retry-after at 30 seconds
                            delay = min(retryAfter, 30.0)
                        }
                        
                        logger.debug("Retrying after \(delay) seconds (attempt \(retryState.attempt))")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                throw error
                
            } catch {
                // Handle non-HTTP errors
                if error is HumeError {
                    throw error
                }
                
                // Check if retryable
                if retryPolicy.isRetryable(error: error) {
                    retryState = retryState.nextAttempt(with: error)
                    
                    if retryState.shouldRetry(with: retryPolicy) {
                        let delay = retryPolicy.delay(for: retryState.attempt)
                        logger.debug("Retrying after \(delay) seconds (attempt \(retryState.attempt))")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // Wrap in HumeError if needed
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        throw HumeError.timeout
                    case .notConnectedToInternet:
                        throw HumeError.noConnection
                    default:
                        throw HumeError.http(error)
                    }
                }
                
                throw HumeError.http(error)
            }
        }
    }
    
    private func parseError(
        from data: Data,
        statusCode: Int,
        response: HTTPURLResponse
    ) throws -> HumeError {
        // Try to parse error response
        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            if let errors = errorResponse.errors, !errors.isEmpty {
                return .validation(errors: errors)
            }
            
            let message = errorResponse.message ?? errorResponse.detail ?? "HTTP \(statusCode) error"
            
            if statusCode == 429 {
                let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(RetryAfterParser.parse)
                return .rateLimit(retryAfter: retryAfter)
            }
            
            return .api(
                status: statusCode,
                message: message,
                code: errorResponse.code,
                body: String(data: data, encoding: .utf8)
            )
        }
        
        // Fallback to generic error
        let message = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        return .api(
            status: statusCode,
            message: message,
            code: nil,
            body: String(data: data, encoding: .utf8)
        )
    }
}

// Helper struct for wrapping raw Data
private struct DataWrapper: Encodable {
    let data: Data
    
    func encode(to encoder: Encoder) throws {
        // This won't actually be called since we handle Data specially
        throw HumeError.encodingFailed(NSError(domain: "DataWrapper", code: 0))
    }
}
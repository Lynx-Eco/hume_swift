import Foundation

/// Client for Text-to-Speech API
public class TTSClient {
    private let client: HumeClient
    
    public init(client: HumeClient) {
        self.client = client
    }
    
    // MARK: - Synthesis Methods
    
    /// Synthesize speech from text (JSON response)
    public func synthesize(
        _ request: TTSRequest,
        options: RequestOptions? = nil
    ) async throws -> TTSResponse {
        return try await client.http.post(
            "/v0/tts",
            body: request,
            responseType: TTSResponse.self,
            options: options
        )
    }
    
    /// Synthesize speech from text (raw audio data)
    public func synthesizeAudio(
        _ request: TTSRequest,
        options: RequestOptions? = nil
    ) async throws -> Data {
        var modifiedOptions = options ?? RequestOptions()
        var headers = modifiedOptions.headers ?? [:]
        headers["Accept"] = "audio/*"
        modifiedOptions.headers = headers
        
        return try await client.http.postData(
            "/v0/tts",
            body: request,
            options: modifiedOptions
        )
    }
    
    /// Simple synthesis with just text
    public func synthesize(
        text: String,
        voice: VoiceSpecification? = nil,
        options: RequestOptions? = nil
    ) async throws -> TTSResponse {
        let request = try TTSRequest(text: text, voice: voice)
        return try await synthesize(request, options: options)
    }
    
    /// Simple synthesis returning audio data
    public func synthesizeAudio(
        text: String,
        voice: VoiceSpecification? = nil,
        format: AudioFormatDetails = .mp3,
        options: RequestOptions? = nil
    ) async throws -> Data {
        let request = try TTSRequest(
            text: text,
            voice: voice
        )
        return try await synthesizeAudio(request, options: options)
    }
    
    // MARK: - Streaming Methods
    
    /// Stream synthesis response (JSON chunks)
    public func streamSynthesis(
        _ request: TTSRequest,
        options: RequestOptions? = nil
    ) -> AsyncThrowingStream<TTSStreamChunk, Error> {
        return AsyncThrowingStream<TTSStreamChunk, Error> { continuation in
            Task {
                do {
                    var modifiedOptions = options ?? RequestOptions()
                    var headers = modifiedOptions.headers ?? [:]
                    headers["Accept"] = "text/event-stream"
                    modifiedOptions.headers = headers
                    
                    let url = try client.buildURL(path: "/v0/tts/stream")
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.httpBody = try JSONEncoder().encode(request)
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add auth header
                    let auth = try await client.getAuthProvider().getAuthentication()
                    urlRequest.setValue(auth.headerValue, forHTTPHeaderField: auth.headerField)
                    
                    // Add custom headers
                    for (key, value) in headers {
                        urlRequest.setValue(value, forHTTPHeaderField: key)
                    }
                    
                    // Create SSE stream
                    let session = URLSession.shared
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw HumeError.invalidResponse(message: "Invalid HTTP response")
                    }
                    
                    // Parse SSE events
                    let parser = ServerSentEventsParser()
                    
                    for try await chunk in bytes {
                        let events = await parser.parse(Data([chunk]))
                        for event in events {
                            if let data = event.data.data(using: .utf8),
                               let streamChunk = try? JSONDecoder().decode(TTSStreamChunk.self, from: data) {
                                continuation.yield(streamChunk)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Stream audio synthesis (raw audio chunks)
    public func streamAudio(
        _ request: TTSRequest,
        options: RequestOptions? = nil
    ) -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream<Data, Error> { continuation in
            Task {
                do {
                    var modifiedOptions = options ?? RequestOptions()
                    var headers = modifiedOptions.headers ?? [:]
                    headers["Accept"] = "audio/*"
                    modifiedOptions.headers = headers
                    
                    let url = try client.buildURL(path: "/v0/tts/stream_audio")
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.httpBody = try JSONEncoder().encode(request)
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Add auth header
                    let auth = try await client.getAuthProvider().getAuthentication()
                    urlRequest.setValue(auth.headerValue, forHTTPHeaderField: auth.headerField)
                    
                    // Add custom headers
                    for (key, value) in headers {
                        urlRequest.setValue(value, forHTTPHeaderField: key)
                    }
                    
                    // Stream audio data
                    let session = URLSession.shared
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw HumeError.invalidResponse(message: "Invalid HTTP response")
                    }
                    
                    // Collect chunks and yield them
                    var buffer = Data()
                    let chunkSize = 4096 // 4KB chunks
                    
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        if buffer.count >= chunkSize {
                            continuation.yield(buffer)
                            buffer = Data()
                        }
                    }
                    
                    // Yield any remaining data
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Voice Management
    
    /// List available voices
    public func listVoices(
        provider: VoiceProvider? = nil,
        pageSize: Int? = nil,
        pageNumber: Int? = nil,
        options: RequestOptions? = nil
    ) async throws -> VoicesResponse {
        var queryParams: [String: String] = [:]
        
        if let provider = provider {
            queryParams["provider"] = provider.rawValue
        }
        if let pageSize = pageSize {
            queryParams["page_size"] = String(pageSize)
        }
        if let pageNumber = pageNumber {
            queryParams["page_number"] = String(pageNumber)
        }
        
        let modifiedOptions = RequestOptions(
            queryParameters: queryParams
        ).merged(with: options)
        
        return try await client.http.get(
            "/v0/tts/voices",
            responseType: VoicesResponse.self,
            options: modifiedOptions
        )
    }
    
    /// Get voices as paginated sequence
    public func voices(
        provider: VoiceProvider? = nil,
        pageSize: Int = 100
    ) -> PaginatedSequence<Voice> {
        return PaginatedSequence(pageSize: pageSize) { page in
            let response = try await self.listVoicesPagedInternal(
                provider: provider,
                pageSize: pageSize,
                pageNumber: page
            )
            
            return PagedResponse(
                pageNumber: response.pageNumber ?? 0,
                pageSize: response.pageSize ?? pageSize,
                totalPages: response.totalPages ?? 1,
                totalItems: response.voicesPage.count,
                items: response.voicesPage
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func listVoicesPagedInternal(
        provider: VoiceProvider? = nil,
        pageSize: Int,
        pageNumber: Int
    ) async throws -> PagedVoicesResponse {
        var queryParams: [String: String] = [
            "page_size": String(pageSize),
            "page_number": String(pageNumber)
        ]
        
        if let provider = provider {
            queryParams["provider"] = provider.rawValue
        }
        
        let options = RequestOptions(queryParameters: queryParams)
        
        return try await client.http.get(
            "/v0/tts/voices",
            responseType: PagedVoicesResponse.self,
            options: options
        )
    }
}

// MARK: - Convenience Extensions

public extension TTSClient {
    /// Create from HumeClient
    convenience init(apiKey: String) throws {
        let client = try HumeClient(apiKey: apiKey)
        self.init(client: client)
    }
}

// MARK: - Builder Extensions

public extension TTSClient {
    /// Create a request builder
    func request(text: String) -> TTSRequestBuilder {
        return TTSRequestBuilder(text: text)
    }
}


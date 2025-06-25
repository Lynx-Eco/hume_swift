import Foundation

/// Server-Sent Events (SSE) parser for streaming responses
public actor ServerSentEventsParser {
    private var buffer = ""
    private var eventType: String?
    private var eventData = ""
    private var eventId: String?
    private var retryTime: Int?
    
    /// Event received from SSE stream
    public struct Event: Sendable {
        public let type: String?
        public let data: String
        public let id: String?
        public let retry: Int?
    }
    
    /// Parse incoming data chunk
    public func parse(_ data: Data) async -> [Event] {
        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }
        
        buffer += text
        var events: [Event] = []
        
        // Process complete lines
        while let lineRange = buffer.range(of: "\n") {
            let line = String(buffer[..<lineRange.lowerBound])
            buffer.removeSubrange(..<lineRange.upperBound)
            
            // Process the line
            if let event = await processLine(line) {
                events.append(event)
            }
        }
        
        return events
    }
    
    /// Process a single line
    private func processLine(_ line: String) async -> Event? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty line signals end of event
        if trimmedLine.isEmpty {
            if !eventData.isEmpty {
                let event = Event(
                    type: eventType,
                    data: eventData.trimmingCharacters(in: .whitespacesAndNewlines),
                    id: eventId,
                    retry: retryTime
                )
                
                // Reset for next event
                eventType = nil
                eventData = ""
                eventId = nil
                retryTime = nil
                
                return event
            }
            return nil
        }
        
        // Skip comments
        if trimmedLine.hasPrefix(":") {
            return nil
        }
        
        // Parse field
        if let colonIndex = trimmedLine.firstIndex(of: ":") {
            let field = String(trimmedLine[..<colonIndex])
            var value = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
            
            // Remove leading space if present
            if value.hasPrefix(" ") {
                value.removeFirst()
            }
            
            switch field {
            case "event":
                eventType = value
            case "data":
                if !eventData.isEmpty {
                    eventData += "\n"
                }
                eventData += value
            case "id":
                eventId = value
            case "retry":
                retryTime = Int(value)
            default:
                // Ignore unknown fields
                break
            }
        }
        
        return nil
    }
    
    /// Reset the parser state
    public func reset() {
        buffer = ""
        eventType = nil
        eventData = ""
        eventId = nil
        retryTime = nil
    }
}

/// Async sequence for SSE events
public struct ServerSentEventsSequence: AsyncSequence {
    public typealias Element = ServerSentEventsParser.Event
    
    private let dataStream: AsyncThrowingStream<Data, Error>
    
    public init(dataStream: AsyncThrowingStream<Data, Error>) {
        self.dataStream = dataStream
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(dataStream: dataStream)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var dataIterator: AsyncThrowingStream<Data, Error>.AsyncIterator
        private let parser = ServerSentEventsParser()
        private var eventBuffer: [ServerSentEventsParser.Event] = []
        
        init(dataStream: AsyncThrowingStream<Data, Error>) {
            self.dataIterator = dataStream.makeAsyncIterator()
        }
        
        public mutating func next() async throws -> ServerSentEventsParser.Event? {
            // Return buffered events first
            if !eventBuffer.isEmpty {
                return eventBuffer.removeFirst()
            }
            
            // Process more data
            while let data = try await dataIterator.next() {
                let events = await parser.parse(data)
                if !events.isEmpty {
                    eventBuffer = events
                    return eventBuffer.removeFirst()
                }
            }
            
            return nil
        }
    }
}

/// Extension to URLSession for SSE support
extension URLSession {
    /// Create an async stream of server-sent events
    public func serverSentEventsStream(
        for request: URLRequest
    ) -> AsyncThrowingStream<ServerSentEventsParser.Event, Error> {
        AsyncThrowingStream { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    continuation.finish(throwing: HumeError.invalidResponse(message: "Invalid HTTP response"))
                    return
                }
            }
            
            // Set up streaming delegate
            let delegate = SSETaskDelegate(continuation: continuation)
            task.delegate = delegate
            
            task.resume()
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

/// Delegate for handling streaming data
private class SSETaskDelegate: NSObject, URLSessionDataDelegate {
    private let continuation: AsyncThrowingStream<ServerSentEventsParser.Event, Error>.Continuation
    private let parser = ServerSentEventsParser()
    
    init(continuation: AsyncThrowingStream<ServerSentEventsParser.Event, Error>.Continuation) {
        self.continuation = continuation
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Task {
            let events = await parser.parse(data)
            for event in events {
                continuation.yield(event)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation.finish(throwing: error)
        } else {
            continuation.finish()
        }
    }
}
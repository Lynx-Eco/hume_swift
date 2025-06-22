import Foundation

// MARK: - Chat Messages

/// Base chat message protocol
public protocol ChatMessage: Codable, Sendable {}

/// Type-erased chat message for WebSocket
public struct AnyChatMessage: Codable, Sendable {
    private let _encode: (Encoder) throws -> Void
    
    public init<T: ChatMessage>(_ message: T) {
        self._encode = { encoder in
            try message.encode(to: encoder)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
    
    public init(from decoder: Decoder) throws {
        // Not used for sending, only encoding
        fatalError("Decoding AnyChatMessage is not supported")
    }
}

/// User message for chat
public struct UserMessage: ChatMessage {
    public let type: String
    public let text: String
    
    public init(text: String) {
        self.type = "user_message"
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

/// Assistant message from chat
public struct AssistantMessage: ChatMessage {
    public let type: String = "assistant_message"
    public let messageId: String?
    public let text: String
    public let isFinal: Bool
    
    public init(messageId: String? = nil, text: String, isFinal: Bool = false) {
        self.messageId = messageId
        self.text = text
        self.isFinal = isFinal
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case messageId = "message_id"
        case text
        case isFinal = "is_final"
    }
}

/// Audio input for chat
public struct AudioInput: ChatMessage {
    public let type: String
    public let data: String // Base64 encoded audio
    
    public init(data: Data) {
        self.type = "audio_input"
        self.data = data.base64EncodedString()
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

/// Session settings for chat
public struct SessionSettings: ChatMessage, Sendable {
    public let type: String
    public let systemPrompt: String?
    public let temperature: Double?
    public let maxTokens: Int?
    public let audioEncoding: EVIAudioEncoding?
    public let sampleRate: Int?
    public let channelCount: Int?
    public let language: Language?
    
    public init(
        systemPrompt: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        audioEncoding: EVIAudioEncoding? = nil,
        sampleRate: Int? = nil,
        channelCount: Int? = nil,
        language: Language? = nil
    ) {
        self.type = "session_settings"
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.audioEncoding = audioEncoding
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.language = language
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case systemPrompt = "system_prompt"
        case temperature
        case maxTokens = "max_tokens"
        case audioEncoding = "audio_encoding"
        case sampleRate = "sample_rate"
        case channelCount = "channel_count"
        case language
    }
}

// MARK: - Server Messages

/// Server message types
public enum ServerMessageType: String, Codable, Sendable {
    case userMessage = "user_message"
    case assistantMessage = "assistant_message"
    case audioOutput = "audio_output"
    case userInterruption = "user_interruption"
    case error = "error"
}

/// Base server message
public enum ServerMessage: Codable, Sendable {
    case userMessage(UserMessageResponse)
    case assistantMessage(AssistantMessageResponse)
    case audioOutput(AudioOutputResponse)
    case userInterruption(UserInterruptionResponse)
    case error(ErrorResponse)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "user_message":
            self = .userMessage(try UserMessageResponse(from: decoder))
        case "assistant_message":
            self = .assistantMessage(try AssistantMessageResponse(from: decoder))
        case "audio_output":
            self = .audioOutput(try AudioOutputResponse(from: decoder))
        case "user_interruption":
            self = .userInterruption(try UserInterruptionResponse(from: decoder))
        case "error":
            self = .error(try ErrorResponse(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message type: \(type)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .userMessage(let msg):
            try msg.encode(to: encoder)
        case .assistantMessage(let msg):
            try msg.encode(to: encoder)
        case .audioOutput(let msg):
            try msg.encode(to: encoder)
        case .userInterruption(let msg):
            try msg.encode(to: encoder)
        case .error(let msg):
            try msg.encode(to: encoder)
        }
    }
}

/// User message response
public struct UserMessageResponse: Codable, Sendable {
    public let type: String
    public let text: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

/// Assistant message response
public struct AssistantMessageResponse: Codable, Sendable {
    public let type: String
    public let messageId: String?
    public let text: String
    public let isFinal: Bool
    
    enum CodingKeys: String, CodingKey {
        case type
        case messageId = "message_id"
        case text
        case isFinal = "is_final"
    }
}

/// Audio output response
public struct AudioOutputResponse: Codable, Sendable {
    public let type: String
    public let messageId: String?
    public let data: String // Base64 encoded audio
    public let isFinal: Bool
    
    enum CodingKeys: String, CodingKey {
        case type
        case messageId = "message_id"
        case data
        case isFinal = "is_final"
    }
}

/// User interruption response
public struct UserInterruptionResponse: Codable, Sendable {
    public let type: String
    
    enum CodingKeys: String, CodingKey {
        case type
    }
}

/// Error response
public struct ErrorResponse: Codable, Sendable {
    public let type: String
    public let message: String
    public let code: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case message
        case code
    }
}

// MARK: - Configurations

/// EVI configuration
public struct EVIConfig: Codable, Sendable {
    public let id: String
    public let version: Int
    public let name: String
    public let prompt: String?
    public let language: Language?
    public let voiceId: String?
    public let voiceName: String?
    public let createdOn: Date?
    public let modifiedOn: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case version
        case name
        case prompt
        case language
        case voiceId = "voice_id"
        case voiceName = "voice_name"
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
}

/// Configuration creation request
public struct CreateConfigRequest: Codable, Sendable {
    public let name: String
    public let prompt: String?
    public let language: Language?
    public let voiceId: String?
    
    public init(
        name: String,
        prompt: String? = nil,
        language: Language? = nil,
        voiceId: String? = nil
    ) {
        self.name = name
        self.prompt = prompt
        self.language = language
        self.voiceId = voiceId
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case prompt
        case language
        case voiceId = "voice_id"
    }
}

/// Configuration update request
public struct UpdateConfigRequest: Codable, Sendable {
    public let name: String?
    public let prompt: String?
    public let language: Language?
    public let voiceId: String?
    
    public init(
        name: String? = nil,
        prompt: String? = nil,
        language: Language? = nil,
        voiceId: String? = nil
    ) {
        self.name = name
        self.prompt = prompt
        self.language = language
        self.voiceId = voiceId
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case prompt
        case language
        case voiceId = "voice_id"
    }
}

/// Configurations response with built-in configs
public struct ConfigurationsResponseBuiltIn: Codable, Sendable {
    public let configsPage: [EVIConfig]
    
    enum CodingKeys: String, CodingKey {
        case configsPage = "configs_page"
    }
}

/// Configurations response for custom configs
public struct ConfigurationsResponse: Codable, Sendable {
    public let totalItems: Int
    public let totalPages: Int
    public let pageNumber: Int
    public let pageSize: Int
    public let configsPage: [EVIConfig]
    
    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case totalPages = "total_pages"
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case configsPage = "configs_page"
    }
}

// MARK: - Tools

/// EVI tool
public struct EVITool: Codable, Sendable {
    public let id: String
    public let version: Int
    public let name: String
    public let description: String?
    public let parameters: String
    public let fallbackContent: String?
    public let createdOn: Date?
    public let modifiedOn: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case version
        case name
        case description
        case parameters
        case fallbackContent = "fallback_content"
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
}

/// Tool creation request
public struct CreateToolRequest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let parameters: String
    public let fallbackContent: String?
    
    public init(
        name: String,
        description: String? = nil,
        parameters: String,
        fallbackContent: String? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.fallbackContent = fallbackContent
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case parameters
        case fallbackContent = "fallback_content"
    }
}

/// Tool update request
public struct UpdateToolRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let parameters: String?
    public let fallbackContent: String?
    
    public init(
        name: String? = nil,
        description: String? = nil,
        parameters: String? = nil,
        fallbackContent: String? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.fallbackContent = fallbackContent
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case parameters
        case fallbackContent = "fallback_content"
    }
}

/// Tools response
public struct ToolsResponse: Codable, Sendable {
    public let totalItems: Int
    public let totalPages: Int
    public let pageNumber: Int
    public let pageSize: Int
    public let toolsPage: [EVITool]
    
    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case totalPages = "total_pages"
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case toolsPage = "tools_page"
    }
}

// MARK: - Enums

/// Audio encoding types for EVI
public enum EVIAudioEncoding: String, Codable, Sendable {
    case pcmLinear16 = "pcm_linear16"
    case mulaw = "mulaw"
}

/// Supported languages
public enum Language: String, Codable, Sendable {
    case en = "en"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case it = "it"
    case pt = "pt"
    case ja = "ja"
    case ko = "ko"
    case zh = "zh"
    case nl = "nl"
    case pl = "pl"
    case ru = "ru"
    case sv = "sv"
    case tr = "tr"
}
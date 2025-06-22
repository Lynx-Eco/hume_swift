import Foundation

// MARK: - Audio Formats

/// Audio encoding format
public enum AudioFormat: String, Codable, Sendable {
    case mp3 = "mp3"
    case wav = "wav"
    case pcm = "pcm"
}

/// Audio format details
public enum AudioFormatDetails: Codable, Sendable {
    case mp3
    case wav
    case pcm
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    private enum FormatType: String, Codable {
        case mp3 = "mp3"
        case wav = "wav"
        case pcm = "pcm"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .mp3:
            try container.encode(FormatType.mp3.rawValue, forKey: .type)
            
        case .wav:
            try container.encode(FormatType.wav.rawValue, forKey: .type)
            
        case .pcm:
            try container.encode(FormatType.pcm.rawValue, forKey: .type)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decode(FormatType.self, forKey: .type)
        
        switch format {
        case .mp3:
            self = .mp3
            
        case .wav:
            self = .wav
            
        case .pcm:
            self = .pcm
        }
    }
}

/// PCM encoding format
public enum PCMEncoding: String, Codable, Sendable {
    case int16 = "int16"
    case float32 = "float32"
}

// MARK: - Sample Rate

/// Audio sample rate with common presets
public struct SampleRate: Codable, Equatable, Sendable {
    public let value: Int
    
    public init(_ value: Int) {
        self.value = value
    }
    
    // Common sample rates
    public static let hz8000 = SampleRate(8000)
    public static let hz16000 = SampleRate(16000)
    public static let hz22050 = SampleRate(22050)
    public static let hz24000 = SampleRate(24000)
    public static let hz44100 = SampleRate(44100)
    public static let hz48000 = SampleRate(48000)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Int.self)
    }
}

// MARK: - Voice Models

/// Voice provider
public enum VoiceProvider: String, Codable, Sendable {
    case humeAI = "HUME_AI"
    case customVoice = "CUSTOM_VOICE"
    case hume = "HUME" // Legacy
    case eleven = "ELEVEN" // Legacy
    case playht = "PLAYHT" // Legacy
}

/// Voice information
public struct Voice: Codable, Sendable {
    public let id: String
    public let name: String
    public let provider: VoiceProvider?
    public let description: String?
    public let gender: String?
    public let age: String?
    public let language: String?
    public let previewUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case provider
        case description
        case gender
        case age
        case language
        case previewUrl = "preview_url"
    }
}

/// Voice specification for requests
public enum VoiceSpecification: Codable, Sendable {
    case id(String)
    case name(String)
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .id(let id):
            try container.encode(id, forKey: .id)
        case .name(let name):
            try container.encode(name, forKey: .name)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self = .id(id)
        } else if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self = .name(name)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Must provide either id or name"
                )
            )
        }
    }
}

// MARK: - TTS Requests

/// Posted utterance for TTS
public struct PostedUtterance: Codable, Sendable {
    public let text: String
    public let voice: VoiceSpecification?
    public let description: String?
    public let speed: Double?
    public let trailingSilence: Double?
    
    private enum CodingKeys: String, CodingKey {
        case text
        case voice
        case description
        case speed
        case trailingSilence = "trailing_silence"
    }
    
    public init(
        text: String,
        voice: VoiceSpecification? = nil,
        description: String? = nil,
        speed: Double? = nil,
        trailingSilence: Double? = nil
    ) {
        self.text = text
        self.voice = voice
        self.description = description
        self.speed = speed
        self.trailingSilence = trailingSilence
    }
}

/// TTS synthesis request
public struct TTSRequest: Codable, Sendable {
    public let utterances: [PostedUtterance]
    public let format: AudioFormatDetails?
    public let numGenerations: Int?
    public let splitUtterances: Bool?
    public let stripHeaders: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case utterances
        case format
        case numGenerations = "num_generations"
        case splitUtterances = "split_utterances"
        case stripHeaders = "strip_headers"
    }
    
    public init(
        utterances: [PostedUtterance],
        format: AudioFormatDetails? = nil,
        numGenerations: Int? = nil,
        splitUtterances: Bool? = nil,
        stripHeaders: Bool? = nil
    ) {
        self.utterances = utterances
        self.format = format
        self.numGenerations = numGenerations
        self.splitUtterances = splitUtterances
        self.stripHeaders = stripHeaders
    }
    
    // Convenience init for single utterance
    public init(
        text: String,
        voice: VoiceSpecification? = nil,
        description: String? = nil,
        speed: Double? = nil
    ) {
        let utterance = PostedUtterance(
            text: text,
            voice: voice,
            description: description,
            speed: speed
        )
        self.utterances = [utterance]
        self.format = nil
        self.numGenerations = nil
        self.splitUtterances = nil
        self.stripHeaders = nil
    }
}

/// Builder for TTS requests
public class TTSRequestBuilder {
    private var text: String
    private var voice: VoiceSpecification?
    private var descriptionText: String?
    private var speed: Double?
    private var trailingSilenceValue: Double?
    private var format: AudioFormatDetails?
    private var numGenerations: Int?
    private var splitUtterances: Bool?
    private var stripHeaders: Bool?
    
    public init(text: String) {
        self.text = text
    }
    
    @discardableResult
    public func voice(_ voice: VoiceSpecification) -> TTSRequestBuilder {
        self.voice = voice
        return self
    }
    
    @discardableResult
    public func voiceId(_ id: String) -> TTSRequestBuilder {
        self.voice = .id(id)
        return self
    }
    
    @discardableResult
    public func voiceName(_ name: String) -> TTSRequestBuilder {
        self.voice = .name(name)
        return self
    }
    
    @discardableResult
    public func outputFormat(_ format: AudioFormatDetails) -> TTSRequestBuilder {
        self.format = format
        return self
    }
    
    @discardableResult
    public func sampleRate(_ rate: SampleRate) -> TTSRequestBuilder {
        // Note: Sample rate is handled by the API based on format type
        // This is kept for API compatibility but doesn't affect the request
        return self
    }
    
    @discardableResult
    public func sampleRate(_ rate: Int) -> TTSRequestBuilder {
        return sampleRate(SampleRate(rate))
    }
    
    @discardableResult
    public func speed(_ speed: Double) -> TTSRequestBuilder {
        self.speed = speed
        return self
    }
    
    @discardableResult
    public func volume(_ volume: Double) -> TTSRequestBuilder {
        // Volume is not directly supported in the API
        return self
    }
    
    @discardableResult
    public func description(_ description: String) -> TTSRequestBuilder {
        self.descriptionText = description
        return self
    }
    
    @discardableResult
    public func trailingSilence(_ silence: Double) -> TTSRequestBuilder {
        self.trailingSilenceValue = silence
        return self
    }
    
    public func build() -> TTSRequest {
        let utterance = PostedUtterance(
            text: text,
            voice: voice,
            description: descriptionText,
            speed: speed,
            trailingSilence: trailingSilenceValue
        )
        
        return TTSRequest(
            utterances: [utterance],
            format: format,
            numGenerations: nil,
            splitUtterances: nil,
            stripHeaders: nil
        )
    }
}

// MARK: - TTS Responses

/// Snippet in TTS response
public struct Snippet: Codable, Sendable {
    public let text: String
    public let startTime: Double?
    public let endTime: Double?
    
    private enum CodingKeys: String, CodingKey {
        case text
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

/// Generation in TTS response
public struct Generation: Codable, Sendable {
    public let audio: String // Base64 encoded audio
    public let duration: Double
    public let encoding: AudioEncoding
    public let fileSize: Int
    public let generationId: String
    public let snippets: [[Snippet]]
    
    private enum CodingKeys: String, CodingKey {
        case audio
        case duration
        case encoding
        case fileSize = "file_size"
        case generationId = "generation_id"
        case snippets
    }
}

/// Audio encoding in response
public struct AudioEncoding: Codable, Sendable {
    public let format: String
    public let sampleRate: Int?
    public let encoding: String?
    
    private enum CodingKeys: String, CodingKey {
        case format
        case sampleRate = "sample_rate"
        case encoding
    }
}

/// TTS synthesis response
public struct TTSResponse: Codable, Sendable {
    public let generations: [Generation]
    public let requestId: String?
    
    private enum CodingKeys: String, CodingKey {
        case generations
        case requestId = "request_id"
    }
    
    // Convenience accessors for first generation
    public var audioUrl: String? {
        return nil // JSON response doesn't have URL
    }
    
    public var duration: Double? {
        return generations.first?.duration
    }
    
    public var audioBase64: String? {
        return generations.first?.audio
    }
}

/// Voices list response
public struct VoicesResponse: Codable, Sendable {
    public let pageNumber: Int?
    public let pageSize: Int?
    public let totalPages: Int?
    public let voicesPage: [Voice]
    
    private enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case voicesPage = "voices_page"
    }
    
    // Convenience accessor
    public var voices: [Voice] {
        return voicesPage
    }
}

/// Paged voices response (alias for internal use)
public typealias PagedVoicesResponse = VoicesResponse
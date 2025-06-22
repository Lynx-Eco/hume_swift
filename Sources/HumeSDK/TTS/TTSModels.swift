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
    case wav(sampleRate: Int)
    case pcm(encoding: PCMEncoding, sampleRate: Int)
    
    private enum CodingKeys: String, CodingKey {
        case format
        case sampleRate = "sample_rate"
        case encoding
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
            try container.encode(FormatType.mp3, forKey: .format)
            
        case .wav(let sampleRate):
            try container.encode(FormatType.wav, forKey: .format)
            try container.encode(sampleRate, forKey: .sampleRate)
            
        case .pcm(let encoding, let sampleRate):
            try container.encode(FormatType.pcm, forKey: .format)
            try container.encode(encoding, forKey: .encoding)
            try container.encode(sampleRate, forKey: .sampleRate)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decode(FormatType.self, forKey: .format)
        
        switch format {
        case .mp3:
            self = .mp3
            
        case .wav:
            let sampleRate = try container.decode(Int.self, forKey: .sampleRate)
            self = .wav(sampleRate: sampleRate)
            
        case .pcm:
            let encoding = try container.decode(PCMEncoding.self, forKey: .encoding)
            let sampleRate = try container.decode(Int.self, forKey: .sampleRate)
            self = .pcm(encoding: encoding, sampleRate: sampleRate)
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
    case hume = "HUME"
    case eleven = "ELEVEN"
    case playht = "PLAYHT"
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

/// TTS synthesis request
public struct TTSRequest: Codable, Sendable {
    public let text: String
    public let voice: VoiceSpecification?
    public let outputFormat: AudioFormatDetails?
    public let sampleRate: SampleRate?
    public let speed: Double?
    public let volume: Double?
    
    private enum CodingKeys: String, CodingKey {
        case text
        case voice
        case outputFormat = "output_format"
        case sampleRate = "sample_rate"
        case speed
        case volume
    }
    
    public init(
        text: String,
        voice: VoiceSpecification? = nil,
        outputFormat: AudioFormatDetails? = nil,
        sampleRate: SampleRate? = nil,
        speed: Double? = nil,
        volume: Double? = nil
    ) {
        self.text = text
        self.voice = voice
        self.outputFormat = outputFormat
        self.sampleRate = sampleRate
        self.speed = speed
        self.volume = volume
    }
}

/// Builder for TTS requests
public class TTSRequestBuilder {
    private var text: String
    private var voice: VoiceSpecification?
    private var outputFormat: AudioFormatDetails?
    private var sampleRate: SampleRate?
    private var speed: Double?
    private var volume: Double?
    
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
        self.outputFormat = format
        return self
    }
    
    @discardableResult
    public func sampleRate(_ rate: SampleRate) -> TTSRequestBuilder {
        self.sampleRate = rate
        return self
    }
    
    @discardableResult
    public func sampleRate(_ rate: Int) -> TTSRequestBuilder {
        self.sampleRate = SampleRate(rate)
        return self
    }
    
    @discardableResult
    public func speed(_ speed: Double) -> TTSRequestBuilder {
        self.speed = speed
        return self
    }
    
    @discardableResult
    public func volume(_ volume: Double) -> TTSRequestBuilder {
        self.volume = volume
        return self
    }
    
    public func build() -> TTSRequest {
        return TTSRequest(
            text: text,
            voice: voice,
            outputFormat: outputFormat,
            sampleRate: sampleRate,
            speed: speed,
            volume: volume
        )
    }
}

// MARK: - TTS Responses

/// TTS synthesis response
public struct TTSResponse: Codable, Sendable {
    public let audioUrl: String?
    public let duration: Double?
    
    private enum CodingKeys: String, CodingKey {
        case audioUrl = "audio_url"
        case duration
    }
}

/// Voices list response
public struct VoicesResponse: Codable, Sendable {
    public let voices: [Voice]
}

/// Paged voices response
public struct PagedVoicesResponse: Codable, Sendable {
    public let pageNumber: Int
    public let pageSize: Int
    public let totalPages: Int
    public let totalItems: Int
    public let voices: [Voice]
    
    private enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case voices
    }
}
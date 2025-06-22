import Foundation

// MARK: - Batch Models

/// Batch job status
public enum BatchJobStatus: String, Codable, Sendable {
    case queued = "QUEUED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

/// Batch job
public struct BatchJob: Codable, Sendable {
    public let jobId: String
    public let status: BatchJobStatus
    public let createdTimestampMs: Int64
    public let startedTimestampMs: Int64?
    public let endedTimestampMs: Int64?
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case createdTimestampMs = "created_timestamp_ms"
        case startedTimestampMs = "started_timestamp_ms"
        case endedTimestampMs = "ended_timestamp_ms"
    }
}

/// Job creation response
public struct JobCreationResponse: Codable, Sendable {
    public let jobId: String
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
    }
}

/// Model configuration
public struct ModelConfiguration: Codable, Sendable {
    public let face: FaceConfiguration?
    public let prosody: ProsodyConfiguration?
    public let language: LanguageConfiguration?
    public let ner: NERConfiguration?
    
    public init(
        face: FaceConfiguration? = nil,
        prosody: ProsodyConfiguration? = nil,
        language: LanguageConfiguration? = nil,
        ner: NERConfiguration? = nil
    ) {
        self.face = face
        self.prosody = prosody
        self.language = language
        self.ner = ner
    }
}

/// Face configuration
public struct FaceConfiguration: Codable, Sendable {
    public let facs: EmotionConfiguration?
    public let descriptions: EmotionConfiguration?
    public let emotions: EmotionConfiguration?
    
    public init(
        facs: EmotionConfiguration? = nil,
        descriptions: EmotionConfiguration? = nil,
        emotions: EmotionConfiguration? = nil
    ) {
        self.facs = facs
        self.descriptions = descriptions
        self.emotions = emotions
    }
}

/// Prosody configuration
public struct ProsodyConfiguration: Codable, Sendable {
    public let granularity: Granularity?
    public let emotions: EmotionConfiguration?
    
    public init(
        granularity: Granularity? = nil,
        emotions: EmotionConfiguration? = nil
    ) {
        self.granularity = granularity
        self.emotions = emotions
    }
}

/// Language configuration
public struct LanguageConfiguration: Codable, Sendable {
    public let granularity: Granularity?
    public let emotions: EmotionConfiguration?
    
    public init(
        granularity: Granularity? = nil,
        emotions: EmotionConfiguration? = nil
    ) {
        self.granularity = granularity
        self.emotions = emotions
    }
}

/// NER configuration
public struct NERConfiguration: Codable, Sendable {
    public let identifyEmotions: Bool?
    
    public init(identifyEmotions: Bool? = nil) {
        self.identifyEmotions = identifyEmotions
    }
    
    enum CodingKeys: String, CodingKey {
        case identifyEmotions = "identify_emotions"
    }
}

/// Emotion configuration
public struct EmotionConfiguration: Codable, Sendable {
    // Empty for now, can be extended
    public init() {}
}

/// Granularity for analysis
public enum Granularity: String, Codable, Sendable {
    case word = "word"
    case sentence = "sentence"
    case utterance = "utterance"
    case passage = "passage"
    case conversational = "conversational"
}

/// Job request
public struct BatchJobRequest: Codable, Sendable {
    public let models: ModelConfiguration
    public let urls: [String]?
    public let files: [String]?
    public let text: [String]?
    public let callbackUrl: String?
    public let notify: Bool?
    
    public init(
        models: ModelConfiguration,
        urls: [String]? = nil,
        files: [String]? = nil,
        text: [String]? = nil,
        callbackUrl: String? = nil,
        notify: Bool? = nil
    ) {
        self.models = models
        self.urls = urls
        self.files = files
        self.text = text
        self.callbackUrl = callbackUrl
        self.notify = notify
    }
    
    enum CodingKeys: String, CodingKey {
        case models
        case urls
        case files
        case text
        case callbackUrl = "callback_url"
        case notify
    }
}

/// Predictions response
public struct PredictionsResponse: Codable, Sendable {
    public let predictions: [Prediction]
    public let errors: [PredictionError]
    
    public init(predictions: [Prediction] = [], errors: [PredictionError] = []) {
        self.predictions = predictions
        self.errors = errors
    }
}

/// Single prediction
public struct Prediction: Codable, Sendable {
    public let file: String
    public let models: PredictionModels
}

/// Prediction models
public struct PredictionModels: Codable, Sendable {
    public let face: FacePrediction?
    public let prosody: ProsodyPrediction?
    public let language: LanguagePrediction?
    public let ner: NERPrediction?
}

/// Face prediction
public struct FacePrediction: Codable, Sendable {
    public let groupedPredictions: [GroupedPrediction]
    
    enum CodingKeys: String, CodingKey {
        case groupedPredictions = "grouped_predictions"
    }
}

/// Prosody prediction
public struct ProsodyPrediction: Codable, Sendable {
    public let groupedPredictions: [GroupedPrediction]
    
    enum CodingKeys: String, CodingKey {
        case groupedPredictions = "grouped_predictions"
    }
}

/// Language prediction
public struct LanguagePrediction: Codable, Sendable {
    public let groupedPredictions: [GroupedPrediction]
    
    enum CodingKeys: String, CodingKey {
        case groupedPredictions = "grouped_predictions"
    }
}

/// NER prediction
public struct NERPrediction: Codable, Sendable {
    public let groupedPredictions: [GroupedPrediction]
    
    enum CodingKeys: String, CodingKey {
        case groupedPredictions = "grouped_predictions"
    }
}

/// Grouped prediction
public struct GroupedPrediction: Codable, Sendable {
    public let id: String
    public let predictions: [EmotionScore]
}

/// Emotion score
public struct EmotionScore: Codable, Sendable {
    public let name: String
    public let score: Double
}

/// Prediction error
public struct PredictionError: Codable, Sendable {
    public let file: String
    public let message: String
}

// MARK: - Streaming Models

/// Stream task
public struct StreamExpressionTask: Codable, Sendable {
    public let models: ModelConfiguration
    
    public init(models: ModelConfiguration) {
        self.models = models
    }
}

/// Stream message types
public enum StreamMessageType: String, Codable, Sendable {
    case modelPredictions = "model_predictions"
    case error = "error"
    case jobDetails = "job_details"
}

/// Base stream message
public enum StreamMessage: Codable, Sendable {
    case modelPredictions(ModelPredictionsMessage)
    case error(StreamErrorMessage)
    case jobDetails(JobDetailsMessage)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "model_predictions":
            self = .modelPredictions(try ModelPredictionsMessage(from: decoder))
        case "error":
            self = .error(try StreamErrorMessage(from: decoder))
        case "job_details":
            self = .jobDetails(try JobDetailsMessage(from: decoder))
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
        case .modelPredictions(let msg):
            try msg.encode(to: encoder)
        case .error(let msg):
            try msg.encode(to: encoder)
        case .jobDetails(let msg):
            try msg.encode(to: encoder)
        }
    }
}

/// Model predictions message
public struct ModelPredictionsMessage: Codable, Sendable {
    public let type: String
    public let payloadId: String
    public let jobId: String
    public let timestamp: Int64
    public let models: PredictionModels
    
    enum CodingKeys: String, CodingKey {
        case type
        case payloadId = "payload_id"
        case jobId = "job_id"
        case timestamp
        case models
    }
}

/// Stream error message
public struct StreamErrorMessage: Codable, Sendable {
    public let type: String
    public let message: String
    public let code: String?
}

/// Job details message
public struct JobDetailsMessage: Codable, Sendable {
    public let type: String
    public let jobId: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case jobId = "job_id"
    }
}
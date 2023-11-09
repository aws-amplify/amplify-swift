//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AWSRekognition {}

extension AWSRekognition {
    struct HumanLoopQuotaExceededException: Error {}
    struct ResourceNotFoundException: Error {}
    struct ThrottlingException: Error {}
    struct InternalServerError: Error {}
    struct AccessDeniedException: Error {}
    struct ImageTooLargeException: Error {}
    struct InvalidImageFormatException: Error {}
    struct InvalidParameterException: Error {}
    struct InvalidS3ObjectException: Error {}
    struct ProvisionedThroughputExceededException: Error {}
}

struct DetectLabelsInput: Equatable, Encodable {
    var features: [RekognitionClientTypes.DetectLabelsFeatureName]?
    /// This member is required.
    var image: RekognitionClientTypes.Image
    var maxLabels: Int?
    var minConfidence: Float?
    var settings: RekognitionClientTypes.DetectLabelsSettings?

    enum CodingKeys: String, CodingKey {
        case features = "Features"
        case image = "Image"
        case maxLabels = "MaxLabels"
        case minConfidence = "MinConfidence"
        case settings = "Settings"
    }
}

struct DetectLabelsOutputResponse: Equatable, Decodable {
    var imageProperties: RekognitionClientTypes.DetectLabelsImageProperties?
    var labelModelVersion: String?
    var labels: [RekognitionClientTypes.Label]?
    var orientationCorrection: RekognitionClientTypes.OrientationCorrection?

    enum CodingKeys: String, CodingKey {
        case imageProperties = "ImageProperties"
        case labelModelVersion = "LabelModelVersion"
        case labels = "Labels"
        case orientationCorrection = "OrientationCorrection"
    }
}

struct DetectModerationLabelsInput: Equatable, Encodable {
    var humanLoopConfig: RekognitionClientTypes.HumanLoopConfig?
    /// This member is required.
    var image: RekognitionClientTypes.Image
    var minConfidence: Float?

    enum CodingKeys: String, CodingKey {
        case humanLoopConfig = "HumanLoopConfig"
        case image = "Image"
        case minConfidence = "MinConfidence"
    }
}

struct DetectModerationLabelsOutputResponse: Equatable, Decodable {
    var humanLoopActivationOutput: RekognitionClientTypes.HumanLoopActivationOutput?
    var moderationLabels: [RekognitionClientTypes.ModerationLabel]?
    var moderationModelVersion: String?

    enum CodingKeys: String, CodingKey {
        case humanLoopActivationOutput = "HumanLoopActivationOutput"
        case moderationLabels = "ModerationLabels"
        case moderationModelVersion = "ModerationModelVersion"
    }
}

struct DetectTextInput: Equatable, Encodable {
    var filters: RekognitionClientTypes.DetectTextFilters?
    /// This member is required.
    var image: RekognitionClientTypes.Image

    enum CodingKeys: String, CodingKey {
        case filters = "Filters"
        case image = "Image"
    }
}

struct DetectTextOutputResponse: Equatable, Decodable {
    var textDetections: [RekognitionClientTypes.TextDetection]?
    var textModelVersion: String?

    enum CodingKeys: String, CodingKey {
        case textDetections = "TextDetections"
        case textModelVersion = "TextModelVersion"
    }
}



struct DetectFacesInput: Equatable, Encodable {
    var attributes: [RekognitionClientTypes.Attribute]?
    /// This member is required.
    var image: RekognitionClientTypes.Image

    enum CodingKeys: String, CodingKey {
        case attributes = "Attributes"
        case image = "Image"
    }
}

struct DetectFacesOutputResponse: Equatable, Decodable {
    var faceDetails: [RekognitionClientTypes.FaceDetail]?
    var orientationCorrection: RekognitionClientTypes.OrientationCorrection?

    enum CodingKeys: String, CodingKey {
        case faceDetails = "FaceDetails"
        case orientationCorrection = "OrientationCorrection"
    }
}

struct SearchFacesByImageInput: Equatable, Encodable {
    /// This member is required.
    var collectionId: String
    var faceMatchThreshold: Float?
    /// This member is required.
    var image: RekognitionClientTypes.Image
    var maxFaces: Int?
    var qualityFilter: RekognitionClientTypes.QualityFilter?

    enum CodingKeys: String, CodingKey {
        case collectionId = "CollectionId"
        case faceMatchThreshold = "FaceMatchThreshold"
        case image = "Image"
        case maxFaces = "MaxFaces"
        case qualityFilter = "QualityFilter"
    }
}

struct SearchFacesByImageOutputResponse: Equatable, Decodable {
    var faceMatches: [RekognitionClientTypes.FaceMatch]?
    var faceModelVersion: String?
    var searchedFaceBoundingBox: RekognitionClientTypes.BoundingBox?
    var searchedFaceConfidence: Float?

    enum CodingKeys: String, CodingKey {
        case faceMatches = "FaceMatches"
        case faceModelVersion = "FaceModelVersion"
        case searchedFaceBoundingBox = "SearchedFaceBoundingBox"
        case searchedFaceConfidence = "SearchedFaceConfidence"
    }
}

struct RecognizeCelebritiesInput: Equatable, Encodable {
    /// This member is required.
    var image: RekognitionClientTypes.Image

    enum CodingKeys: String, CodingKey {
        case image = "Image"
    }
}

struct RecognizeCelebritiesOutputResponse: Equatable, Decodable {
    var celebrityFaces: [RekognitionClientTypes.Celebrity]?
    var orientationCorrection: RekognitionClientTypes.OrientationCorrection?
    var unrecognizedFaces: [RekognitionClientTypes.ComparedFace]?

    enum CodingKeys: String, CodingKey {
        case celebrityFaces = "CelebrityFaces"
        case orientationCorrection = "OrientationCorrection"
        case unrecognizedFaces = "UnrecognizedFaces"
    }
}


enum RekognitionClientTypes {}

extension RekognitionClientTypes {
    struct AgeRange: Equatable, Decodable {
        var high: Int?
        var low: Int?

        enum CodingKeys: String, CodingKey {
            case high = "High"
            case low = "Low"
        }
    }
}

extension RekognitionClientTypes {
    struct Beard: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    struct EyeDirection: Equatable, Decodable {
        var confidence: Float?
        var pitch: Float?
        var yaw: Float?

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case pitch = "Pitch"
            case yaw = "Yaw"
        }
    }
}

extension RekognitionClientTypes {
    struct Eyeglasses: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    struct EyeOpen: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    struct FaceOccluded: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    enum GenderType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case female
        case male
        case sdkUnknown(String)

        static var allCases: [GenderType] {
            return [
                .female,
                .male,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .female: return "Female"
            case .male: return "Male"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = GenderType(rawValue: rawValue) ?? GenderType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Gender: Equatable, Decodable {
        var confidence: Float?
        var value: RekognitionClientTypes.GenderType?

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    /// Indicates whether or not the mouth on the face is open, and the confidence level in the determination.
    struct MouthOpen: Equatable, Decodable {
        /// Level of confidence in the determination.
        var confidence: Float?
        /// Boolean value that indicates whether the mouth on the face is open or not.
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    struct Mustache: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    struct Sunglasses: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}


extension RekognitionClientTypes {
    struct FaceDetail: Equatable, Decodable {
        var ageRange: RekognitionClientTypes.AgeRange?
        var beard: RekognitionClientTypes.Beard?
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var confidence: Float?
        var emotions: [RekognitionClientTypes.Emotion]?
        var eyeDirection: RekognitionClientTypes.EyeDirection?
        var eyeglasses: RekognitionClientTypes.Eyeglasses?
        var eyesOpen: RekognitionClientTypes.EyeOpen?
        var faceOccluded: RekognitionClientTypes.FaceOccluded?
        var gender: RekognitionClientTypes.Gender?
        var landmarks: [RekognitionClientTypes.Landmark]?
        var mouthOpen: RekognitionClientTypes.MouthOpen?
        var mustache: RekognitionClientTypes.Mustache?
        var pose: RekognitionClientTypes.Pose?
        var quality: RekognitionClientTypes.ImageQuality?
        var smile: RekognitionClientTypes.Smile?
        var sunglasses: RekognitionClientTypes.Sunglasses?

        enum CodingKeys: String, CodingKey {
            case ageRange = "AgeRange"
            case beard = "Beard"
            case boundingBox = "BoundingBox"
            case confidence = "Confidence"
            case emotions = "Emotions"
            case eyeDirection = "EyeDirection"
            case eyeglasses = "Eyeglasses"
            case eyesOpen = "EyesOpen"
            case faceOccluded = "FaceOccluded"
            case gender = "Gender"
            case landmarks = "Landmarks"
            case mouthOpen = "MouthOpen"
            case mustache = "Mustache"
            case pose = "Pose"
            case quality = "Quality"
            case smile = "Smile"
            case sunglasses = "Sunglasses"
        }
    }
}

extension RekognitionClientTypes {
    struct Geometry: Equatable, Decodable {
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var polygon: [RekognitionClientTypes.Point]?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension RekognitionClientTypes {
    struct Point: Equatable, Codable {
        var x: Float?
        var y: Float?

        enum CodingKeys: String, CodingKey {
            case x = "X"
            case y = "Y"
        }
    }
}

extension RekognitionClientTypes {
    enum TextTypes: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case line
        case word
        case sdkUnknown(String)

        static var allCases: [TextTypes] {
            return [
                .line,
                .word,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .line: return "LINE"
            case .word: return "WORD"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = TextTypes(rawValue: rawValue) ?? TextTypes.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct TextDetection: Equatable, Decodable {
        var confidence: Float?
        var detectedText: String?
        var geometry: RekognitionClientTypes.Geometry?
        var id: Int?
        var parentId: Int?
        var type: RekognitionClientTypes.TextTypes?

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case detectedText = "DetectedText"
            case geometry = "Geometry"
            case id = "Id"
            case parentId = "ParentId"
            case type = "Type"
        }
    }
}

extension RekognitionClientTypes {
    struct RegionOfInterest: Equatable, Encodable {
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var polygon: [RekognitionClientTypes.Point]?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectionFilter: Equatable, Encodable {
        var minBoundingBoxHeight: Float?
        var minBoundingBoxWidth: Float?
        var minConfidence: Float?

        enum CodingKeys: String, CodingKey {
            case minBoundingBoxHeight = "MinBoundingBoxHeight"
            case minBoundingBoxWidth = "MinBoundingBoxWidth"
            case minConfidence = "MinConfidence"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectTextFilters: Equatable, Encodable {
        var regionsOfInterest: [RekognitionClientTypes.RegionOfInterest]?
        var wordFilter: RekognitionClientTypes.DetectionFilter?

        enum CodingKeys: String, CodingKey {
            case regionsOfInterest = "RegionsOfInterest"
            case wordFilter = "WordFilter"
        }
    }
}

extension RekognitionClientTypes {
    enum Attribute: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case ageRange
        case all
        case beard
        case `default`
        case emotions
        case eyeglasses
        case eyesOpen
        case eyeDirection
        case faceOccluded
        case gender
        case mouthOpen
        case mustache
        case smile
        case sunglasses
        case sdkUnknown(String)

        static var allCases: [Attribute] {
            return [
                .ageRange,
                .all,
                .beard,
                .default,
                .emotions,
                .eyeglasses,
                .eyesOpen,
                .eyeDirection,
                .faceOccluded,
                .gender,
                .mouthOpen,
                .mustache,
                .smile,
                .sunglasses,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .ageRange: return "AGE_RANGE"
            case .all: return "ALL"
            case .beard: return "BEARD"
            case .default: return "DEFAULT"
            case .emotions: return "EMOTIONS"
            case .eyeglasses: return "EYEGLASSES"
            case .eyesOpen: return "EYES_OPEN"
            case .eyeDirection: return "EYE_DIRECTION"
            case .faceOccluded: return "FACE_OCCLUDED"
            case .gender: return "GENDER"
            case .mouthOpen: return "MOUTH_OPEN"
            case .mustache: return "MUSTACHE"
            case .smile: return "SMILE"
            case .sunglasses: return "SUNGLASSES"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Attribute(rawValue: rawValue) ?? Attribute.sdkUnknown(rawValue)
        }
    }
}


extension RekognitionClientTypes {
    struct ModerationLabel: Equatable, Decodable {
        var confidence: Float?
        var name: String?
        var parentName: String?

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case name = "Name"
            case parentName = "ParentName"
        }
    }
}

extension RekognitionClientTypes {
    struct HumanLoopActivationOutput: Equatable, Decodable {
        var humanLoopActivationConditionsEvaluationResults: String?
        var humanLoopActivationReasons: [String]?
        var humanLoopArn: String?

        enum CodingKeys: String, CodingKey {
            case humanLoopActivationConditionsEvaluationResults = "HumanLoopActivationConditionsEvaluationResults"
            case humanLoopActivationReasons = "HumanLoopActivationReasons"
            case humanLoopArn = "HumanLoopArn"
        }
    }
}

extension RekognitionClientTypes {
    enum ContentClassifier: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case freeOfAdultContent
        case freeOfPersonallyIdentifiableInformation
        case sdkUnknown(String)

        static var allCases: [ContentClassifier] {
            return [
                .freeOfAdultContent,
                .freeOfPersonallyIdentifiableInformation,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .freeOfAdultContent: return "FreeOfAdultContent"
            case .freeOfPersonallyIdentifiableInformation: return "FreeOfPersonallyIdentifiableInformation"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ContentClassifier(rawValue: rawValue) ?? ContentClassifier.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct HumanLoopDataAttributes: Equatable, Encodable {
        var contentClassifiers: [RekognitionClientTypes.ContentClassifier]?

        enum CodingKeys: String, CodingKey {
            case contentClassifiers = "ContentClassifiers"
        }
    }
}

extension RekognitionClientTypes {
    struct HumanLoopConfig: Equatable, Encodable {
        var dataAttributes: RekognitionClientTypes.HumanLoopDataAttributes?
        /// This member is required.
        var flowDefinitionArn: String
        /// This member is required.
        var humanLoopName: String

        enum CodingKeys: String, CodingKey {
            case dataAttributes = "DataAttributes"
            case flowDefinitionArn = "FlowDefinitionArn"
            case humanLoopName = "HumanLoopName"
        }
    }
}

extension RekognitionClientTypes {
    struct LabelAlias: Equatable, Decodable {
        var name: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
}

extension RekognitionClientTypes {
    struct LabelCategory: Equatable, Decodable {
        var name: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
}

extension RekognitionClientTypes {
    struct DominantColor: Equatable, Decodable {
        var blue: Int?
        var cssColor: String?
        var green: Int?
        var hexCode: String?
        var pixelPercent: Float?
        var red: Int?
        var simplifiedColor: String?

        enum CodingKeys: String, CodingKey {
            case blue = "Blue"
            case cssColor = "CSSColor"
            case green = "Green"
            case hexCode = "HexCode"
            case pixelPercent = "PixelPercent"
            case red = "Red"
            case simplifiedColor = "SimplifiedColor"
        }
    }
}

extension RekognitionClientTypes {
    struct Instance: Equatable, Decodable {
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var confidence: Float?
        var dominantColors: [RekognitionClientTypes.DominantColor]?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case confidence = "Confidence"
            case dominantColors = "DominantColors"
        }
    }
}

extension RekognitionClientTypes {
    struct Parent: Equatable, Decodable {
        var name: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
        }
    }
}


extension RekognitionClientTypes {
    struct Label: Equatable, Decodable {
        var aliases: [RekognitionClientTypes.LabelAlias]?
        var categories: [RekognitionClientTypes.LabelCategory]?
        var confidence: Float?
        var instances: [RekognitionClientTypes.Instance]?
        var name: String?
        var parents: [RekognitionClientTypes.Parent]?

        enum CodingKeys: String, CodingKey {
            case aliases = "Aliases"
            case categories = "Categories"
            case confidence = "Confidence"
            case instances = "Instances"
            case name = "Name"
            case parents = "Parents"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsImageBackground: Equatable, Decodable {
        var dominantColors: [RekognitionClientTypes.DominantColor]?
        var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: String, CodingKey {
            case dominantColors = "DominantColors"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsImageQuality: Equatable, Decodable {
        var brightness: Float?
        var contrast: Float?
        var sharpness: Float?

        enum CodingKeys: String, CodingKey {
            case brightness = "Brightness"
            case contrast = "Contrast"
            case sharpness = "Sharpness"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsImageForeground: Equatable, Decodable {
        var dominantColors: [RekognitionClientTypes.DominantColor]?
        var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: String, CodingKey {
            case dominantColors = "DominantColors"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsImageProperties: Equatable, Decodable {
        var background: RekognitionClientTypes.DetectLabelsImageBackground?
        var dominantColors: [RekognitionClientTypes.DominantColor]?
        var foreground: RekognitionClientTypes.DetectLabelsImageForeground?
        var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: String, CodingKey {
            case background = "Background"
            case dominantColors = "DominantColors"
            case foreground = "Foreground"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    struct GeneralLabelsSettings: Equatable, Encodable {
        var labelCategoryExclusionFilters: [String]?
        var labelCategoryInclusionFilters: [String]?
        var labelExclusionFilters: [String]?
        var labelInclusionFilters: [String]?

        enum CodingKeys: String, CodingKey {
            case labelCategoryExclusionFilters = "LabelCategoryExclusionFilters"
            case labelCategoryInclusionFilters = "LabelCategoryInclusionFilters"
            case labelExclusionFilters = "LabelExclusionFilters"
            case labelInclusionFilters = "LabelInclusionFilters"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsImagePropertiesSettings: Equatable, Encodable {
        var maxDominantColors: Int?

        enum CodingKeys: String, CodingKey {
            case maxDominantColors = "MaxDominantColors"
        }
    }
}

extension RekognitionClientTypes {
    struct DetectLabelsSettings: Equatable, Encodable {
        var generalLabels: RekognitionClientTypes.GeneralLabelsSettings?
        var imageProperties: RekognitionClientTypes.DetectLabelsImagePropertiesSettings?
        
        enum CodingKeys: String, CodingKey {
            case generalLabels = "GeneralLabels"
            case imageProperties = "ImageProperties"
        }
    }
}

extension RekognitionClientTypes {
    enum DetectLabelsFeatureName: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case generalLabels
        case imageProperties
        case sdkUnknown(String)

        static var allCases: [DetectLabelsFeatureName] {
            return [
                .generalLabels,
                .imageProperties,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .generalLabels: return "GENERAL_LABELS"
            case .imageProperties: return "IMAGE_PROPERTIES"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DetectLabelsFeatureName(rawValue: rawValue) ?? DetectLabelsFeatureName.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Face: Equatable, Decodable {
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var confidence: Float?
        var externalImageId: String?
        var faceId: String?
        var imageId: String?
        var indexFacesModelVersion: String?
        var userId: String?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case confidence = "Confidence"
            case externalImageId = "ExternalImageId"
            case faceId = "FaceId"
            case imageId = "ImageId"
            case indexFacesModelVersion = "IndexFacesModelVersion"
            case userId = "UserId"
        }
    }
}


extension RekognitionClientTypes {
    struct FaceMatch: Equatable, Decodable {
        var face: RekognitionClientTypes.Face?
        var similarity: Float?

        enum CodingKeys: String, CodingKey {
            case face = "Face"
            case similarity = "Similarity"
        }
    }
}

extension RekognitionClientTypes {
    enum QualityFilter: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case auto
        case high
        case low
        case medium
        case `none`
        case sdkUnknown(String)

        static var allCases: [QualityFilter] {
            return [
                .auto,
                .high,
                .low,
                .medium,
                .none,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .auto: return "AUTO"
            case .high: return "HIGH"
            case .low: return "LOW"
            case .medium: return "MEDIUM"
            case .none: return "NONE"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = QualityFilter(rawValue: rawValue) ?? QualityFilter.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    enum OrientationCorrection: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case rotate0
        case rotate180
        case rotate270
        case rotate90
        case sdkUnknown(String)

        static var allCases: [OrientationCorrection] {
            return [
                .rotate0,
                .rotate180,
                .rotate270,
                .rotate90,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .rotate0: return "ROTATE_0"
            case .rotate180: return "ROTATE_180"
            case .rotate270: return "ROTATE_270"
            case .rotate90: return "ROTATE_90"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = OrientationCorrection(rawValue: rawValue) ?? OrientationCorrection.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Emotion: Equatable, Decodable {
        var confidence: Float?
        var type: RekognitionClientTypes.EmotionName?

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case type = "Type"
        }
    }
}

extension RekognitionClientTypes {
    enum EmotionName: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case angry
        case calm
        case confused
        case disgusted
        case fear
        case happy
        case sad
        case surprised
        case unknown
        case sdkUnknown(String)

        static var allCases: [EmotionName] {
            return [
                .angry,
                .calm,
                .confused,
                .disgusted,
                .fear,
                .happy,
                .sad,
                .surprised,
                .unknown,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .angry: return "ANGRY"
            case .calm: return "CALM"
            case .confused: return "CONFUSED"
            case .disgusted: return "DISGUSTED"
            case .fear: return "FEAR"
            case .happy: return "HAPPY"
            case .sad: return "SAD"
            case .surprised: return "SURPRISED"
            case .unknown: return "UNKNOWN"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = EmotionName(rawValue: rawValue) ?? EmotionName.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Pose: Equatable, Decodable {
        var pitch: Float?
        var roll: Float?
        var yaw: Float?

        enum CodingKeys: String, CodingKey {
            case pitch = "Pitch"
            case roll = "Roll"
            case yaw = "Yaw"
        }
    }
}

extension RekognitionClientTypes {
    enum LandmarkType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case chinbottom
        case eyeleft
        case eyeright
        case lefteyebrowleft
        case lefteyebrowright
        case lefteyebrowup
        case lefteyedown
        case lefteyeleft
        case lefteyeright
        case lefteyeup
        case leftpupil
        case midjawlineleft
        case midjawlineright
        case mouthdown
        case mouthleft
        case mouthright
        case mouthup
        case nose
        case noseleft
        case noseright
        case righteyebrowleft
        case righteyebrowright
        case righteyebrowup
        case righteyedown
        case righteyeleft
        case righteyeright
        case righteyeup
        case rightpupil
        case upperjawlineleft
        case upperjawlineright
        case sdkUnknown(String)

        static var allCases: [LandmarkType] {
            return [
                .chinbottom,
                .eyeleft,
                .eyeright,
                .lefteyebrowleft,
                .lefteyebrowright,
                .lefteyebrowup,
                .lefteyedown,
                .lefteyeleft,
                .lefteyeright,
                .lefteyeup,
                .leftpupil,
                .midjawlineleft,
                .midjawlineright,
                .mouthdown,
                .mouthleft,
                .mouthright,
                .mouthup,
                .nose,
                .noseleft,
                .noseright,
                .righteyebrowleft,
                .righteyebrowright,
                .righteyebrowup,
                .righteyedown,
                .righteyeleft,
                .righteyeright,
                .righteyeup,
                .rightpupil,
                .upperjawlineleft,
                .upperjawlineright,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .chinbottom: return "chinBottom"
            case .eyeleft: return "eyeLeft"
            case .eyeright: return "eyeRight"
            case .lefteyebrowleft: return "leftEyeBrowLeft"
            case .lefteyebrowright: return "leftEyeBrowRight"
            case .lefteyebrowup: return "leftEyeBrowUp"
            case .lefteyedown: return "leftEyeDown"
            case .lefteyeleft: return "leftEyeLeft"
            case .lefteyeright: return "leftEyeRight"
            case .lefteyeup: return "leftEyeUp"
            case .leftpupil: return "leftPupil"
            case .midjawlineleft: return "midJawlineLeft"
            case .midjawlineright: return "midJawlineRight"
            case .mouthdown: return "mouthDown"
            case .mouthleft: return "mouthLeft"
            case .mouthright: return "mouthRight"
            case .mouthup: return "mouthUp"
            case .nose: return "nose"
            case .noseleft: return "noseLeft"
            case .noseright: return "noseRight"
            case .righteyebrowleft: return "rightEyeBrowLeft"
            case .righteyebrowright: return "rightEyeBrowRight"
            case .righteyebrowup: return "rightEyeBrowUp"
            case .righteyedown: return "rightEyeDown"
            case .righteyeleft: return "rightEyeLeft"
            case .righteyeright: return "rightEyeRight"
            case .righteyeup: return "rightEyeUp"
            case .rightpupil: return "rightPupil"
            case .upperjawlineleft: return "upperJawlineLeft"
            case .upperjawlineright: return "upperJawlineRight"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LandmarkType(rawValue: rawValue) ?? LandmarkType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Landmark: Equatable, Decodable {
        var type: RekognitionClientTypes.LandmarkType?
        var x: Float?
        var y: Float?

        enum CodingKeys: String, CodingKey {
            case type = "Type"
            case x = "X"
            case y = "Y"
        }
    }
}

extension RekognitionClientTypes {
    struct ImageQuality: Equatable, Decodable {
        var brightness: Float?
        var sharpness: Float?

        enum CodingKeys: String, CodingKey {
            case brightness = "Brightness"
            case sharpness = "Sharpness"
        }
    }
}

extension RekognitionClientTypes {
    struct Smile: Equatable, Decodable {
        var confidence: Float?
        var value: Bool

        enum CodingKeys: String, CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}


extension RekognitionClientTypes {
    struct ComparedFace: Equatable, Decodable {
        var boundingBox: RekognitionClientTypes.BoundingBox?
        var confidence: Float?
        var emotions: [RekognitionClientTypes.Emotion]?
        var landmarks: [RekognitionClientTypes.Landmark]?
        var pose: RekognitionClientTypes.Pose?
        var quality: RekognitionClientTypes.ImageQuality?
        var smile: RekognitionClientTypes.Smile?

        enum CodingKeys: String, CodingKey {
            case boundingBox = "BoundingBox"
            case confidence = "Confidence"
            case emotions = "Emotions"
            case landmarks = "Landmarks"
            case pose = "Pose"
            case quality = "Quality"
            case smile = "Smile"
        }
    }
}

extension RekognitionClientTypes {
    struct BoundingBox: Equatable, Codable {
        var height: Float?
        var `left`: Float?
        var top: Float?
        var width: Float?

        enum CodingKeys: String, CodingKey {
            case height = "Height"
            case `left` = "Left"
            case top = "Top"
            case width = "Width"
        }
    }
}

extension RekognitionClientTypes {
    struct KnownGender: Equatable, Decodable {
        var type: RekognitionClientTypes.KnownGenderType?

        enum CodingKeys: String, CodingKey {
            case type = "Type"
        }
    }
}

extension RekognitionClientTypes {
    enum KnownGenderType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case female
        case male
        case nonbinary
        case unlisted
        case sdkUnknown(String)

        static var allCases: [KnownGenderType] {
            return [
                .female,
                .male,
                .nonbinary,
                .unlisted,
                .sdkUnknown("")
            ]
        }
        init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        var rawValue: String {
            switch self {
            case .female: return "Female"
            case .male: return "Male"
            case .nonbinary: return "Nonbinary"
            case .unlisted: return "Unlisted"
            case let .sdkUnknown(s): return s
            }
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = KnownGenderType(rawValue: rawValue) ?? KnownGenderType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    struct Celebrity: Equatable, Decodable {
        var face: RekognitionClientTypes.ComparedFace?
        var id: String?
        var knownGender: RekognitionClientTypes.KnownGender?
        var matchConfidence: Float?
        var name: String?
        var urls: [String]?

        enum CodingKeys: String, CodingKey {
            case face = "Face"
            case id = "Id"
            case knownGender = "KnownGender"
            case matchConfidence = "MatchConfidence"
            case name = "Name"
            case urls = "Urls"
        }
    }
}

extension RekognitionClientTypes {
    struct Image: Equatable, Codable {
        var bytes: Data?
        var s3Object: RekognitionClientTypes.S3Object?

        enum CodingKeys: String, CodingKey {
            case bytes = "Bytes"
            case s3Object = "S3Object"
        }
    }
}

extension RekognitionClientTypes {
    struct S3Object: Equatable, Codable {
        var bucket: String?
        var name: String?
        var version: String?

        enum CodingKeys: String, CodingKey {
            case bucket = "Bucket"
            case name = "Name"
            case version = "Version"
        }
    }
}

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

public struct DetectLabelsInput: Swift.Equatable {
    public var features: [RekognitionClientTypes.DetectLabelsFeatureName]?
    /// This member is required.
    public var image: RekognitionClientTypes.Image
    public var maxLabels: Swift.Int?
    public var minConfidence: Swift.Float?
    public var settings: RekognitionClientTypes.DetectLabelsSettings?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case features = "Features"
        case image = "Image"
        case maxLabels = "MaxLabels"
        case minConfidence = "MinConfidence"
        case settings = "Settings"
    }
}

public struct DetectLabelsOutputResponse: Swift.Equatable {
    public var imageProperties: RekognitionClientTypes.DetectLabelsImageProperties?
    public var labelModelVersion: Swift.String?
    public var labels: [RekognitionClientTypes.Label]?
    public var orientationCorrection: RekognitionClientTypes.OrientationCorrection?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case imageProperties = "ImageProperties"
        case labelModelVersion = "LabelModelVersion"
        case labels = "Labels"
        case orientationCorrection = "OrientationCorrection"
    }
}

public struct DetectModerationLabelsInput: Swift.Equatable {
    public var humanLoopConfig: RekognitionClientTypes.HumanLoopConfig?
    /// This member is required.
    public var image: RekognitionClientTypes.Image
    public var minConfidence: Swift.Float?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case humanLoopConfig = "HumanLoopConfig"
        case image = "Image"
        case minConfidence = "MinConfidence"
    }
}

public struct DetectModerationLabelsOutputResponse: Swift.Equatable {
    public var humanLoopActivationOutput: RekognitionClientTypes.HumanLoopActivationOutput?
    public var moderationLabels: [RekognitionClientTypes.ModerationLabel]?
    public var moderationModelVersion: Swift.String?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case humanLoopActivationOutput = "HumanLoopActivationOutput"
        case moderationLabels = "ModerationLabels"
        case moderationModelVersion = "ModerationModelVersion"
    }
}

public struct DetectTextInput: Swift.Equatable {
    public var filters: RekognitionClientTypes.DetectTextFilters?
    /// This member is required.
    public var image: RekognitionClientTypes.Image

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case filters = "Filters"
        case image = "Image"
    }
}

public struct DetectTextOutputResponse: Swift.Equatable {
    public var textDetections: [RekognitionClientTypes.TextDetection]?
    public var textModelVersion: Swift.String?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case textDetections = "TextDetections"
        case textModelVersion = "TextModelVersion"
    }
}



public struct DetectFacesInput: Swift.Equatable {
    public var attributes: [RekognitionClientTypes.Attribute]?
    /// This member is required.
    public var image: RekognitionClientTypes.Image

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case attributes = "Attributes"
        case image = "Image"
    }
}

public struct DetectFacesOutputResponse: Swift.Equatable {
    public var faceDetails: [RekognitionClientTypes.FaceDetail]?
    public var orientationCorrection: RekognitionClientTypes.OrientationCorrection?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case faceDetails = "FaceDetails"
        case orientationCorrection = "OrientationCorrection"
    }
}

public struct SearchFacesByImageInput: Swift.Equatable {
    /// This member is required.
    public var collectionId: Swift.String
    public var faceMatchThreshold: Swift.Float?
    /// This member is required.
    public var image: RekognitionClientTypes.Image
    public var maxFaces: Swift.Int?
    public var qualityFilter: RekognitionClientTypes.QualityFilter?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case collectionId = "CollectionId"
        case faceMatchThreshold = "FaceMatchThreshold"
        case image = "Image"
        case maxFaces = "MaxFaces"
        case qualityFilter = "QualityFilter"
    }
}

public struct SearchFacesByImageOutputResponse: Swift.Equatable {
    public var faceMatches: [RekognitionClientTypes.FaceMatch]?
    public var faceModelVersion: Swift.String?
    public var searchedFaceBoundingBox: RekognitionClientTypes.BoundingBox?
    public var searchedFaceConfidence: Swift.Float?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case faceMatches = "FaceMatches"
        case faceModelVersion = "FaceModelVersion"
        case searchedFaceBoundingBox = "SearchedFaceBoundingBox"
        case searchedFaceConfidence = "SearchedFaceConfidence"
    }
}

public struct RecognizeCelebritiesInput: Swift.Equatable {
    /// This member is required.
    public var image: RekognitionClientTypes.Image

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case image = "Image"
    }
}

public struct RecognizeCelebritiesOutputResponse: Swift.Equatable {
    public var celebrityFaces: [RekognitionClientTypes.Celebrity]?
    public var orientationCorrection: RekognitionClientTypes.OrientationCorrection?
    public var unrecognizedFaces: [RekognitionClientTypes.ComparedFace]?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case celebrityFaces = "CelebrityFaces"
        case orientationCorrection = "OrientationCorrection"
        case unrecognizedFaces = "UnrecognizedFaces"
    }
}


public enum RekognitionClientTypes {}

extension RekognitionClientTypes {
    public struct AgeRange: Swift.Equatable {
        public var high: Swift.Int?
        public var low: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case high = "High"
            case low = "Low"
        }
    }
}

extension RekognitionClientTypes {
    public struct Beard: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public struct EyeDirection: Swift.Equatable {
        public var confidence: Swift.Float?
        public var pitch: Swift.Float?
        public var yaw: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case pitch = "Pitch"
            case yaw = "Yaw"
        }
    }
}

extension RekognitionClientTypes {
    public struct Eyeglasses: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public struct EyeOpen: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public struct FaceOccluded: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public enum GenderType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case female
        case male
        case sdkUnknown(Swift.String)

        public static var allCases: [GenderType] {
            return [
                .female,
                .male,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .female: return "Female"
            case .male: return "Male"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = GenderType(rawValue: rawValue) ?? GenderType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Gender: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: RekognitionClientTypes.GenderType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    /// Indicates whether or not the mouth on the face is open, and the confidence level in the determination.
    public struct MouthOpen: Swift.Equatable {
        /// Level of confidence in the determination.
        public var confidence: Swift.Float?
        /// Boolean value that indicates whether the mouth on the face is open or not.
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public struct Mustache: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}

extension RekognitionClientTypes {
    public struct Sunglasses: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}


extension RekognitionClientTypes {
    public struct FaceDetail: Swift.Equatable {
        public var ageRange: RekognitionClientTypes.AgeRange?
        public var beard: RekognitionClientTypes.Beard?
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var confidence: Swift.Float?
        public var emotions: [RekognitionClientTypes.Emotion]?
        public var eyeDirection: RekognitionClientTypes.EyeDirection?
        public var eyeglasses: RekognitionClientTypes.Eyeglasses?
        public var eyesOpen: RekognitionClientTypes.EyeOpen?
        public var faceOccluded: RekognitionClientTypes.FaceOccluded?
        public var gender: RekognitionClientTypes.Gender?
        public var landmarks: [RekognitionClientTypes.Landmark]?
        public var mouthOpen: RekognitionClientTypes.MouthOpen?
        public var mustache: RekognitionClientTypes.Mustache?
        public var pose: RekognitionClientTypes.Pose?
        public var quality: RekognitionClientTypes.ImageQuality?
        public var smile: RekognitionClientTypes.Smile?
        public var sunglasses: RekognitionClientTypes.Sunglasses?
    }
}

extension RekognitionClientTypes {
    public struct Geometry: Swift.Equatable {
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var polygon: [RekognitionClientTypes.Point]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension RekognitionClientTypes {
    public struct Point: Swift.Equatable {
        public var x: Swift.Float?
        public var y: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case x = "X"
            case y = "Y"
        }
    }
}

extension RekognitionClientTypes {
    public enum TextTypes: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case line
        case word
        case sdkUnknown(Swift.String)

        public static var allCases: [TextTypes] {
            return [
                .line,
                .word,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .line: return "LINE"
            case .word: return "WORD"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = TextTypes(rawValue: rawValue) ?? TextTypes.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct TextDetection: Swift.Equatable {
        public var confidence: Swift.Float?
        public var detectedText: Swift.String?
        public var geometry: RekognitionClientTypes.Geometry?
        public var id: Swift.Int?
        public var parentId: Swift.Int?
        public var type: RekognitionClientTypes.TextTypes?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct RegionOfInterest: Swift.Equatable {
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var polygon: [RekognitionClientTypes.Point]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case boundingBox = "BoundingBox"
            case polygon = "Polygon"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectionFilter: Swift.Equatable {
        public var minBoundingBoxHeight: Swift.Float?
        public var minBoundingBoxWidth: Swift.Float?
        public var minConfidence: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case minBoundingBoxHeight = "MinBoundingBoxHeight"
            case minBoundingBoxWidth = "MinBoundingBoxWidth"
            case minConfidence = "MinConfidence"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectTextFilters: Swift.Equatable {
        public var regionsOfInterest: [RekognitionClientTypes.RegionOfInterest]?
        public var wordFilter: RekognitionClientTypes.DetectionFilter?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case regionsOfInterest = "RegionsOfInterest"
            case wordFilter = "WordFilter"
        }
    }
}

extension RekognitionClientTypes {
    public enum Attribute: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
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
        case sdkUnknown(Swift.String)

        public static var allCases: [Attribute] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Attribute(rawValue: rawValue) ?? Attribute.sdkUnknown(rawValue)
        }
    }
}


extension RekognitionClientTypes {
    public struct ModerationLabel: Swift.Equatable {
        public var confidence: Swift.Float?
        public var name: Swift.String?
        public var parentName: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case name = "Name"
            case parentName = "ParentName"
        }
    }
}

extension RekognitionClientTypes {
    public struct HumanLoopActivationOutput: Swift.Equatable {
        public var humanLoopActivationConditionsEvaluationResults: Swift.String?
        public var humanLoopActivationReasons: [Swift.String]?
        public var humanLoopArn: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case humanLoopActivationConditionsEvaluationResults = "HumanLoopActivationConditionsEvaluationResults"
            case humanLoopActivationReasons = "HumanLoopActivationReasons"
            case humanLoopArn = "HumanLoopArn"
        }
    }
}

extension RekognitionClientTypes {
    public enum ContentClassifier: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case freeOfAdultContent
        case freeOfPersonallyIdentifiableInformation
        case sdkUnknown(Swift.String)

        public static var allCases: [ContentClassifier] {
            return [
                .freeOfAdultContent,
                .freeOfPersonallyIdentifiableInformation,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .freeOfAdultContent: return "FreeOfAdultContent"
            case .freeOfPersonallyIdentifiableInformation: return "FreeOfPersonallyIdentifiableInformation"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ContentClassifier(rawValue: rawValue) ?? ContentClassifier.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct HumanLoopDataAttributes: Swift.Equatable {
        public var contentClassifiers: [RekognitionClientTypes.ContentClassifier]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case contentClassifiers = "ContentClassifiers"
        }
    }
}

extension RekognitionClientTypes {
    public struct HumanLoopConfig: Swift.Equatable {
        public var dataAttributes: RekognitionClientTypes.HumanLoopDataAttributes?
        /// This member is required.
        public var flowDefinitionArn: Swift.String
        /// This member is required.
        public var humanLoopName: Swift.String

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case dataAttributes = "DataAttributes"
            case flowDefinitionArn = "FlowDefinitionArn"
            case humanLoopName = "HumanLoopName"
        }
    }
}

extension RekognitionClientTypes {
    /// A potential alias of for a given label.
    public struct LabelAlias: Swift.Equatable {
        /// The name of an alias for a given label.
        public var name: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case name = "Name"
        }
    }
}

extension RekognitionClientTypes {
    public struct LabelCategory: Swift.Equatable {
        public var name: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case name = "Name"
        }
    }
}

extension RekognitionClientTypes {
    public struct DominantColor: Swift.Equatable {
        public var blue: Swift.Int?
        public var cssColor: Swift.String?
        public var green: Swift.Int?
        public var hexCode: Swift.String?
        public var pixelPercent: Swift.Float?
        public var red: Swift.Int?
        public var simplifiedColor: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct Instance: Swift.Equatable {
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var confidence: Swift.Float?
        public var dominantColors: [RekognitionClientTypes.DominantColor]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case boundingBox = "BoundingBox"
            case confidence = "Confidence"
            case dominantColors = "DominantColors"
        }
    }
}

extension RekognitionClientTypes {
    public struct Parent: Swift.Equatable {
        public var name: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case name = "Name"
        }
    }
}


extension RekognitionClientTypes {
    public struct Label: Swift.Equatable {
        public var aliases: [RekognitionClientTypes.LabelAlias]?
        public var categories: [RekognitionClientTypes.LabelCategory]?
        public var confidence: Swift.Float?
        public var instances: [RekognitionClientTypes.Instance]?
        public var name: Swift.String?
        public var parents: [RekognitionClientTypes.Parent]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct DetectLabelsImageBackground: Swift.Equatable {
        public var dominantColors: [RekognitionClientTypes.DominantColor]?
        public var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case dominantColors = "DominantColors"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectLabelsImageQuality: Swift.Equatable {
        public var brightness: Swift.Float?
        public var contrast: Swift.Float?
        public var sharpness: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case brightness = "Brightness"
            case contrast = "Contrast"
            case sharpness = "Sharpness"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectLabelsImageForeground: Swift.Equatable {
        public var dominantColors: [RekognitionClientTypes.DominantColor]?
        public var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case dominantColors = "DominantColors"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectLabelsImageProperties: Swift.Equatable {
        public var background: RekognitionClientTypes.DetectLabelsImageBackground?
        public var dominantColors: [RekognitionClientTypes.DominantColor]?
        public var foreground: RekognitionClientTypes.DetectLabelsImageForeground?
        public var quality: RekognitionClientTypes.DetectLabelsImageQuality?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case background = "Background"
            case dominantColors = "DominantColors"
            case foreground = "Foreground"
            case quality = "Quality"
        }
    }
}

extension RekognitionClientTypes {
    public struct GeneralLabelsSettings: Swift.Equatable {
        public var labelCategoryExclusionFilters: [Swift.String]?
        public var labelCategoryInclusionFilters: [Swift.String]?
        public var labelExclusionFilters: [Swift.String]?
        public var labelInclusionFilters: [Swift.String]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case labelCategoryExclusionFilters = "LabelCategoryExclusionFilters"
            case labelCategoryInclusionFilters = "LabelCategoryInclusionFilters"
            case labelExclusionFilters = "LabelExclusionFilters"
            case labelInclusionFilters = "LabelInclusionFilters"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectLabelsImagePropertiesSettings: Swift.Equatable {
        public var maxDominantColors: Swift.Int?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case maxDominantColors = "MaxDominantColors"
        }
    }
}

extension RekognitionClientTypes {
    public struct DetectLabelsSettings: Swift.Equatable {
        public var generalLabels: RekognitionClientTypes.GeneralLabelsSettings?
        public var imageProperties: RekognitionClientTypes.DetectLabelsImagePropertiesSettings?
        
        enum CodingKeys: Swift.String, Swift.CodingKey {
            case generalLabels = "GeneralLabels"
            case imageProperties = "ImageProperties"
        }
    }
}

extension RekognitionClientTypes {
    public enum DetectLabelsFeatureName: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case generalLabels
        case imageProperties
        case sdkUnknown(Swift.String)

        public static var allCases: [DetectLabelsFeatureName] {
            return [
                .generalLabels,
                .imageProperties,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .generalLabels: return "GENERAL_LABELS"
            case .imageProperties: return "IMAGE_PROPERTIES"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = DetectLabelsFeatureName(rawValue: rawValue) ?? DetectLabelsFeatureName.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Face: Swift.Equatable {
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var confidence: Swift.Float?
        public var externalImageId: Swift.String?
        public var faceId: Swift.String?
        public var imageId: Swift.String?
        public var indexFacesModelVersion: Swift.String?
        public var userId: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct FaceMatch: Swift.Equatable {
        public var face: RekognitionClientTypes.Face?
        public var similarity: Swift.Float?
    }
}

extension RekognitionClientTypes {
    public enum QualityFilter: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case auto
        case high
        case low
        case medium
        case `none`
        case sdkUnknown(Swift.String)

        public static var allCases: [QualityFilter] {
            return [
                .auto,
                .high,
                .low,
                .medium,
                .none,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .auto: return "AUTO"
            case .high: return "HIGH"
            case .low: return "LOW"
            case .medium: return "MEDIUM"
            case .none: return "NONE"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = QualityFilter(rawValue: rawValue) ?? QualityFilter.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public enum OrientationCorrection: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case rotate0
        case rotate180
        case rotate270
        case rotate90
        case sdkUnknown(Swift.String)

        public static var allCases: [OrientationCorrection] {
            return [
                .rotate0,
                .rotate180,
                .rotate270,
                .rotate90,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .rotate0: return "ROTATE_0"
            case .rotate180: return "ROTATE_180"
            case .rotate270: return "ROTATE_270"
            case .rotate90: return "ROTATE_90"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = OrientationCorrection(rawValue: rawValue) ?? OrientationCorrection.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Emotion: Swift.Equatable {
        public var confidence: Swift.Float?
        public var type: RekognitionClientTypes.EmotionName?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case type = "Type"
        }
    }
}

extension RekognitionClientTypes {
    public enum EmotionName: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case angry
        case calm
        case confused
        case disgusted
        case fear
        case happy
        case sad
        case surprised
        case unknown
        case sdkUnknown(Swift.String)

        public static var allCases: [EmotionName] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = EmotionName(rawValue: rawValue) ?? EmotionName.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Pose: Swift.Equatable {
        public var pitch: Swift.Float?
        public var roll: Swift.Float?
        public var yaw: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case pitch = "Pitch"
            case roll = "Roll"
            case yaw = "Yaw"
        }
    }
}

extension RekognitionClientTypes {
    public enum LandmarkType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
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
        case sdkUnknown(Swift.String)

        public static var allCases: [LandmarkType] {
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
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
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
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LandmarkType(rawValue: rawValue) ?? LandmarkType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Landmark: Swift.Equatable {
        public var type: RekognitionClientTypes.LandmarkType?
        public var x: Swift.Float?
        public var y: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case type = "Type"
            case x = "X"
            case y = "Y"
        }
    }
}

extension RekognitionClientTypes {
    public struct ImageQuality: Swift.Equatable {
        public var brightness: Swift.Float?
        public var sharpness: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case brightness = "Brightness"
            case sharpness = "Sharpness"
        }
    }
}

extension RekognitionClientTypes {
    public struct Smile: Swift.Equatable {
        public var confidence: Swift.Float?
        public var value: Swift.Bool

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case confidence = "Confidence"
            case value = "Value"
        }
    }
}


extension RekognitionClientTypes {
    public struct ComparedFace: Swift.Equatable {
        public var boundingBox: RekognitionClientTypes.BoundingBox?
        public var confidence: Swift.Float?
        public var emotions: [RekognitionClientTypes.Emotion]?
        public var landmarks: [RekognitionClientTypes.Landmark]?
        public var pose: RekognitionClientTypes.Pose?
        public var quality: RekognitionClientTypes.ImageQuality?
        public var smile: RekognitionClientTypes.Smile?
    }
}

extension RekognitionClientTypes {
    public struct BoundingBox: Swift.Equatable {
        public var height: Swift.Float?
        public var `left`: Swift.Float?
        public var top: Swift.Float?
        public var width: Swift.Float?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case height = "Height"
            case `left` = "Left"
            case top = "Top"
            case width = "Width"
        }
    }
}

extension RekognitionClientTypes {
    public struct KnownGender: Swift.Equatable {
        public var type: RekognitionClientTypes.KnownGenderType?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case type = "Type"
        }
    }
}

extension RekognitionClientTypes {
    public enum KnownGenderType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case female
        case male
        case nonbinary
        case unlisted
        case sdkUnknown(Swift.String)

        public static var allCases: [KnownGenderType] {
            return [
                .female,
                .male,
                .nonbinary,
                .unlisted,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .female: return "Female"
            case .male: return "Male"
            case .nonbinary: return "Nonbinary"
            case .unlisted: return "Unlisted"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = KnownGenderType(rawValue: rawValue) ?? KnownGenderType.sdkUnknown(rawValue)
        }
    }
}

extension RekognitionClientTypes {
    public struct Celebrity: Swift.Equatable {
        public var face: RekognitionClientTypes.ComparedFace?
        public var id: Swift.String?
        public var knownGender: RekognitionClientTypes.KnownGender?
        public var matchConfidence: Swift.Float?
        public var name: Swift.String?
        public var urls: [Swift.String]?

        enum CodingKeys: Swift.String, Swift.CodingKey {
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
    public struct Image: Swift.Equatable {
        public var bytes: Data?
        public var s3Object: RekognitionClientTypes.S3Object?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case bytes = "Bytes"
            case s3Object = "S3Object"
        }
    }
}

extension RekognitionClientTypes {
    public struct S3Object: Swift.Equatable {
        public var bucket: Swift.String?
        public var name: Swift.String?
        public var version: Swift.String?

        enum CodingKeys: Swift.String, Swift.CodingKey {
            case bucket = "Bucket"
            case name = "Name"
            case version = "Version"
        }
    }
}

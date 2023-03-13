//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct ConvertConfiguration {
    public let region: AWSRegionType
    public var translateText: TranslateTextConfiguration?
    public var speechGenerator: SpeechGeneratorConfiguration?
    public var transcription: TranscriptionConfiguration?

    init(_ region: AWSRegionType) {
        self.region = region
        self.translateText = nil
        self.speechGenerator = nil
        self.transcription = nil
    }
}

public struct TranslateTextConfiguration {
    public let sourceLanguage: LanguageType
    public let targetLanguage: LanguageType
}

public struct SpeechGeneratorConfiguration {
    public let voiceID: String?
}

public struct TranscriptionConfiguration {
    public let language: LanguageType
}

extension ConvertConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case translateText
        case speechGenerator
        case transcription
    }

    enum SubRegion: String, CodingKey {
        case region
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var awsRegion: AWSRegionType?

        if let configuration = try values.decodeIfPresent(TranslateTextConfiguration.self,
                                                          forKey: .translateText) {
            self.translateText = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self,
                                                             forKey: .translateText)
            awsRegion = awsRegion ?? ConvertConfiguration.getRegionIfPresent(nestedContainer)
        } else {
            self.translateText = nil
        }

        if let configuration = try values.decodeIfPresent(SpeechGeneratorConfiguration.self,
                                                          forKey: .speechGenerator) {
            self.speechGenerator = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self,
                                                             forKey: .speechGenerator)
            awsRegion = awsRegion ?? ConvertConfiguration.getRegionIfPresent(nestedContainer)
        } else {
            self.speechGenerator = nil
        }

        if let configuration = try values.decodeIfPresent(TranscriptionConfiguration.self, forKey: .transcription) {
            self.transcription = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self, forKey: .transcription)
            awsRegion = awsRegion ?? ConvertConfiguration.getRegionIfPresent(nestedContainer)
        } else {
            self.transcription = nil
        }

        guard  let region = awsRegion else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.missingRegion.errorDescription,
                                                       PluginErrorMessage.missingRegion.recoverySuggestion)
        }
        self.region = region
    }

    static func getRegionIfPresent(_ container: KeyedDecodingContainer<SubRegion>) -> AWSRegionType? {
        guard let textRegionString = try? container.decodeIfPresent(String.self, forKey: .region) as NSString? else {
            return nil
        }
        return textRegionString.aws_regionTypeValue()
    }
}

extension TranslateTextConfiguration: Decodable {

    enum CodingKeys: String, CodingKey {
        case sourceLanguage = "sourceLang"
        case targetLanguage = "targetLang"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.sourceLanguage = try values.decode(LanguageType.self, forKey: .sourceLanguage)
        self.targetLanguage = try values.decode(LanguageType.self, forKey: .targetLanguage)
    }
}

extension LanguageType: Decodable {}

extension SpeechGeneratorConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case voiceID = "voice"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.voiceID = try values.decode(String.self, forKey: .voiceID)
    }
}

extension TranscriptionConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case language
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.language = try values.decode(LanguageType.self, forKey: .language)
    }
}

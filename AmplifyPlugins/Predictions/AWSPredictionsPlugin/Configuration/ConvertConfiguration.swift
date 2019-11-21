//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify

public struct ConvertConfiguration {
    public let region: AWSRegionType
    public var translateText: TranslateTextConfiguration?
    public var speechGenerator: SpeechGeneratorConfiguration?

    init(_ region: AWSRegionType) {
        self.region = region
        self.translateText = nil
        self.speechGenerator = nil
    }
}

public struct TranslateTextConfiguration {
    public let sourceLanguage: LanguageType
    public let targetLanguage: LanguageType
}

public struct SpeechGeneratorConfiguration {
    public let voiceID: String?
}

extension ConvertConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case translateText
        case speechGenerator
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
        case sourceLanguage
        case targetLanguage
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
        case voiceID = "voiceId"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.voiceID = try values.decode(String.self, forKey: .voiceID)
    }
}

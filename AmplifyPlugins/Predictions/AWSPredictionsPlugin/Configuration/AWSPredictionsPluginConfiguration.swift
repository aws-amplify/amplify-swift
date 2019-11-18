//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

public struct AWSPredictionsPluginConfiguration {
    public var identifyConfig: AWSIdentifyConfig?
    public var interpretConfig: AWSInterpretConfig?
    public var convertConfig: AWSConvertConfig?
    public var defaultProjectRegion: AWSRegionType

    public init(identifyConfig: AWSIdentifyConfig?,
                interpretConfig: AWSInterpretConfig?,
                convertConfig: AWSConvertConfig?,
                defaultProjectRegion: AWSRegionType) {
        self.identifyConfig = identifyConfig
        self.interpretConfig = interpretConfig
        self.convertConfig = convertConfig
        self.defaultProjectRegion = defaultProjectRegion
    }
}

public struct AWSIdentifyConfig {
    public var region: AWSRegionType
    public var collectionId: String?
    public var maxEntities: Int?
}

public struct AWSInterpretConfig {
    public var region: AWSRegionType
}

public struct AWSConvertConfig {
    public var region: AWSRegionType
    public var voiceId: String?
}

public extension AWSPredictionsPluginConfiguration {
    enum KeyName: String {
        case region
        case identify
        case convert
        case interpret
        case interpretText
        case translateText
        case identifyEntities
        case collectionId
        case maxFaces
        case speechGenerator
        case voiceId = "VoiceId"
        case defaultProjectRegion = "aws_project_region"
    }
}

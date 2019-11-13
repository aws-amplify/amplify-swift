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
}

public struct AWSIdentifyConfig {
    public var region: AWSRegionType
    public var collectionId: String?
    public var maxFaces: Int?
}

public struct AWSInterpretConfig {
    public var region: AWSRegionType
}

public struct AWSConvertConfig {
    public var region: AWSRegionType
}

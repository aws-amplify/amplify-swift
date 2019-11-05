//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

public struct PredictionsIdentifyRequest: AmplifyOperationRequest {
    public let options: IdentifyOptions
    public let image: CGImage
    public let identifyType: IdentifyType

    public init(image: CGImage, identifyType: IdentifyType, options: IdentifyOptions) {
        self.image = image
        self.identifyType = identifyType
        self.options = options
    }

    public struct IdentifyOptions {
        var callType: CallType = .auto
        var uploadToS3: Bool = false
    }

}


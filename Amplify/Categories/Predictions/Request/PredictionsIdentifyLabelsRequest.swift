//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

public struct PredictionsIdentifyLabelsRequest: AmplifyOperationRequest, PredictionsConvertRequest {

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options
    public let image: CGImage
    public let identifyType: IdentifyType
    public init(image: CGImage,
                identifyType: IdentifyType,
                options: Options) {
        self.image = image
        self.identifyType = identifyType
        self.options = options
    }
}

public extension PredictionsIdentifyLabelsRequest {

    struct Options {
        public let callType: CallType
        init(callType: CallType = .auto) {
            self.callType = callType
        }
    }
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

public struct PredictionsIdentifyLabelsRequest: AmplifyOperationRequest, PredictionsConvertRequest {

    /// Inpug image
    public let image: CGImage

    /// The type of identification to perform
    public let identifyType: IdentifyType

    /// Options to adjust the behavior of this request, including plugin options
    public let options: Options

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

        /// The calltype for the operation. The default value will be `auto`.
        public let callType: CallType

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(callType: CallType = .auto,
                    pluginOptions: Any? = nil) {
            self.callType = callType
            self.pluginOptions = pluginOptions
        }
    }
}

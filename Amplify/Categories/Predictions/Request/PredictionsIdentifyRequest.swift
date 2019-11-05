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
        /// The calltype for the operation. The default value will be `auto`.
        var callType: CallType
        
        /// if image needs to be uploaded to S3 before rekognition is called set to true. the default value will be `false`.
        var uploadToS3: Bool
        
        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(callType: CallType = .auto,
                    uploadToS3: Bool = false,
                    pluginOptions: Any? = nil) {
            self.callType = callType
            self.pluginOptions = pluginOptions
            self.uploadToS3 = uploadToS3
        }
    }

}


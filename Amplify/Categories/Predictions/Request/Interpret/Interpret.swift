//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

//public struct PredictionsInterpretRequest: AmplifyOperationRequest {
//
//    /// The text to be interpreted.
//    public let textToInterpret: String
//
//    /// Options to adjust the behavior of this request, including plugin options
//    public let options: Options
//
//    public init(textToInterpret: String,
//                options: Options) {
//        self.textToInterpret = textToInterpret
//        self.options = options
//    }
//}

public extension Predictions.Interpret {

    struct Options {

        /// The defaultNetworkPolicy for the operation. The default value will be `auto`.
        public let defaultNetworkPolicy: DefaultNetworkPolicy

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                    pluginOptions: Any? = nil) {
            self.defaultNetworkPolicy = defaultNetworkPolicy
            self.pluginOptions = pluginOptions
        }
    }
}

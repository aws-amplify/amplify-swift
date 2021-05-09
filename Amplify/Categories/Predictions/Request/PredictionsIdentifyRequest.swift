//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// <#Description#>
public struct PredictionsIdentifyRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let image: URL

    /// <#Description#>
    public let identifyType: IdentifyAction

    /// <#Description#>
    public let options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - image: <#image description#>
    ///   - identifyType: <#identifyType description#>
    ///   - options: <#options description#>
    public init(image: URL, identifyType: IdentifyAction, options: Options) {
        self.image = image
        self.identifyType = identifyType
        self.options = options
    }

}

public extension PredictionsIdentifyRequest {

    /// <#Description#>
    struct Options {
         /// The default NetworkPolicy for the operation. The default value will be `auto`.
        public let defaultNetworkPolicy: DefaultNetworkPolicy
        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        let pluginOptions: Any?

        /// <#Description#>
        /// - Parameters:
        ///   - defaultNetworkPolicy: <#defaultNetworkPolicy description#>
        ///   - uploadToRemote: <#uploadToRemote description#>
        ///   - pluginOptions: <#pluginOptions description#>
        public init(defaultNetworkPolicy: DefaultNetworkPolicy = .auto,
                    uploadToRemote: Bool = false,
                    pluginOptions: Any? = nil) {
            self.defaultNetworkPolicy = defaultNetworkPolicy
            self.pluginOptions = pluginOptions

        }
    }
}

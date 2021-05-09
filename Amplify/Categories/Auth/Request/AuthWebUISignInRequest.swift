//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// <#Description#>
public struct AuthWebUISignInRequest: AmplifyOperationRequest {

    /// <#Description#>
    public let presentationAnchor: AuthUIPresentationAnchor

    /// <#Description#>
    public let authProvider: AuthProvider?

    /// <#Description#>
    public var options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - presentationAnchor: <#presentationAnchor description#>
    ///   - authProvider: <#authProvider description#>
    ///   - options: <#options description#>
    public init(presentationAnchor: AuthUIPresentationAnchor,
                authProvider: AuthProvider? = nil,
                options: Options) {
        self.presentationAnchor = presentationAnchor
        self.authProvider = authProvider
        self.options = options
    }
}

public extension AuthWebUISignInRequest {

    /// <#Description#>
    struct Options {

        /// <#Description#>
        public let scopes: [String]?

        /// <#Description#>
        public let signInQueryParameters: [String: String]?

        /// <#Description#>
        public let signOutQueryParameters: [String: String]?

        /// <#Description#>
        public let tokenQueryParameters: [String: String]?

        /// <#Description#>
        public let pluginOptions: Any?

        /// <#Description#>
        /// - Parameters:
        ///   - scopes: <#scopes description#>
        ///   - signInQueryParameters: <#signInQueryParameters description#>
        ///   - signOutQueryParameters: <#signOutQueryParameters description#>
        ///   - tokenQueryParameters: <#tokenQueryParameters description#>
        ///   - pluginOptions: <#pluginOptions description#>
        public init(scopes: [String]? = nil,
                    signInQueryParameters: [String: String]? = nil,
                    signOutQueryParameters: [String: String]? = nil,
                    tokenQueryParameters: [String: String]? = nil,
                    pluginOptions: Any? = nil) {
            self.scopes = scopes
            self.signInQueryParameters = signInQueryParameters
            self.signOutQueryParameters = signOutQueryParameters
            self.tokenQueryParameters = tokenQueryParameters
            self.pluginOptions = pluginOptions
        }
    }
}

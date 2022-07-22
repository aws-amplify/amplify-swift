//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AuthenticationServices

/// Request for sign out user
public struct AuthSignOutRequest: AmplifyOperationRequest {

    /// Extra request options defined in `AuthSignOutRequest.Options`
    public var options: Options

    public init(options: Options) {

        self.options = options
    }
}

public extension AuthSignOutRequest {

    struct Options {

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying auth plugin functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public let globalSignOut: Bool

        public let presentationAnchorForWebUI: AuthUIPresentationAnchor?

        public init(globalSignOut: Bool = false,
                    presentationAnchor: AuthUIPresentationAnchor? = nil,
                    pluginOptions: Any? = nil) {
            self.globalSignOut = globalSignOut
            self.pluginOptions = pluginOptions
            self.presentationAnchorForWebUI = presentationAnchor
        }
    }


}

extension AuthSignOutRequest.Options {
    public static func presentationAnchor(_ anchor: AuthUIPresentationAnchor) -> AuthSignOutRequest.Options {
        return AuthSignOutRequest.Options(presentationAnchor: anchor)
    }
}

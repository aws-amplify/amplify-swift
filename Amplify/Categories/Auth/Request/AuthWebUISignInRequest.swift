//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

public struct AuthWebUISignInRequest: AmplifyOperationRequest {

    public let presentationAnchor: AuthUIPresentationAnchor

    public let authProvider: AuthProvider?

    public var options: Options

    public init(presentationAnchor: AuthUIPresentationAnchor,
                authProvider: AuthProvider? = nil,
                options: Options) {
        self.presentationAnchor = presentationAnchor
        self.authProvider = authProvider
        self.options = options
    }
}

public extension AuthWebUISignInRequest {

    struct Options {

        public let scopes: [String]?

        public let signInQueryParameters: [String: String]?

        public let signOutQueryParameters: [String: String]?

        public let tokenQueryParameters: [String: String]?

        public let pluginOptions: Any?

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

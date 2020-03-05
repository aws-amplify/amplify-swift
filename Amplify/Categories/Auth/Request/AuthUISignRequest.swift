//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

public struct AuthUISignInRequest: AmplifyOperationRequest {

    public var options: Options

    public init( options: Options) {

        self.options = options
    }
}

public extension AuthUISignInRequest {

    struct Options {
        public var navigationController: UINavigationController?
        public let validationData: [String: String]?
        public let metadata: [String: String]?

        public init(navigationController: UINavigationController? = nil,
                    validationData: [String: String]? = nil,
                    metadata: [String: String]? = nil) {
            self.navigationController = navigationController
            self.validationData = validationData
            self.metadata = metadata
        }
    }
}

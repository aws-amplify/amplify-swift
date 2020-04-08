//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthStateRequest: AmplifyOperationRequest {

    public var options: Options

    public init( options: Options) {

        self.options = options
    }
}

public extension AuthStateRequest {

    struct Options {
        public init() {
        }
    }
}

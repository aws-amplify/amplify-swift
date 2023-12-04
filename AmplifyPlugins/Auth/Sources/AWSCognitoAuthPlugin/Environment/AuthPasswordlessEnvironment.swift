//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AuthPasswordlessEnvironment: Environment {

    typealias AuthPasswordlessFactory = () throws -> AuthPasswordlessBehavior

    var authPasswordlessFactory: AuthPasswordlessFactory { get }
}

struct BasicPasswordlessEnvironment: AuthPasswordlessEnvironment {
    let authPasswordlessFactory: AuthPasswordlessFactory
}

extension AuthEnvironment: AuthPasswordlessEnvironment {
    var authPasswordlessFactory: AuthPasswordlessFactory {
        guard let authPasswordlessFactory = authPasswordlessEnvironment?.authPasswordlessFactory else {
            fatalError("Could not find auth passwordless environment")
        }
        return authPasswordlessFactory
    }
}

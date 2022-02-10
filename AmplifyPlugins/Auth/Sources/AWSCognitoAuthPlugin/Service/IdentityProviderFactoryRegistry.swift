//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol Keyed {
    var key: String { get }
}

extension SignUpEventData: Keyed {
    var key: String {
        "\(username)-\(password)"
    }
}

extension ConfirmSignUpEventData: Keyed {
    var key: String {
        "\(username)-\(confirmationCode)"
    }
}

/// Registry for use with unit tests to register service overrides.
class IdentityProviderFactoryRegistry {
    typealias IdentityProviderFactory = UserPoolEnvironment.CognitoUserPoolFactory

    private var registry: [String: IdentityProviderFactory]
    private let queue = DispatchQueue(label: "com.amazon.aws.amplify-identity", target: .global())

    static let shared = IdentityProviderFactoryRegistry()

    init() {
        registry = [:]
    }

    subscript(key: String) -> IdentityProviderFactory? {
        get {
            queue.sync {
                registry[key]
            }
        }
        set {
            queue.sync {
                registry[key] = newValue
            }
        }
    }

}

extension Action {

    func createIdentityProviderClient(key: String, environment: UserPoolEnvironment) throws -> CognitoUserPoolBehavior {
        let client: CognitoUserPoolBehavior
        if let clientFactory = IdentityProviderFactoryRegistry.shared[key] {
            client = try clientFactory()
        } else {
            client = try environment.cognitoUserPoolFactory()
        }

        return client
    }

}

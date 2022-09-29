//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import AWSCognitoAuthPlugin

class AnalyticsHandlerTests: XCTestCase {

    var credentialStoreEnvironment: CredentialStoreEnvironment {

        let mockLegacyKeychainStoreBehavior = MockKeychainStoreBehavior()
        let legacyKeychainStoreFactory: BasicCredentialStoreEnvironment.KeychainStoreFactory = { _ in
            return mockLegacyKeychainStoreBehavior
        }

        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return MockAmplifyCredentialStoreBehavior()
        }
        return BasicCredentialStoreEnvironment(
            amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
            legacyKeychainStoreFactory: legacyKeychainStoreFactory)
    }

}

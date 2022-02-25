//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import Combine

@testable import Amplify

// Models registration
extension AWSDataStoreMultiAuthSingleRuleTests {
    struct UserPoolsOwnerModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerUPPost.self)
        }
    }

    struct UserPoolsGroupModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupUPPost.self)
        }
    }

    struct UserPoolsPrivateModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivateUPPost.self)
        }
    }

    struct IAMPrivateModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivateIAMPost.self)
        }
    }

    struct OIDCOwnerModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerOIDCPost.self)
        }
    }

    struct IAMPublicModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicIAMPost.self)
        }
    }

    struct APIKeyPublicModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicAPIPost.self)
        }
    }
}

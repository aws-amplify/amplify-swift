//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import XCTest

@testable import Amplify

// Models registration
extension AWSDataStoreMultiAuthSingleRuleTests {
    struct UserPoolsOwnerModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerUPPost.self)
        }
    }

    struct UserPoolsGroupModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupUPPost.self)
        }
    }

    struct UserPoolsPrivateModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivateUPPost.self)
        }
    }

    struct IAMPrivateModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivateIAMPost.self)
        }
    }

    struct OIDCOwnerModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerOIDCPost.self)
        }
    }

    struct IAMPublicModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicIAMPost.self)
        }
    }

    struct APIKeyPublicModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicAPIPost.self)
        }
    }
}

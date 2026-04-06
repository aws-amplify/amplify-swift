//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSDataStoreMultiAuthTwoRulesTests {
    struct OwnerPrivateUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPrivateUPIAMPost.self)
        }
    }

    struct OwnerPublicUserPoolsAPIModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicUPAPIPost.self)
        }
    }

    struct OwnerPublicUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicUPIAMPost.self)
        }
    }

    struct OwnerPublicOIDCAPIModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicOIDAPIPost.self)
        }
    }

    struct GroupPrivateUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPrivateUPIAMPost.self)
        }
    }

    struct GroupPublicUserPoolsAPIModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPublicUPAPIPost.self)
        }
    }

    struct GroupPublicUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPublicUPIAMPost.self)
        }
    }

    struct PrivateUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePrivateUPIAMPost.self)
        }
    }

    struct PrivatePublicUserPoolsAPIModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicUPAPIPost.self)
        }
    }

    struct PrivatePublicUserPoolsIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicUPIAMPost.self)
        }
    }

    struct PrivatePublicIAMAPIModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicIAMAPIPost.self)
        }
    }

    struct PublicPublicAPIIAMModels: AmplifyModelRegistration {
        let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicPublicIAMAPIPost.self)
        }
    }
}

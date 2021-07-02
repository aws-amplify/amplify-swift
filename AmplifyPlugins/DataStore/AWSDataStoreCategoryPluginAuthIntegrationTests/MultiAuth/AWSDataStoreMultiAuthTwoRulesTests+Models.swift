//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSDataStoreMultiAuthTwoRulesTests {
    struct OwnerPrivateUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPrivateUPIAMPost.self)
        }
    }

    struct OwnerPublicUserPoolsAPIModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicUPAPIPost.self)
        }
    }

    struct OwnerPublicUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicUPIAMPost.self)
        }
    }

    struct OwnerPublicOIDCAPIModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPublicOIDAPIPost.self)
        }
    }

    struct GroupPrivateUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPrivateUPIAMPost.self)
        }
    }

    struct GroupPublicUserPoolsAPIModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPublicUPAPIPost.self)
        }
    }

    struct GroupPublicUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPublicUPIAMPost.self)
        }
    }

    struct PrivateUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePrivateUPIAMPost.self)
        }
    }

    struct PrivatePublicUserPoolsAPIModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicUPAPIPost.self)
        }
    }

    struct PrivatePublicUserPoolsIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicUPIAMPost.self)
        }
    }

    struct PrivatePublicIAMAPIModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicIAMAPIPost.self)
        }
    }

    struct PublicPublicAPIIAMModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PublicPublicIAMAPIPost.self)
        }
    }
}

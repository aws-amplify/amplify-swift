//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import Amplify

extension AWSDataStoreMultiAuthThreeRulesTests {
    struct OwnerPrivatePublicUserPoolsAPIKeyModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: OwnerPrivatePublicUPIAMAPIPost.self)
        }
    }

    struct GroupPrivatePublicUserPoolsAPIKeyModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: GroupPrivatePublicUPIAMAPIPost.self)
        }
    }

    struct PrivatePrivatePublicUserPoolsIAMIAM: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePrivatePublicUPIAMIAMPost.self)
        }
    }

    struct PrivatePrivatePublicUserPoolsIAMAPiKey: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePrivatePublicUPIAMAPIPost.self)
        }
    }

    struct PrivatePublicPublicUserPoolsAPIKeyIAM: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicPublicUPAPIIAMPost.self)
        }
    }
}

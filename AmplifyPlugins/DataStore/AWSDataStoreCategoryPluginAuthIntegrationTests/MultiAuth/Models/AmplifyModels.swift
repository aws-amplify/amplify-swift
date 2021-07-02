//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.

final public class MultiAuthModels: AmplifyModelRegistration {
  public let version: String = "56b0ba175531f2b8bd0317d5984a7feb"

  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: OwnerUPPost.self)
    ModelRegistry.register(modelType: OwnerOIDCPost.self)
    ModelRegistry.register(modelType: GroupUPPost.self)
    ModelRegistry.register(modelType: PrivateUPPost.self)
    ModelRegistry.register(modelType: PrivateIAMPost.self)
    ModelRegistry.register(modelType: PublicIAMPost.self)
    ModelRegistry.register(modelType: PublicAPIPost.self)
    ModelRegistry.register(modelType: OwnerPrivateUPIAMPost.self)
    ModelRegistry.register(modelType: OwnerPublicUPAPIPost.self)
    ModelRegistry.register(modelType: OwnerPublicUPIAMPost.self)
    ModelRegistry.register(modelType: OwnerPublicOIDAPIPost.self)
    ModelRegistry.register(modelType: GroupPrivateUPIAMPost.self)
    ModelRegistry.register(modelType: GroupPublicUPAPIPost.self)
    ModelRegistry.register(modelType: GroupPublicUPIAMPost.self)
    ModelRegistry.register(modelType: PrivatePrivateUPIAMPost.self)
    ModelRegistry.register(modelType: PrivatePublicUPAPIPost.self)
    ModelRegistry.register(modelType: PrivatePublicUPIAMPost.self)
    ModelRegistry.register(modelType: PrivatePublicIAMAPIPost.self)
    ModelRegistry.register(modelType: PublicPublicIAMAPIPost.self)
    ModelRegistry.register(modelType: OwnerPrivatePublicUPIAMAPIPost.self)
    ModelRegistry.register(modelType: GroupPrivatePublicUPIAMAPIPost.self)
    ModelRegistry.register(modelType: PrivatePrivatePublicUPIAMIAMPost.self)
    ModelRegistry.register(modelType: PrivatePrivatePublicUPIAMAPIPost.self)
    ModelRegistry.register(modelType: PrivatePublicPublicUPAPIIAMPost.self)
    ModelRegistry.register(modelType: PrivatePublicComboUPPost.self)
    ModelRegistry.register(modelType: PrivatePublicComboAPIPost.self)
  }
}

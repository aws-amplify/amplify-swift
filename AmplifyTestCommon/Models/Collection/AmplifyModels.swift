//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "a9d41db3823520a5379fa5f3bfe84fae"

  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Project1.self)
    ModelRegistry.register(modelType: Team1.self)
    ModelRegistry.register(modelType: Project2.self)
    ModelRegistry.register(modelType: Team2.self)
    ModelRegistry.register(modelType: Post3.self)
    ModelRegistry.register(modelType: Comment3.self)
    ModelRegistry.register(modelType: Post4.self)
    ModelRegistry.register(modelType: Comment4.self)
    ModelRegistry.register(modelType: Post5.self)
    ModelRegistry.register(modelType: PostEditor5.self)
    ModelRegistry.register(modelType: User5.self)
  }
}

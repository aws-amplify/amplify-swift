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

final public class AmplifyModels: AmplifyModelRegistration {
    public let version: String

    public init(version: String = "46369a50a95486d76713fd33833fb782") {
        self.version = version
    }

    public func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: User.self)
        ModelRegistry.register(modelType: UserFollowers.self)
        ModelRegistry.register(modelType: UserFollowing.self)
    }
}

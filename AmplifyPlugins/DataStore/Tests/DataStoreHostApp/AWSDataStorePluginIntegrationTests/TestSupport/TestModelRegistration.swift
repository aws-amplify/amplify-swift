//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon

struct TestModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {
        registry.register(modelType: Post.self)
        registry.register(modelType: Comment.self)
        registry.register(modelType: Project1.self)
        registry.register(modelType: Team1.self)
        registry.register(modelType: Project2.self)
        registry.register(modelType: Team2.self)
        registry.register(modelType: Post3.self)
        registry.register(modelType: Comment3.self)
        registry.register(modelType: Post4.self)
        registry.register(modelType: Comment4.self)
        registry.register(modelType: Post5.self)
        registry.register(modelType: PostEditor5.self)
        registry.register(modelType: User5.self)
        registry.register(modelType: Blog6.self)
        registry.register(modelType: Post6.self)
        registry.register(modelType: Comment6.self)
        registry.register(modelType: ScalarContainer.self)
        registry.register(modelType: ListIntContainer.self)
        registry.register(modelType: ListStringContainer.self)
        registry.register(modelType: EnumTestModel.self)
        registry.register(modelType: NestedTypeTestModel.self)
        registry.register(modelType: CustomerOrder.self)
    }

    let version: String = "1"

}

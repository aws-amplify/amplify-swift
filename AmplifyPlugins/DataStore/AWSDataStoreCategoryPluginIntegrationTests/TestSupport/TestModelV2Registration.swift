//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon

struct TestModelV2Registration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {
        registry.register(modelType: Project1V2.self)
        registry.register(modelType: Team1V2.self)
        registry.register(modelType: Project2V2.self)
        registry.register(modelType: Team2V2.self)
        registry.register(modelType: Post3aV2.self)
        registry.register(modelType: Comment3aV2.self)
        registry.register(modelType: Post3V2.self)
        registry.register(modelType: Comment3V2.self)
        registry.register(modelType: Post4V2.self)
        registry.register(modelType: Comment4V2.self)
        registry.register(modelType: Post5V2.self)
        registry.register(modelType: PostEditor5V2.self)
        registry.register(modelType: User5V2.self)
        registry.register(modelType: Blog6V2.self)
        registry.register(modelType: Post6V2.self)
        registry.register(modelType: Comment6V2.self)
        registry.register(modelType: Blog7V2.self)
        registry.register(modelType: Post7V2.self)
        registry.register(modelType: Comment7V2.self)
        registry.register(modelType: Meeting8V2.self)
        registry.register(modelType: Attendee8V2.self)
        registry.register(modelType: Registration8V2.self)

        registry.register(modelType: CustomerSecondaryIndexV2.self)
        registry.register(modelType: TodoWithDefaultValueV2.self)
        registry.register(modelType: TodoCustomTimestampV2.self)
    }

    let version: String = "1"

}

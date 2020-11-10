//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon
import Foundation

struct TestModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {
        // Post and Comment
        registry.register(modelType: Post.self)
        registry.register(modelType: Comment.self)

        // Mock Models
        registry.register(modelType: MockSynced.self)
        registry.register(modelType: MockUnsynced.self)

        // Models for data conversion testing
        registry.register(modelType: ExampleWithEveryType.self)
    }

    let version: String = "1"

}

struct TestJsonModelRegistration: AmplifyModelRegistration {

    func registerModels(registry: ModelRegistry.Type) {

        // Post
        let id = ModelFieldDefinition.id("id").modelField
        let title = ModelField(name: "title", type: .string, isRequired: true)
        let content = ModelField(name: "content", type: .string, isRequired: true)
        let createdAt = ModelField(name: "createdAt", type: .string, isRequired: true)
        let updatedAt = ModelField(name: "updatedAt", type: .string)
        let draft = ModelField(name: "draft", type: .bool, isRequired: false)
        let rating = ModelField(name: "rating", type: .double, isRequired: false)
        let status = ModelField(name: "status", type: .string, isRequired: false)
        let comments = ModelField(name: "comments",
                                  type: .collection(of: "Comment"),
                                  isRequired: false,
                                  association: .hasMany(associatedFieldName: "post"))
        let postSchema = ModelSchema(name: "Post",
                                     pluralName: "Posts",
                                     fields: [id.name: id,
                                              title.name: title,
                                              content.name: content,
                                              createdAt.name: createdAt,
                                              updatedAt.name: updatedAt,
                                              draft.name: draft,
                                              rating.name: rating,
                                              status.name: status,
                                              comments.name: comments])

        ModelRegistry.register(modelType: DynamicModel.self, modelSchema: postSchema) { (_, _) -> Model in
            DynamicModel(id: "", values: [:])
        }

        // Comment

        let commentId = ModelFieldDefinition.id().modelField
        let commentContent = ModelField(name: "content", type: .string, isRequired: true)
        let commentCreatedAt = ModelField(name: "createdAt", type: .dateTime, isRequired: true)
        let belongsTo = ModelField(name: "post",
                                   type: .model(name: "Post"),
                                   isRequired: true,
                                   association: .belongsTo(associatedWith: nil, targetName: "postId"))
        let commentSchema = ModelSchema(name: "Comment",
                                        pluralName: "Comments",
                                        fields: [
                                            commentId.name: commentId,
                                            commentContent.name: commentContent,
                                            commentCreatedAt.name: commentCreatedAt,
                                            belongsTo.name: belongsTo])
        ModelRegistry.register(modelType: DynamicModel.self, modelSchema: commentSchema
        ) { (_, _) -> Model in
            DynamicModel(id: "", values: [:])
        }
    }

    let version: String = "1"

}

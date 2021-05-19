//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with the value of `Model.Identifier` for a "delete" mutation with custom primary keys
public struct ModelDeleteDecorator: ModelBasedGraphQLDocumentDecorator {

    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .mutation = document.operationType {
            if let customPrimaryKeys = modelSchema.customPrimaryIndexFields {
                var objectMap = [String: Any?]()
                // let graphQLInput = model.graphQLInputForMutation(modelSchema)
                for key in customPrimaryKeys {
                    objectMap[key] = model[key]
                }
                inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                       value: .object(objectMap))

            } else {
                inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                       value: .object(["id": model.id]))
            }
        } else if case .query = document.operationType {
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .scalar(model.id))
        }

        return document.copy(inputs: inputs)
    }
}

// GraphQL Document
// create
/*
 createMutation(input: CreateInput) {
   createTodo {
     orderid
     id
     email
   }
 }
 variables = {
    // all the fields
    orderid: UUID
    id =
 }
 */

// update
/*
 updateMutation(input: UpdateInput) {
   createTodo {
     orderid
     id
     email
   }
 }
 variables = {
    // all the fields
    orderid: UUID
    id =
 }
 */


// delete
/*
 deleteMutation(input: DeleteInput) {
   createTodo {
     orderid
     id
     email
   }
 }
 variables = {
    // default
    id: 123
 
    // custom primary 1
    orderid: "123"
 
    // custom primary 2
    orderId
    id
 }
 
 // query (get by id)
  // to verify: Q. what is the id used for querying
 # custom priamry 1
 query MyQuery {
   getBlog6(orderid: "")
 }

 #custom primary 2
 query MyQuery {
   getBlog6(orderid: "", id: "")
 }
 
 // list
 listQuery
 // possibly not much to do here
 */










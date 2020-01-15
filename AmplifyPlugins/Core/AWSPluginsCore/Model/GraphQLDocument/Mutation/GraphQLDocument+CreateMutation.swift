//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLCreateMutation {
    convenience init(of anyModel: AnyModel,
                     where predicate: QueryPredicate? = nil) {
        self.init(of: anyModel.instance)
    }
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public class GraphQLCreateMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let mutationType = GraphQLMutationType.create
    public let model: Model
    public let modelType: Model.Type

    public init(of model: Model) {
        self.model = model
        self.modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
    }

    public var name: String {
        mutationType.rawValue + model.schema.graphQLName
    }

    public var inputTypes: String? {
        "$input: \(name.pascalCased())Input!"
    }

    public var inputParameters: String? {
        "input: $input"
    }

    public var variables: [String: Any] {
        var variables = [String: Any]()

        variables.updateValue(model.graphQLInput, forKey: "input")

        return variables
    }
}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public typealias SyncQueryResult = PaginatedList<AnyModel>
public typealias MutationSyncResult = MutationSync<AnyModel>

/// Extension methods that are useful for `DataStore`. The methods consist of conflict resolution related fields such
/// as `version` and `lastSync` and returns a model that has been erased to `AnyModel`.
extension GraphQLRequest {

    public static func createMutation(of model: Model,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        createOrUpdateMutation(of: model, type: .create, version: version)
    }

    public static func updateMutation(of model: Model,
                                      where predicate: QueryPredicate? = nil,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        createOrUpdateMutation(of: model, type: .update, version: version)
    }

    public static func deleteMutation(modelName: String,
                                      id: Model.Identifier,
                                      where predicate: QueryPredicate? = nil,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: id))
        if let predicate = predicate {
            documentBuilder.add(decorator: PredicateDecorator(predicate: predicate))
        }
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: version))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                  variables: document.variables,
                                                  responseType: MutationSyncResult.self,
                                                  decodePath: document.name)
    }

    public static func subscription(to modelType: Model.Type,
                                    subscriptionType: GraphQLSubscriptionType) -> GraphQLRequest<MutationSyncResult> {

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: subscriptionType))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                  responseType: MutationSyncResult.self,
                                                  decodePath: document.name)
    }

    public static func syncQuery(modelType: Model.Type,
                                 where predicate: QueryPredicate? = nil,
                                 limit: Int? = nil,
                                 nextToken: String? = nil,
                                 lastSync: Int? = nil) -> GraphQLRequest<SyncQueryResult> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        if let predicate = predicate {
            documentBuilder.add(decorator: PredicateDecorator(predicate: predicate))
        }
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        let document = documentBuilder.build()

        return GraphQLRequest<SyncQueryResult>(document: document.stringValue,
                                               variables: document.variables,
                                               responseType: SyncQueryResult.self,
                                               decodePath: document.name)
    }

    // MARK: Private methods

    private static func createOrUpdateMutation(of model: Model,
                                               where predicate: QueryPredicate? = nil,
                                               type: GraphQLMutationType,
                                               version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: model.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: type))
        documentBuilder.add(decorator: ModelDecorator(model: model))
        if let predicate = predicate {
            documentBuilder.add(decorator: PredicateDecorator(predicate: predicate))
        }
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: version))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                  variables: document.variables,
                                                  responseType: MutationSyncResult.self,
                                                  decodePath: document.name)
    }
}

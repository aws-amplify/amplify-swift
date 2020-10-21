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

/// TODO document this and change it to work in a way that these functions are not
/// publicly exposed to developers
protocol ModelSyncGraphQLRequestFactory {

    static func query(modelName: String, byId id: String) -> GraphQLRequest<MutationSyncResult?>

    static func createMutation(of model: Model,
                               version: Int?) -> GraphQLRequest<MutationSyncResult>

    static func updateMutation(of model: Model,
                               where filter: GraphQLFilter?,
                               version: Int?) -> GraphQLRequest<MutationSyncResult>

    static func deleteMutation(modelName: String,
                               id: Model.Identifier,
                               where filter: GraphQLFilter?,
                               version: Int?) -> GraphQLRequest<MutationSyncResult>

    static func subscription(to modelType: Model.Type,
                             subscriptionType: GraphQLSubscriptionType) -> GraphQLRequest<MutationSyncResult>

    static func subscription(to modelType: Model.Type,
                             subscriptionType: GraphQLSubscriptionType,
                             claims: IdentityClaimsDictionary) -> GraphQLRequest<MutationSyncResult>

    static func syncQuery(modelType: Model.Type,
                          where predicate: QueryPredicate?,
                          limit: Int?,
                          nextToken: String?,
                          lastSync: Int?) -> GraphQLRequest<SyncQueryResult>

}

/// Extension methods that are useful for `DataStore`. The methods consist of conflict resolution related fields such
/// as `version` and `lastSync` and returns a model that has been erased to `AnyModel`.
extension GraphQLRequest: ModelSyncGraphQLRequestFactory {

    public static func query(modelName: String, byId id: String) -> GraphQLRequest<MutationSyncResult?> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult?>(document: document.stringValue,
                                                   variables: document.variables,
                                                   responseType: MutationSyncResult?.self,
                                                   decodePath: document.name)
    }

    public static func createMutation(of model: Model,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        createOrUpdateMutation(of: model, type: .create, version: version)
    }

    public static func updateMutation(of model: Model,
                                      where filter: GraphQLFilter? = nil,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        createOrUpdateMutation(of: model, where: filter, type: .update, version: version)
    }

    public static func deleteMutation(modelName: String,
                                      id: Model.Identifier,
                                      where filter: GraphQLFilter? = nil,
                                      version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: modelName, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: id))
        if let filter = filter {
            documentBuilder.add(decorator: FilterDecorator(filter: filter))
        }
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: version))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
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
                                                  variables: document.variables,
                                                  responseType: MutationSyncResult.self,
                                                  decodePath: document.name)
    }

    public static func subscription(to modelType: Model.Type,
                                    subscriptionType: GraphQLSubscriptionType,
                                    claims: IdentityClaimsDictionary) -> GraphQLRequest<MutationSyncResult> {

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: subscriptionType))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(subscriptionType, claims)))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                  variables: document.variables,
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
            documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        }
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()

        return GraphQLRequest<SyncQueryResult>(document: document.stringValue,
                                               variables: document.variables,
                                               responseType: SyncQueryResult.self,
                                               decodePath: document.name)
    }

    // MARK: Private methods

    private static func createOrUpdateMutation(of model: Model,
                                               where filter: GraphQLFilter? = nil,
                                               type: GraphQLMutationType,
                                               version: Int? = nil) -> GraphQLRequest<MutationSyncResult> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: model.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: type))
        documentBuilder.add(decorator: ModelDecorator(model: model))
        if let filter = filter {
            documentBuilder.add(decorator: FilterDecorator(filter: filter))
        }
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: version))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                  variables: document.variables,
                                                  responseType: MutationSyncResult.self,
                                                  decodePath: document.name)
    }
}

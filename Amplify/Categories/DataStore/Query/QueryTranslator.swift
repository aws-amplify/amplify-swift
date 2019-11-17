//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Classes conforming to this protocol are responsible for translating `ModelSchema` and `QueryPredicate`
/// types to platform-specific query language.
///
/// **Note**: It is OK for implementations to call `preconditionFailure` if a specific operation is
/// not supported. Consumers of concrete types of this protocol must be aware of the supported features.
public protocol QueryTranslator {

    associatedtype Value

    /// Translate a modelType reference to a `delete`-type operation with the specified predicate.
    /// - Parameter modelType: the model type
    /// - Parameter predicate: the optional predicate with condition operations
    /// - Returns: a `Query` object that contains the query as string and the associated values
    func translateToDelete(from modelType: Model.Type,
                           predicate: QueryPredicate?) -> Query<Value>

    /// Translate a model reference to a `insert`-type operation.
    /// - Parameter model: the model instance
    /// - Returns: a `Query` object that contains the query as string and the associated values
    func translateToInsert(from model: Model) -> Query<Value>

    /// Translate a model reference to a `query`-type operation.
    /// - Parameter modelType: the model type
    /// - Parameter predicate: the optional predicate with condition operations
    /// - Returns: a `Query` object that contains the query as string and the associated values
    func translateToQuery(from modelType: Model.Type,
                          predicate: QueryPredicate?) -> Query<Value>

    /// Translate a model reference to a `update`-type operation.
    /// - Parameter model: the model instance
    /// - Returns: a `Query` object that contains the query as string and the associated values
    func translateToUpdate(from model: Model) -> Query<Value>

}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

enum GraphQLDocumentType: String {
    case mutation
    case query
    case subscription
}

/// Represents a GraphQL document. Concrete types that conform to this protocol must
/// define a valid GraphQL operation document.
///
/// This type aims to provide an integration between GraphQL and an Amplify `Model`.
/// Therefore, documents represented by concrete implementations provide a single GraphQL
/// operation based on a defined `Model`.
protocol GraphQLDocument {
    associatedtype M: Model

    /// The `GraphQLDocumentType` a concrete implementation represents the
    /// GraphQL operation of the document
    var documentType: GraphQLDocumentType { get }

    /// The `Model` type associated with the document
    var modelType: M.Type { get }

    /// The raw representation of the GraphQL document. This can be used to submit
    /// a `GraphQLRequest` using API operations like `query`, `mutate` and `subscribe`.
    var stringValue: String { get }
}

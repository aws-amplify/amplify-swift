//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum GraphQLDocumentType: String {
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
public protocol GraphQLDocument {
    associatedtype M: Model

    /// The `GraphQLDocumentType` a concrete implementation represents the
    /// GraphQL operation of the document
    var documentType: GraphQLDocumentType { get }

    /// The name of the document. This is useful to inspect the response, since it will
    /// contain the name of the document as the key to the response value.
    var name: String { get }

    /// The `Model` type associated with the document
    var modelType: M.Type { get }

    /// The raw representation of the GraphQL document. This can be used to submit
    /// a `GraphQLRequest` using API operations like `query`, `mutate` and `subscribe`.
    var stringValue: String { get }
}

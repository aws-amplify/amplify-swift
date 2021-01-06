//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension AnyModel {
    /// Initializes an AnyModel instance from incoming JSONValue. The JSONValue is expected to be provided by the AWS
    /// service. Specifically, it must have a `__typename` property that corresponds to a Model registered in
    /// `ModelRegistry`, and the schemas must match.
    init(modelJSON: JSONValue) throws {

        guard case .string(let typename) = modelJSON["__typename"] else {
            throw APIError.operationError(
                "Could not retrieve __typename from object",
                """
                Could not retrieve the `__typename` attribute from the return value. Be sure to include __typename in \
                the selection set of the GraphQL operation. GraphQL:
                \(modelJSON)
                """
            )
        }

        guard let underlyingModelData = try? JSONEncoder().encode(modelJSON),
            let underlyingModelString = String(data: underlyingModelData, encoding: .utf8) else {
            throw APIError.operationError(
                "Could not convert model data to string",
                """
                Could not convert the \(typename) model data to a JSONString. Inspect the model data below and ensure \
                it does not contain any invalid UTF8 data. Model:

                \(modelJSON)
                """
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy

        let model = try ModelRegistry.decode(modelName: typename,
                                             from: underlyingModelString,
                                             jsonDecoder: decoder)

        self.init(model)
    }
}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension GraphQLResponseDecoder {

    static func decodeToAppSyncList<R: Decodable>(responseData: R,
                                                  responseType: R.Type,
                                                  graphQLData: JSONValue,
                                                  document: String? = nil,
                                                  variables: [String: Any]? = nil) throws -> R {
        if responseData is ModelListMarker, let document = document {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let payload: AppSyncListPayload
            if let variables = variables {
                let variablesData = try JSONSerialization.data(withJSONObject: variables)
                let variablesJSON = try decoder.decode([String: JSONValue].self, from: variablesData)
                payload = AppSyncListPayload(document: document,
                                             variables: variablesJSON,
                                             graphQLData: graphQLData)
            } else {
                payload = AppSyncListPayload(document: document,
                                             graphQLData: graphQLData)
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            let encodedData = try encoder.encode(payload)
            return try decoder.decode(responseType, from: encodedData)
        }

        return responseData
    }
}

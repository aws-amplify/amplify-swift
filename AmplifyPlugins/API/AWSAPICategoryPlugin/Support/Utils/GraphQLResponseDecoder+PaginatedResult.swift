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

    static func decodeToPaginatedResult<R: Decodable>(responseData: R,
                                                         responseType: R.Type,
                                                         graphQLData: JSONValue) throws -> R {
        if responseData is PaginatedResultP {
            let jsonValueContainer = ["__data": graphQLData,
                                      "__request": ["document": "documentString",
                                                    "variables": ["key": "value"]]]
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            let encodedData =  try encoder.encode(jsonValueContainer)
            let response = try decoder.decode(responseType, from: encodedData)
            return response
        } else {
            return responseData
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class GraphQLOperationRequestUtils {

    // Get the graphQL request payload from the query document and variables
    static func getQueryDocument(document: String, variables: [String: Any]?) -> [String: Any] {
        var queryDocument = ["query": document] as [String: Any]
        if let variables = variables {
            queryDocument["variables"] = variables
        }

        return queryDocument
    }

    // Construct a graphQL specific HTTP POST request with the request payload
    static func constructRequest(with baseUrl: URL, requestPayload: Data) -> URLRequest {
        var baseRequest = URLRequest(url: baseUrl)
        baseRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        baseRequest.setValue("no-store", forHTTPHeaderField: "cache-control")
        baseRequest.httpMethod = "POST"
        baseRequest.httpBody = requestPayload

        return baseRequest
    }
}

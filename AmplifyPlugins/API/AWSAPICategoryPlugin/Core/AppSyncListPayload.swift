//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct AppSyncListPayload: Codable {
    let document: String
    let variables: [String: JSONValue]?
    private let graphQLData: JSONValue

    public init(document: String, variables: [String: JSONValue]? = nil, graphQLData: JSONValue) {
        self.document = document
        self.variables = variables
        self.graphQLData = graphQLData
    }

    func getNextToken() -> String? {
        if case let .string(nextToken) = graphQLData["nextToken"] {
            return nextToken
        }
        return nil
    }

    func getItems() -> [JSONValue] {
        if case let .array(jsonArray) = graphQLData["items"] {
            return jsonArray
        }
        return []
    }
}

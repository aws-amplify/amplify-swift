//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AppSyncList: Paginatable {

    public typealias Page = AppSyncList<ModelType>
    public typealias PageError = APIError

    public func next(onComplete: @escaping PageResult) {
        guard let nextToken = nextToken, let document = document else {
            onComplete(.failure(APIError.operationError("Missing next Token", "check hasNext()")))
            return
        }

        let updatedVariables: [String: JSONValue]
        if var storedVariables = variables {
            storedVariables.updateValue(.string(nextToken), forKey: "nextToken")
            updatedVariables = storedVariables
        } else {
            updatedVariables = ["nextToken": .string(nextToken)]
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        guard let variablesData = try? encoder.encode(updatedVariables),
              let variablesJSON = try? JSONSerialization.jsonObject(with: variablesData) as? [String: Any] else {
            onComplete(.failure(APIError.operationError("Could not serialize request", "")))
            return
        }

        let request = GraphQLRequest<AppSyncList<ModelType>>(document: document,
                                                             variables: variablesJSON,
                                                             responseType: AppSyncList<ModelType>.self)
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let list):
                    onComplete(.success(list))
                case .failure(let graphQLError):
                    onComplete(.failure(APIError(error: graphQLError)))
                }
            case .failure(let apiError):
                onComplete(.failure(apiError))
            }
        }
    }

    public func hasNext() -> Bool {
        return nextToken != nil
    }
}

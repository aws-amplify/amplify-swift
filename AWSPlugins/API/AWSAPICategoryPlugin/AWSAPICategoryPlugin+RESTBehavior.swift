//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func get(apiName: String,
             path: String,
             listener: APIOperation.EventListener?) -> APIOperation {

        let apiGetRequest = APIGetRequest(apiName: apiName,
                                          path: path,
                                          options: APIGetRequest.Options())

        let operation = AWSAPIOperation(request: apiGetRequest,
                                        eventName: HubPayload.EventName.API.get,
                                        listener: listener)

        let url: URL
        do {
            url = try urlForAPIName(apiName, path: path)
        } catch {
            if let apiError = error as? APIError {
                operation.dispatch(event: APIOperation.Event.failed(apiError))
            } else {
                // Should never happen, if we properly return APIErrors from `urlForAPIName`
                let apiError = APIError.unknown(
                    "Unable to get a URL for \(apiName)",
                    """
                    Review your API plugin configuration and ensure \(apiName) has a valid URL for the 'Endpoint' \
                    field.
                    """
                )
                operation.dispatch(event: APIOperation.Event.failed(apiError))
            }
            return operation
        }

        let request = URLRequest(url: url)

        let task = session.dataTaskBehavior(with: request)

        mapper.addPair(operation: operation, task: task)

        task.resume()

        return operation
    }

    private func urlForAPIName(_ apiName: String, path: String) throws -> URL {
        guard let baseURL = pluginConfig.endpoints[apiName]?.baseURL else {
            throw APIError.invalidURL(
                "No URL for \(apiName)",
                "Review your API plugin configuration and ensure \(apiName) has a valid URL for the 'Endpoint' field."
            )
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL(
                "Invalid URL for \(apiName)",
                "Review your API plugin configuration and ensure \(apiName) has a valid URL for the 'Endpoint' field."
            )
        }

        if components.path.isEmpty {
            components.path = path
        } else {
            components.path.append(path)
        }

        guard let url = components.url else {
            throw APIError.invalidURL(
                "Invalid URL for \(apiName)",
                """
                Review your API plugin configuration and ensure \(apiName) has a valid URL for the 'Endpoint' field, \
                and make sure to pass a valid path in your request. The value passed was '\(path)'.
                """
            )
        }

        return url
    }

}

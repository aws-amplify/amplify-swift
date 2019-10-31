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

        let request: URLRequest
        do {
            request = try makeRequestForAPIName(apiName, path: path)
        } catch let error as APIError {
            operation.dispatch(event: APIOperation.Event.failed(error))
            return operation
        } catch let error as AmplifyError {
            let apiError = APIError.unknown(error.errorDescription, error.recoverySuggestion)
            operation.dispatch(event: APIOperation.Event.failed(apiError))
            return operation
        } catch {
            let apiError = APIError.unknown(error.localizedDescription, "")
            operation.dispatch(event: APIOperation.Event.failed(apiError))
            return operation
        }

        let task = session.dataTaskBehavior(with: request)

        mapper.addPair(operation: operation, task: task)

        task.resume()

        return operation
    }

    private func makeRequestForAPIName(_ apiName: String, path: String) throws -> URLRequest {
        guard let endpointConfig = pluginConfig.endpoints[apiName] else {
            let error = APIError.invalidConfiguration(
                "Unable to get an endpoint configuration for \(apiName)",
                """
                Review your API plugin configuration and ensure \(apiName) has a valid configuration.
                """
            )
            throw error
        }

        let url = try urlForAPIName(apiName, path: path)

        let baseRequest = URLRequest(url: url)

        let finalRequest = endpointConfig.interceptors.reduce(baseRequest) { $1.intercept($0) }

        return finalRequest
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

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSAPIOperation: AmplifyOperation<APIRequest,
    Void,
    Data,
    APIError
    >,
APIOperation {

    // Data received by the operation
    var data = Data()

    let session: URLSessionBehavior
    var mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration

    init(request: APIRequest,
         eventName: String,
         listener: AWSAPIOperation.EventListener?,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig

        super.init(categoryType: .api,
                   eventName: eventName,
                   request: request,
                   listener: listener)

    }

    /// The work to execute for this operation
    override public func main() {
        if isCancelled {
            finish()
            return
        }
        let urlRequest: URLRequest
        do {
            urlRequest = try makeRequestForAPIName(request.apiName,
                                                   operationType: request.operationType,
                                                   path: request.path)
            let task = session.dataTaskBehavior(with: urlRequest)
            mapper.addPair(operation: self, task: task)

            task.resume()
        } catch let error as APIError {
            dispatch(event: APIOperation.Event.failed(error))
            finish()
        } catch let error as AmplifyError {
            let apiError = APIError.unknown(error.errorDescription, error.recoverySuggestion)
            dispatch(event: APIOperation.Event.failed(apiError))
            finish()
        } catch {
            let apiError = APIError.unknown(error.localizedDescription, "")
            dispatch(event: APIOperation.Event.failed(apiError))
            finish()
        }
    }

    func makeRequestForAPIName(_ apiName: String,
                               operationType: APIOperationType,
                               body: String? = nil,
                               path: String) throws -> URLRequest {
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

        let headers = ["content-type": "application/json"]
        var baseRequest = URLRequest(url: url)

        switch operationType {
        case .get:
            break
        case .put:
            break
        case .post:
            baseRequest.httpMethod = "POST"
            baseRequest.allHTTPHeaderFields = headers
            if let body = body {
                baseRequest.httpBody = body.data(using: .utf8)
            }
        case .patch:
            break
        case .delete:
            break
        }

        let finalRequest = try endpointConfig.interceptors.reduce(baseRequest) { (request, interceptor) -> URLRequest in
            do {
                return try interceptor.intercept(request)
            } catch {
                throw GraphQLError.operationError("Failed to intercept request fully..",
                                                  "Something wrong with the interceptor",
                                                  error)
            }
        }

        return finalRequest
    }

    func urlForAPIName(_ apiName: String, path: String) throws -> URL {
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

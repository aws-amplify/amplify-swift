//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSGraphQLOperation<R: ResponseType>: AmplifyOperation<GraphQLRequest,
    Void,
    GraphQLResponse<R.SerializedObject>,
    GraphQLError> {

    // Data received by the operation
    var data = Data()

    let session: URLSessionBehavior
    var mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfig

    init(request: GraphQLRequest,
         eventName: String,
         responseType: R,
         listener: AWSGraphQLOperation.EventListener?,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfig) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig

        super.init(categoryType: .api,
                   eventName: eventName,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let error = request.validate() {
            dispatch(event: .failed(error))
            finish()
            return
        }

        guard let endpointConfig = pluginConfig.endpoints[request.apiName] else {
            let error = GraphQLError.invalidConfiguration(
                "Unable to get an endpoint configuration for \(request.apiName)",
                """
                Review your API plugin configuration and ensure \(request.apiName) has a valid configuration.
                """
            )
            dispatch(event: .failed(error))
            finish()
            return
        }

        let queryDocument = GraphQLRequestUtils.getQueryDocument(document: request.document,
                                                                 variables: request.variables)

        let requestPayload: Data
        do {
            requestPayload = try JSONSerialization.data(withJSONObject: queryDocument)
        } catch {
            dispatch(event: .failed(GraphQLError.operationError("Failed to serialize query document",
                                                                "fix the document or variables",
                                                                error)))
            finish()
            return
        }

        let urlRequest = GraphQLRequestUtils.constructRequest(with: endpointConfig.baseURL,
                                                              requestPayload: requestPayload)

        let finalRequest = endpointConfig.interceptors.reduce(urlRequest) { $1.intercept($0) }

        let task = session.dataTaskBehavior(with: finalRequest)

        mapper.addPair(operation: self, task: task)
        task.resume()
    }
}

class GraphQLRequestUtils {

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
        let headers = ["content-type": "application/json"]
        baseRequest.allHTTPHeaderFields = headers
        baseRequest.httpMethod = "POST"
        baseRequest.httpBody = requestPayload

        return baseRequest
    }
}

// GraphQLRequestUtils+Validation
extension GraphQLRequestUtils {

    static func validateDocument(_ document: String) -> GraphQLError? {
        // TODO: implement
        return nil
    }

    static func validateVariables(_ variables: [String: Any]?) -> GraphQLError? {
        if let variables = variables {
            // TODO: implement
        }

        return nil
    }
}

extension GraphQLRequest {
    // Performs client side validation and returns a `GraphQLError` for any validation failures
    func validate() -> GraphQLError? {
        if let error = GraphQLRequestUtils.validateDocument(document) {
            return error
        }

        if let error = GraphQLRequestUtils.validateVariables(variables) {
            return error
        }

        return nil
    }
}

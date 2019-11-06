//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCore

final public class AWSGraphQLOperation<R: ResponseType>: AmplifyOperation<GraphQLRequest,
    Void,
    GraphQLResponse<R.SerializedObject>,
    GraphQLError> {

    var graphQLResponseData = Data()
    let session: URLSessionBehavior
    let mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration
    let responseType: R
    var subscriptionConnectionFactory: SubscriptionConnectionFactory?
    var connection: SubscriptionConnection?
    var subscriptionItem: SubscriptionItem?

    init(request: GraphQLRequest,
         eventName: String,
         responseType: R,
         listener: AWSGraphQLOperation.EventListener?,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration) {

        self.responseType = responseType
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

        // Validate the request
        if let error = request.validate() {
            dispatch(event: .failed(error))
            finish()
            return
        }

        // Retrieve endpoint configuration
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

        if request.operationType == .subscription {
            switch endpointConfig.authorizationConfiguration {
            case .apiKey(let apiKeyConfiguration):
                subscribe(url: endpointConfig.baseURL,
                          apiKey: apiKeyConfiguration.apiKey,
                          document: request.document,
                          variables: request.variables)
            default:
                break
            }
            return
        }
        // Prepare request payload
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

        // Create request
        let urlRequest = GraphQLRequestUtils.constructRequest(with: endpointConfig.baseURL,
                                                              requestPayload: requestPayload)

        // Intercept request
        let finalRequest = endpointConfig.interceptors.reduce(urlRequest) { (request, interceptor) -> URLRequest in
            do {
                return try interceptor.intercept(request)
            } catch {
                dispatch(event: .failed(GraphQLError.operationError("Failed to intercept request fully..",
                                                                    "Something wrong with the interceptor",
                                                                    error)))
                cancel()
                return request
            }
        }

        if isCancelled {
            finish()
            return
        }

        // Begin network task
        let task = session.dataTaskBehavior(with: finalRequest)
        mapper.addPair(operation: self, task: task)
        task.resume()
    }

    func subscribe(url: URL, apiKey: String, document: String, variables: [String: Any]?) {

        let authType = AWSAppSyncAuthType.apiKey
        let retryStrategy = AWSAppSyncRetryStrategy.aggressive
        let serviceRegion: AWSRegionType = .USEast1
        let apikeyProvider = BasicAWSAPIKeyAuthProvider(key: apiKey)
        subscriptionConnectionFactory = SubscriptionConnectionFactory(url: url,
                                                                          authType: authType,
                                                                          retryStrategy: retryStrategy,
                                                                          region: serviceRegion,
                                                                          apiKeyProvider: apikeyProvider,
                                                                          cognitoUserPoolProvider: nil,
                                                                          oidcAuthProvider: nil,
                                                                          iamAuthProvider: nil)

        connection = subscriptionConnectionFactory?.connection(connectionType: .appSyncRealtime)
        subscriptionItem = connection?.subscribe(requestString: document,
                                                 variables: variables,
                                                 eventHandler: { (event, item) in
            print("event, item")
            switch event {
            case .connection(let connectionEvent):
                print("Got connectionEvent \(connectionEvent)")
            case .data(let data):
                print("Got data \(data)")
            case .failed(let error):
                print("Got error \(error)")
            }
        })
    }
}
class BasicAWSAPIKeyAuthProvider: AWSAPIKeyAuthProvider {
    var apiKey: String

    init(key: String) {
        self.apiKey = key
    }

    func getAPIKey() -> String {
        return apiKey
    }
}

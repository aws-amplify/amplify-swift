//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCore
import AWSPluginsCore
import AppSyncRealTimeClient

final public class AWSGraphQLSubscriptionOperation<R: Decodable>: GraphQLSubscriptionOperation<R> {

    let pluginConfig: AWSAPICategoryPluginConfiguration
    let subscriptionConnectionFactory: SubscriptionConnectionFactory
    let authService: AWSAuthServiceBehavior

    var subscriptionConnection: SubscriptionConnection?
    var subscriptionItem: SubscriptionItem?
    var apiAuthProviderFactory: APIAuthProviderFactory

    private let subscriptionQueue = DispatchQueue(label: "AWSGraphQLSubscriptionOperation.subscriptionQueue")

    init(request: GraphQLOperationRequest<R>,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         subscriptionConnectionFactory: SubscriptionConnectionFactory,
         authService: AWSAuthServiceBehavior,
         apiAuthProviderFactory: APIAuthProviderFactory,
         inProcessListener: AWSGraphQLSubscriptionOperation.InProcessListener?,
         resultListener: AWSGraphQLSubscriptionOperation.ResultListener?) {

        self.pluginConfig = pluginConfig
        self.subscriptionConnectionFactory = subscriptionConnectionFactory
        self.authService = authService
        self.apiAuthProviderFactory = apiAuthProviderFactory

        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.subscribe,
                   request: request,
                   inProcessListener: inProcessListener,
                   resultListener: resultListener)
    }

    override public func cancel() {
        subscriptionQueue.sync {
            if let subscriptionItem = subscriptionItem, let subscriptionConnection = subscriptionConnection {
                subscriptionConnection.unsubscribe(item: subscriptionItem)
                let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.disconnected)
                dispatchInProcess(data: subscriptionEvent)
            }
        }

        super.cancel()
        dispatch(result: .successfulVoid)
        finish()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        // Validate the request
        if case let .failure(error) = validate(request: request) {
            dispatch(result: .failure(error))
            finish()
            return
        }

        let endpointConfig = getEndpointConfig(from: pluginConfig, apiName: request.apiName)
        let authType = (request.options.pluginOptions as? AWSPluginOptions).flatMap { $0.authType }
        let urlRequestInterceptors = endpointConfig.flatMap {
            getURLRequestInterceptors(
                pluginConfig: pluginConfig,
                endpointConfig: $0,
                authType: authType
            )
        }

        let urlRequest = endpointConfig.map { makeURLRequest(with: $0) }.flatMap { request in
            urlRequestInterceptors.flatMap { interceptors in
                decorateURLRequest(urlRequestInterceptors: interceptors, urlRequest: request)
            }
        }

        switch (endpointConfig, urlRequest) {
        case let (.failure(error), _), let (_, .failure(error)):
            dispatch(result: .failure(error))
            finish()
        case let (.success(endpointConfig), .success(urlRequest)):
            // Retrieve the subscription connection
            subscriptionQueue.sync {
                do {
                    subscriptionConnection = try subscriptionConnectionFactory
                        .getOrCreateConnection(for: endpointConfig,
                                               urlRequest: urlRequest,
                                               authService: authService,
                                               authType: authType,
                                               apiAuthProviderFactory: apiAuthProviderFactory)
                } catch {
                    let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
                    dispatch(result: .failure(error))
                    finish()
                    return
                }

                // Create subscription

                subscriptionItem = subscriptionConnection?.subscribe(requestString: request.document,
                                                                     variables: request.variables,
                                                                     eventHandler: { [weak self] event, _ in
                    self?.onAsyncSubscriptionEvent(event: event)
                })
            }
        }
    }

    private func validate<T>(request: GraphQLOperationRequest<T>) -> Result<Void, APIError> {
        do {
            try request.validate()
            return .success(())
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not validate request", "", nil))
        }
    }

    private func getEndpointConfig(
        from pluginConfig: AWSAPICategoryPluginConfiguration,
        apiName: String?
    ) -> Result<AWSAPICategoryPluginConfiguration.EndpointConfig, APIError> {
        do {
            return .success(try pluginConfig.endpoints.getConfig(for: apiName, endpointType: .graphQL))
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not get endpoint configuration", "", nil))
        }
    }

    private func makeURLRequest(
        with endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
    ) -> URLRequest {
        var urlRequest = URLRequest(url: endpointConfig.baseURL)
        urlRequest.setValue(AmplifyAWSServiceConfiguration.baseUserAgent(),
                            forHTTPHeaderField: URLRequestConstants.Header.userAgent)
        return urlRequest
    }

    private func getURLRequestInterceptors(
        pluginConfig: AWSAPICategoryPluginConfiguration,
        endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        authType: AWSAuthorizationType?
    ) -> Result<[URLRequestInterceptor], APIError> {
        do {
            if let authType = authType {
                return .success(try pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig, authType: authType))
            } else {
                return .success(try pluginConfig.interceptorsForEndpoint(withConfig: endpointConfig))
            }
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Could not get request interceptoors", "", nil))
        }
    }

    private func decorateURLRequest(
        urlRequestInterceptors: [URLRequestInterceptor],
        urlRequest: URLRequest
    ) -> Result<URLRequest, APIError> {
        do {
            var mutableRequest = urlRequest
            for inspector in urlRequestInterceptors {
                mutableRequest = try inspector.intercept(mutableRequest)
            }
            return .success(mutableRequest)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(APIError.unknown("Failed to intercept URLRequest", "", nil))
        }
    }

    private func onAsyncSubscriptionEvent(event: SubscriptionItemEvent) {
        switch event {
        case .connection(let subscriptionConnectionEvent):
            onSubscriptionEvent(subscriptionConnectionEvent)
        case .data(let data):
            onGraphQLResponseData(data)
        case .failed(let error):
            onSubscriptionFailure(error)
        }
    }

    private func onSubscriptionEvent(_ subscriptionConnectionEvent: SubscriptionConnectionEvent) {
        switch subscriptionConnectionEvent {
        case .connecting:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.connecting)
            dispatchInProcess(data: subscriptionEvent)
        case .connected:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.connected)
            dispatchInProcess(data: subscriptionEvent)
        case .disconnected:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.disconnected)
            dispatchInProcess(data: subscriptionEvent)
            dispatch(result: .successfulVoid)
            finish()
        }
    }

    private func onSubscriptionConnectionState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(subscriptionConnectionState)
        dispatchInProcess(data: subscriptionEvent)

        if case .disconnected = subscriptionConnectionState {
            dispatch(result: .successfulVoid)
            finish()
        }
    }

    private func onGraphQLResponseData(_ graphQLResponseData: Data) {
        do {
            let graphQLResponseDecoder = GraphQLResponseDecoder(request: request, response: graphQLResponseData)
            let graphQLResponse = try graphQLResponseDecoder.decodeToGraphQLResponse()
            dispatchInProcess(data: .data(graphQLResponse))
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
        } catch {
            // TODO: Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            dispatch(result: .failure(APIError.operationError("Failed to deserialize", "", error)))
            finish()
        }
    }

    private func onSubscriptionFailure(_ error: Error) {
        var errorDescription = "Subscription item event failed with error"
        if case let ConnectionProviderError.subscription(_, payload) = error,
           let errors = payload?["errors"] as? AppSyncJSONValue,
           let graphQLErrors = try? GraphQLErrorDecoder.decodeAppSyncErrors(errors) {

            if graphQLErrors.hasUnauthorizedError() {
                errorDescription += ": \(APIError.UnauthorizedMessageString)"
            }

            let graphQLResponseError = GraphQLResponseError<R>.error(graphQLErrors)
            dispatch(result: .failure(APIError.operationError(errorDescription, "", graphQLResponseError)))
            finish()
            return
        } else if case ConnectionProviderError.unauthorized = error {
            errorDescription += ": \(APIError.UnauthorizedMessageString)"
        } else if case ConnectionProviderError.connection = error {
            errorDescription += ": connection"
            let error = URLError(.networkConnectionLost)
            dispatch(result: .failure(APIError.networkError(errorDescription, nil, error)))
            finish()
            return
        }

        dispatch(result: .failure(APIError.operationError(errorDescription, "", error)))
        finish()
    }
}

extension Array where Element == GraphQLError {
    func hasUnauthorizedError() -> Bool {
        contains { graphQLError in
            if case let .string(errorTypeValue) = graphQLError.extensions?["errorType"],
               case .unauthorized = AppSyncErrorType(errorTypeValue) {
                return true
            }
            return false
        }
    }
}

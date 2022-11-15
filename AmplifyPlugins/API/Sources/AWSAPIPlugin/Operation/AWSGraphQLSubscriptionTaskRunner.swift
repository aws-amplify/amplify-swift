//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
import AppSyncRealTimeClient

public class AWSGraphQLSubscriptionTaskRunner<R: Decodable>: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel {
    public typealias Request = GraphQLOperationRequest<R>
    public typealias InProcess = GraphQLSubscriptionEvent<R>

    public var request: GraphQLOperationRequest<R>
    public var context = InternalTaskAsyncThrowingSequenceContext<GraphQLSubscriptionEvent<R>>()
    
    let pluginConfig: AWSAPICategoryPluginConfiguration
    let subscriptionConnectionFactory: SubscriptionConnectionFactory
    let authService: AWSAuthServiceBehavior
    var apiAuthProviderFactory: APIAuthProviderFactory
    
    var subscriptionConnection: SubscriptionConnection?
    var subscriptionItem: SubscriptionItem?
    private var running = false

    private let subscriptionQueue = DispatchQueue(label: "AWSGraphQLSubscriptionOperation.subscriptionQueue")
    
    init(request: Request,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         subscriptionConnectionFactory: SubscriptionConnectionFactory,
         authService: AWSAuthServiceBehavior,
         apiAuthProviderFactory: APIAuthProviderFactory) {
        self.request = request
        self.pluginConfig = pluginConfig
        self.subscriptionConnectionFactory = subscriptionConnectionFactory
        self.authService = authService
        self.apiAuthProviderFactory = apiAuthProviderFactory
    }
    
    public func cancel() {
        subscriptionQueue.sync {
            if let subscriptionItem = subscriptionItem, let subscriptionConnection = subscriptionConnection {
                subscriptionConnection.unsubscribe(item: subscriptionItem)
                let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.disconnected)
                send(subscriptionEvent)
            }
        }
    }
    
    public func run() async throws {
        guard !running else { return }
        running = true

        // Validate the request
        do {
            try request.validate()
        } catch let error as APIError {
            fail(error)
            return
        } catch {
            fail(APIError.unknown("Could not validate request", "", nil))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL)
        } catch let error as APIError {
            fail(error)
            return
        } catch {
            fail(APIError.unknown("Could not get endpoint configuration", "", nil))
            return
        }

        // Retrieve request plugin option and
        // auth type in case of a multi-auth setup
        let pluginOptions = request.options.pluginOptions as? AWSPluginOptions

        // Retrieve the subscription connection
        subscriptionQueue.sync {
            do {
                subscriptionConnection = try subscriptionConnectionFactory
                    .getOrCreateConnection(for: endpointConfig,
                                              authService: authService,
                                              authType: pluginOptions?.authType,
                                              apiAuthProviderFactory: apiAuthProviderFactory)
            } catch {
                let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
                fail(error)
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
    
    // MARK: - Subscription callbacks
    
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
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.connecting)
            send(subscriptionEvent)
        case .connected:
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.connected)
            send(subscriptionEvent)
        case .disconnected:
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.disconnected)
            send(subscriptionEvent)
            finish()
        }
    }

    private func onSubscriptionConnectionState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(subscriptionConnectionState)
        send(subscriptionEvent)

        if case .disconnected = subscriptionConnectionState {
            finish()
        }
    }

    private func onGraphQLResponseData(_ graphQLResponseData: Data) {
        do {
            let graphQLResponseDecoder = GraphQLResponseDecoder(request: request, response: graphQLResponseData)
            let graphQLResponse = try graphQLResponseDecoder.decodeToGraphQLResponse()
            send(.data(graphQLResponse))
        } catch let error as APIError {
            fail(error)
        } catch {
            // TODO: Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            
            fail(APIError.operationError("Failed to deserialize", "", error))
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
            fail(APIError.operationError(errorDescription, "", graphQLResponseError))
            return
        } else if case ConnectionProviderError.unauthorized = error {
            errorDescription += ": \(APIError.UnauthorizedMessageString)"
        }

        fail(APIError.operationError(errorDescription, "", error))
    }
}

// TODO: Remove this code, it has replaced been with AWSGraphQLSubscriptionTaskRunner above.
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
                let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.disconnected)
                dispatchInProcess(data: subscriptionEvent)
            }
        }

        dispatch(result: .successfulVoid)
        super.cancel()
        finish()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        // Validate the request
        do {
            try request.validate()
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not validate request", "", nil)))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL)
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not get endpoint configuration", "", nil)))
            finish()
            return
        }

        // Retrieve request plugin option and
        // auth type in case of a multi-auth setup
        let pluginOptions = request.options.pluginOptions as? AWSPluginOptions

        // Retrieve the subscription connection
        subscriptionQueue.sync {
            do {
                subscriptionConnection = try subscriptionConnectionFactory
                    .getOrCreateConnection(for: endpointConfig,
                                              authService: authService,
                                              authType: pluginOptions?.authType,
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

    // MARK: - Subscription callbacks
    
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
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.connecting)
            dispatchInProcess(data: subscriptionEvent)
        case .connected:
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.connected)
            dispatchInProcess(data: subscriptionEvent)
        case .disconnected:
            let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(.disconnected)
            dispatchInProcess(data: subscriptionEvent)
            dispatch(result: .successfulVoid)
            finish()
        }
    }

    private func onSubscriptionConnectionState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        let subscriptionEvent = GraphQLSubscriptionEvent<R>.connection(subscriptionConnectionState)
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

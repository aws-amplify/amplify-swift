//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCore
import AWSPluginsCore

final public class AWSGraphQLSubscriptionOperation<R: Decodable>: GraphQLSubscriptionOperation<R> {

    let pluginConfig: AWSAPICategoryPluginConfiguration
    let subscriptionConnectionFactory: SubscriptionConnectionFactory
    let authService: AWSAuthServiceBehavior

    var subscriptionConnection: SubscriptionConnection?
    var subscriptionItem: SubscriptionItem?

    init(request: GraphQLOperationRequest<R>,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         subscriptionConnectionFactory: SubscriptionConnectionFactory,
         authService: AWSAuthServiceBehavior,
         listener: AWSGraphQLSubscriptionOperation.EventListener?) {

        self.pluginConfig = pluginConfig
        self.subscriptionConnectionFactory = subscriptionConnectionFactory
        self.authService = authService

        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.subscribe,
                   request: request,
                   listener: listener)
    }

    override public func cancel() {
        if let subscriptionItem = subscriptionItem, let subscriptionConnection = subscriptionConnection {
            switch subscriptionItem.subscriptionConnectionState {
            case .connecting, .connected:
                subscriptionConnection.unsubscribe(item: subscriptionItem)
            case .disconnected:
                super.cancel()
            }
        } else {
            super.cancel()
        }
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
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("Could not validate request", "", nil)))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL)
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("Could not get endpoint configuration", "", nil)))
            finish()
            return
        }

        // Retrieve the subscription connection
        do {
            subscriptionConnection = try subscriptionConnectionFactory.getOrCreateConnection(for: endpointConfig,
                                                                                 authService: authService)
        } catch {
            let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
            dispatch(event: .failed(error))
            finish()
            return
        }

        // Create subscription
        subscriptionItem = subscriptionConnection?.subscribe(requestString: request.document,
                                                             variables: request.variables,
                                                             onEvent: { [weak self] event in
            self?.onAsyncSubscriptionEvent(event: event)
        })

    }

    private func onAsyncSubscriptionEvent(event: AsyncEvent<SubscriptionEvent<Data>, Void, APIError>) {
        switch event {
        case .inProcess(let subscriptionEvent):
            onSubscriptionEvent(subscriptionEvent)
        case .failed(let error):
            dispatch(event: .failed(error))
            finish()
        default:
            dispatch(event: .failed(APIError.unknown("Unknown subscription event", "", nil)))
            finish()
        }
    }

    private func onSubscriptionEvent(_ subscriptionEvent: SubscriptionEvent<Data>) {
        switch subscriptionEvent {
        case .connection(let subscriptionConnectionState):
            onSubscriptionConnectionState(subscriptionConnectionState)
        case .data(let graphQLResponseData):
            onGraphQLResponseData(graphQLResponseData)
        }
    }

    private func onSubscriptionConnectionState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(subscriptionConnectionState)
        dispatch(event: .inProcess(subscriptionEvent))

        if case .disconnected = subscriptionConnectionState {
            dispatch(event: .completed(()))
            finish()
        }
    }

    private func onGraphQLResponseData(_ graphQLResponseData: Data) {
        do {
            let graphQLServiceResponse = try GraphQLResponseDecoder.deserialize(graphQLResponse: graphQLResponseData)
            let graphQLResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: graphQLServiceResponse,
                                                                    responseType: request.responseType,
                                                                    decodePath: request.decodePath,
                                                                    rawGraphQLResponse: graphQLResponseData)
            dispatch(event: .inProcess(.data(graphQLResponse)))
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
        } catch {
            // TODO: Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            dispatch(event: .failed(APIError.operationError("Failed to deserialize", "", error)))
            finish()
        }
    }

}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
import InternalAmplifyCredentials
import Combine

public class AWSGraphQLSubscriptionTaskRunner<R: Decodable>: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel {
    public typealias Request = GraphQLOperationRequest<R>
    public typealias InProcess = GraphQLSubscriptionEvent<R>

    public var request: GraphQLOperationRequest<R>
    public var context = InternalTaskAsyncThrowingSequenceContext<GraphQLSubscriptionEvent<R>>()

    var appSyncClient: AppSyncRealTimeClientProtocol?
    var subscription: AnyCancellable? {
        willSet {
            self.subscription?.cancel()
        }
    }
    let appSyncClientFactory: AppSyncRealTimeClientFactoryProtocol
    let pluginConfig: AWSAPICategoryPluginConfiguration
    let authService: AWSAuthCredentialsProviderBehavior
    var apiAuthProviderFactory: APIAuthProviderFactory
    private let userAgent = AmplifyAWSServiceConfiguration.userAgentLib
    private let subscriptionId = UUID().uuidString

    private var running = false

    init(request: Request,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         appSyncClientFactory: AppSyncRealTimeClientFactoryProtocol,
         authService: AWSAuthCredentialsProviderBehavior,
         apiAuthProviderFactory: APIAuthProviderFactory) {
        self.request = request
        self.pluginConfig = pluginConfig
        self.appSyncClientFactory = appSyncClientFactory
        self.authService = authService
        self.apiAuthProviderFactory = apiAuthProviderFactory
    }

    /// When the top-level AmplifyThrowingSequence is canceled, this cancel method is invoked.
    /// In this situation, we need to send the disconnected event because
    /// the top-level AmplifyThrowingSequence is terminated immediately upon cancellation.
    public func cancel() {
        self.send(GraphQLSubscriptionEvent<R>.connection(.disconnected))
        Task {
            guard let appSyncClient = self.appSyncClient else {
                return
            }
            do {
                try await appSyncClient.unsubscribe(id: self.subscriptionId)
            } catch {
                print("[AWSGraphQLSubscriptionTaskRunner] Failed to unsubscribe \(self.subscriptionId)")
            }

            await appSyncClient.disconnectWhenIdel()
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

        let authType: AWSAuthorizationType?
        if let pluginOptions = request.options.pluginOptions as? AWSAPIPluginDataStoreOptions {
            authType = pluginOptions.authType
        } else if let authorizationMode = request.authMode as? AWSAuthorizationType {
            authType = authorizationMode
        } else {
            authType = nil
        }
        // Retrieve the subscription connection
        do {
            self.appSyncClient = try await appSyncClientFactory.getAppSyncRealTimeClient(
                for: endpointConfig,
                endpoint: endpointConfig.baseURL,
                authService: authService,
                authType: authType,
                apiAuthProviderFactory: apiAuthProviderFactory
            )

            // Create subscription
            self.subscription = try await appSyncClient?.subscribe(
                id: subscriptionId,
                query: encodeRequest(query: request.document, variables: request.variables)
            ).sink(receiveValue: { [weak self] event in
                self?.onAsyncSubscriptionEvent(event: event)
            })
        } catch {
            let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
            fail(error)
            return
        }
    }

    private func generateSubscriptionURLRequest(
        from endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
    ) -> URLRequest {
        var urlRequest = URLRequest(url: endpointConfig.baseURL)
        urlRequest.setValue(userAgent, forHTTPHeaderField: URLRequestConstants.Header.userAgent)
        return urlRequest
    }

    // MARK: - Subscription callbacks

    private func onAsyncSubscriptionEvent(event: AppSyncSubscriptionEvent) {
        switch event {
        case .data(let json):
            guard let data = try? JSONEncoder().encode(json) else {
                return
            }
            onGraphQLResponseData(data)
        case .subscribing:
            send(GraphQLSubscriptionEvent<R>.connection(.connecting))
        case .subscribed:
            send(GraphQLSubscriptionEvent<R>.connection(.connected))
        case .unsubscribed:
            send(GraphQLSubscriptionEvent<R>.connection(.disconnected))
            finish()
        case .error(let errors):
            fail(toAPIError(errors, type: R.self))
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
            // Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            // see https://github.com/aws-amplify/amplify-swift/issues/2577

            fail(APIError.operationError("Failed to deserialize", "", error))
        }
    }

}

// Class is still necessary. See https://github.com/aws-amplify/amplify-swift/issues/2252
final public class AWSGraphQLSubscriptionOperation<R: Decodable>: GraphQLSubscriptionOperation<R> {

    let pluginConfig: AWSAPICategoryPluginConfiguration
    let appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol
    let authService: AWSAuthCredentialsProviderBehavior
    private let userAgent = AmplifyAWSServiceConfiguration.userAgentLib

    var appSyncRealTimeClient: AppSyncRealTimeClientProtocol?
    var subscription: AnyCancellable? {
        willSet {
            self.subscription?.cancel()
        }
    }

    var apiAuthProviderFactory: APIAuthProviderFactory
    private let subscriptionId = UUID().uuidString

    init(request: GraphQLOperationRequest<R>,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol,
         authService: AWSAuthCredentialsProviderBehavior,
         apiAuthProviderFactory: APIAuthProviderFactory,
         inProcessListener: AWSGraphQLSubscriptionOperation.InProcessListener?,
         resultListener: AWSGraphQLSubscriptionOperation.ResultListener?) {

        self.pluginConfig = pluginConfig
        self.appSyncRealTimeClientFactory = appSyncRealTimeClientFactory
        self.authService = authService
        self.apiAuthProviderFactory = apiAuthProviderFactory

        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.subscribe,
                   request: request,
                   inProcessListener: inProcessListener,
                   resultListener: resultListener)
    }

    override public func cancel() {
        super.cancel()
        Task {
            guard let appSyncRealTimeClient = self.appSyncRealTimeClient else {
                return
            }

            do {
                try await appSyncRealTimeClient.unsubscribe(id: subscriptionId)
                finish()
            } catch {
                print("[AWSGraphQLSubscriptionOperation] Failed to unsubscribe \(subscriptionId), error: \(error)")
            }

            await appSyncRealTimeClient.disconnectWhenIdel()
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

        let authType: AWSAuthorizationType?
        if let pluginOptions = request.options.pluginOptions as? AWSAPIPluginDataStoreOptions {
            authType = pluginOptions.authType
        } else if let authorizationMode = request.authMode as? AWSAuthorizationType {
            authType = authorizationMode
        } else {
            authType = nil
        }
        Task {
            do {
                appSyncRealTimeClient = try await appSyncRealTimeClientFactory.getAppSyncRealTimeClient(
                    for: endpointConfig,
                    endpoint: endpointConfig.baseURL,
                    authService: authService,
                    authType: authType,
                    apiAuthProviderFactory: apiAuthProviderFactory
                )

                // Create subscription
                self.subscription = try await appSyncRealTimeClient?.subscribe(
                    id: subscriptionId,
                    query: encodeRequest(query: request.document, variables: request.variables)
                ).sink(receiveValue: { [weak self] event in
                    self?.onAsyncSubscriptionEvent(event: event)
                })
            } catch {
                let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
                dispatch(result: .failure(error))
                finish()
                return
            }

        }
    }

    private func generateSubscriptionURLRequest(
        from endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
    ) -> URLRequest {
        var urlRequest = URLRequest(url: endpointConfig.baseURL)
        urlRequest.setValue(userAgent, forHTTPHeaderField: URLRequestConstants.Header.userAgent)
        return urlRequest
    }

    // MARK: - Subscription callbacks

    private func onAsyncSubscriptionEvent(event: AppSyncSubscriptionEvent) {
        switch event {
        case .data(let json):
            guard let data = try? JSONEncoder().encode(json) else {
                return
            }
            onGraphQLResponseData(data)
        case .subscribing:
            dispatchInProcess(data: GraphQLSubscriptionEvent<R>.connection(.connecting))
        case .subscribed:
            dispatchInProcess(data: GraphQLSubscriptionEvent<R>.connection(.connected))
        case .unsubscribed:
            dispatchInProcess(data: GraphQLSubscriptionEvent<R>.connection(.disconnected))
            dispatch(result: .successfulVoid)
            finish()
        case .error(let errors):
            dispatch(result: .failure(toAPIError(errors, type: R.self)))
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
            // Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            // see https://github.com/aws-amplify/amplify-swift/issues/2577

            dispatch(result: .failure(APIError.operationError("Failed to deserialize", "", error)))
            finish()
        }
    }
}

fileprivate func encodeRequest(query: String, variables: [String: Any]?) -> String {
    var json: [String: Any] = [
        "query": query
    ]

    if let variables {
        json["variables"] = variables
    }

    do {
        return String(data: try JSONSerialization.data(withJSONObject: json), encoding: .utf8)!
    } catch {
        return ""
    }
}

fileprivate func toAPIError<R: Decodable>(_ errors: [Error], type: R.Type) -> APIError {
    func errorDescription(_ hasAuthorizationError: Bool = false) -> String {
        "Subscription item event failed with error" +
        (hasAuthorizationError ? ": \(APIError.UnauthorizedMessageString)" : "")
    }

#if swift(<5.8)
    if let errors = errors.cast(to: AppSyncRealTimeRequest.Error.self) {
        let hasAuthorizationError = errors.contains(where: { $0 == .unauthorized})
        return APIError.operationError(
            errorDescription(hasAuthorizationError),
            "",
            errors.first
        )
    } else if let errors = errors.cast(to: GraphQLError.self) {
        let hasAuthorizationError = errors.map(\.extensions)
            .compactMap { $0.flatMap { $0["errorType"]?.stringValue } }
            .contains(where: { AppSyncErrorType($0) == .unauthorized })
        return APIError.operationError(
            errorDescription(hasAuthorizationError),
            "",
            GraphQLResponseError<R>.error(errors)
        )
    } else {
        return APIError.operationError(
            errorDescription(),
            "",
            errors.first
        )
    }
#else
    switch errors {
    case let errors as [AppSyncRealTimeRequest.Error]:
        let hasAuthorizationError = errors.contains(where: { $0 == .unauthorized})
        return APIError.operationError(
            errorDescription(hasAuthorizationError),
            "",
            errors.first
        )
    case let errors as [GraphQLError]:
        let hasAuthorizationError = errors.map(\.extensions)
            .compactMap { $0.flatMap { $0["errorType"]?.stringValue } }
            .contains(where: { AppSyncErrorType($0) == .unauthorized })
        return APIError.operationError(
            errorDescription(hasAuthorizationError),
            "",
            GraphQLResponseError<R>.error(errors)
        )
    default:
        return APIError.operationError(
            errorDescription(),
            "",
            errors.first
        )
    }
#endif
}

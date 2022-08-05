//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

/// Publishes a mutation event to the specified Cloud API. Upon receipt of the API response, validates to ensure it is
/// not a retriable error. If it is, attempts a retry until either success or terminal failure. Upon success or
/// terminal failure, publishes the event response to the appropriate ModelReconciliationQueue subject.
class SyncMutationToCloudOperation: AsynchronousOperation {

    typealias MutationSyncCloudResult = GraphQLOperation<MutationSync<AnyModel>>.OperationResult

    private weak var api: APICategoryGraphQLBehavior?
    private let mutationEvent: MutationEvent
    private let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener
    private let requestRetryablePolicy: RequestRetryablePolicy

    private let lock: NSRecursiveLock

    private var networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?
    private var mutationOperation: GraphQLOperation<MutationSync<AnyModel>>?
    private var mutationRetryNotifier: MutationRetryNotifier?
    private var currentAttemptNumber: Int
    private var authTypesIterator: AWSAuthorizationTypeIterator?

    init(mutationEvent: MutationEvent,
         api: APICategoryGraphQLBehavior,
         authModeStrategy: AuthModeStrategy,
         networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>? = nil,
         currentAttemptNumber: Int = 1,
         requestRetryablePolicy: RequestRetryablePolicy? = RequestRetryablePolicy(),
         completion: @escaping GraphQLOperation<MutationSync<AnyModel>>.ResultListener) async {
        self.mutationEvent = mutationEvent
        self.api = api
        self.networkReachabilityPublisher = networkReachabilityPublisher
        self.completion = completion
        self.currentAttemptNumber = currentAttemptNumber
        self.requestRetryablePolicy = requestRetryablePolicy ?? RequestRetryablePolicy()
        self.lock = NSRecursiveLock()

        if let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName),
           let mutationType = GraphQLMutationType(rawValue: mutationEvent.mutationType) {
            
            self.authTypesIterator = await authModeStrategy.authTypesFor(schema: modelSchema,
                                                                   operation: mutationType.toModelOperation())
        }

        super.init()
    }

    override func main() {
        log.verbose(#function)
        sendMutationToCloud(withAuthType: authTypesIterator?.next())
    }

    override func cancel() {
        log.verbose(#function)
        lock.execute {
            mutationOperation?.cancel()
            mutationRetryNotifier?.cancel()
            mutationRetryNotifier = nil
        }

        let apiError = APIError(error: OperationCancelledError())
        finish(result: .failure(apiError))
    }

    /// Does not require a locking context. Member access is read-only.
    private func sendMutationToCloud(withAuthType authType: AWSAuthorizationType? = nil) {
        guard !isCancelled else {
            return
        }

        log.debug(#function)
        guard let mutationType = GraphQLMutationType(rawValue: mutationEvent.mutationType) else {
            let dataStoreError = DataStoreError.decodingError(
                "Invalid mutation type",
                """
                The incoming mutation event had a mutation type of \(mutationEvent.mutationType), which does not
                match any known GraphQL mutation type. Ensure you only send valid mutation types:
                \(GraphQLMutationType.allCases)
                """
            )
            log.error(error: dataStoreError)
            let apiError = APIError.unknown("Invalid mutation type", "", dataStoreError)
            finish(result: .failure(apiError))
            return
        }

        if let apiRequest = createAPIRequest(mutationType: mutationType, authType: authType) {
            sendMutation(describedBy: apiRequest)
        }
    }

    /// Creates a GraphQLRequest based on given `mutationType`
    /// - Parameters:
    ///   - mutationType: mutation type
    ///   - authType: authorization type, if provided overrides the auth used to perform the API request
    /// - Returns: a GraphQL request
    private func createAPIRequest(
        mutationType: GraphQLMutationType,
        authType: AWSAuthorizationType? = nil
    ) -> GraphQLRequest<MutationSync<AnyModel>>? {
        var request: GraphQLRequest<MutationSync<AnyModel>>

        do {
            var graphQLFilter: GraphQLFilter?
            if let graphQLFilterJSON = mutationEvent.graphQLFilterJSON {
                graphQLFilter = try GraphQLFilterConverter.fromJSON(graphQLFilterJSON)
            }

            switch mutationType {
            case .delete:
                let model = try mutationEvent.decodeModel()
                guard let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName) else {
                    return Fatal.preconditionFailure("""
                    Could not retrieve schema for the model \(mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: model,
                                                                            modelSchema: modelSchema,
                                                                            where: graphQLFilter,
                                                                            version: mutationEvent.version)
            case .update:
                let model = try mutationEvent.decodeModel()
                guard let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName) else {
                    return Fatal.preconditionFailure("""
                    Could not retrieve schema for the model \(mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                request = GraphQLRequest<MutationSyncResult>.updateMutation(of: model,
                                                                            modelSchema: modelSchema,
                                                                            where: graphQLFilter,
                                                                            version: mutationEvent.version)
            case .create:
                let model = try mutationEvent.decodeModel()
                guard let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName) else {
                    return Fatal.preconditionFailure("""
                    Could not retrieve schema for the model \(mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                request = GraphQLRequest<MutationSyncResult>.createMutation(of: model,
                                                                            modelSchema: modelSchema,
                                                                            version: mutationEvent.version)
            }
        } catch {
            let apiError = APIError.unknown("Couldn't decode model", "", error)
            finish(result: .failure(apiError))
            return nil
        }

        let awsPluginOptions = AWSPluginOptions(authType: authType)
        request.options = GraphQLRequest<MutationSyncResult>.Options(pluginOptions: awsPluginOptions)
        return request
    }

    /// Creates and invokes a GraphQL mutation operation for `apiRequest` to the
    /// service, and invokes `respond(toCloudResult:withAPIRequest:)` in the mutation's
    /// completion handler
    /// - Parameter apiRequest: The GraphQLRequest used to create the mutation operation
    private func sendMutation(describedBy apiRequest: GraphQLRequest<MutationSync<AnyModel>>) {
        guard let api = api else {
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failure(apiError))
            return
        }
        log.verbose("\(#function) sending mutation with sync data: \(apiRequest)")
        lock.execute {
            mutationOperation = api.mutate(request: apiRequest) { [weak self] result in
                self?.respond(toCloudResult: result, withAPIRequest: apiRequest)
            }
        }
    }

    /// Initiates a locking context
    private func respond(
        toCloudResult result: GraphQLOperation<MutationSync<AnyModel>>.OperationResult,
        withAPIRequest apiRequest: GraphQLRequest<MutationSync<AnyModel>>
    ) {
        lock.execute {
            guard !self.isCancelled else {
                Amplify.log.debug("SyncMutationToCloudOperation cancelled, aborting")
                return
            }

            log.verbose("GraphQL mutation operation received result: \(result)")
            validate(cloudResult: result, request: apiRequest)
        }
    }

    /// - Warning: Must be invoked from a locking context
    private func validate(cloudResult: MutationSyncCloudResult,
                          request: GraphQLRequest<MutationSync<AnyModel>>) {
        guard !isCancelled else {
            return
        }

        if case .failure(let error) = cloudResult {
            let advice = getRetryAdviceIfRetryable(error: error)

            guard advice.shouldRetry else {
                finish(result: .failure(error))
                return
            }

            resolveReachabilityPublisher(request: request)
            if let pluginOptions = request.options?.pluginOptions as? AWSPluginOptions, pluginOptions.authType != nil,
               let nextAuthType = authTypesIterator?.next() {
                scheduleRetry(advice: advice, withAuthType: nextAuthType)
            } else {
                scheduleRetry(advice: advice)
            }
            return
        }

        finish(result: cloudResult)
    }

    /// - Warning: Must be invoked from a locking context
    private func resolveReachabilityPublisher(request: GraphQLRequest<MutationSync<AnyModel>>) {
        if networkReachabilityPublisher == nil {
            if let reachability = api as? APICategoryReachabilityBehavior {
                do {
                    networkReachabilityPublisher = try reachability.reachabilityPublisher(for: request.apiName)
                } catch {
                    log.error("\(#function): Unable to listen on reachability: \(error)")
                }
            }
        }
    }

    /// - Warning: Must be invoked from a locking context
    private func getRetryAdviceIfRetryable(error: APIError) -> RequestRetryAdvice {
        var advice = RequestRetryAdvice(shouldRetry: false, retryInterval: DispatchTimeInterval.never)

        switch error {
        case .networkError(_, _, let error):
            // currently expecting APIOperationResponse to be an URLError
            let urlError = error as? URLError
            advice = requestRetryablePolicy.retryRequestAdvice(urlError: urlError,
                                                               httpURLResponse: nil,
                                                               attemptNumber: currentAttemptNumber)

        // we can't unify the following two cases as they have different associated values.
        // should retry with a different authType if server returned "Unauthorized Error"
        case .httpStatusError(_, let httpURLResponse) where httpURLResponse.statusCode == 401:
            advice = shouldRetryWithDifferentAuthType()
        // should retry with a different authType if request failed locally with an AuthError
        case .operationError(_, _, let error) where (error as? AuthError) != nil:
            advice = shouldRetryWithDifferentAuthType()

        case .httpStatusError(_, let httpURLResponse):
            advice = requestRetryablePolicy.retryRequestAdvice(urlError: nil,
                                                               httpURLResponse: httpURLResponse,
                                                               attemptNumber: currentAttemptNumber)
        default:
            break
        }
        return advice
    }

    /// - Warning: Must be invoked from a locking context
    private func shouldRetryWithDifferentAuthType() -> RequestRetryAdvice {
        let shouldRetry = (authTypesIterator?.count ?? 0) > 0
        return RequestRetryAdvice(shouldRetry: shouldRetry, retryInterval: .milliseconds(0))
    }

    /// - Warning: Must be invoked from a locking context
    private func scheduleRetry(advice: RequestRetryAdvice,
                               withAuthType authType: AWSAuthorizationType? = nil) {
        log.verbose("\(#function) scheduling retry for mutation \(advice)")
        mutationRetryNotifier = MutationRetryNotifier(
            advice: advice,
            networkReachabilityPublisher: networkReachabilityPublisher
        ) { [weak self] in
            self?.respondToMutationNotifierTriggered(withAuthType: authType)
        }
        currentAttemptNumber += 1
    }

    /// Initiates a locking context
    private func respondToMutationNotifierTriggered(withAuthType authType: AWSAuthorizationType?) {
        log.verbose("\(#function) mutationRetryNotifier triggered")
        lock.execute {
            sendMutationToCloud(withAuthType: authType)
            mutationRetryNotifier = nil
        }
    }

    /// Cleans up operation resources, finalizes AsynchronousOperation states, and invokes `completion` with `result`
    /// - Parameter result: The MutationSyncCloudResult to pass to `completion`
    private func finish(result: MutationSyncCloudResult) {
        log.verbose(#function)
        lock.execute {
            mutationOperation?.removeResultListener()
            mutationOperation = nil
        }

        DispatchQueue.global().async {
            self.completion(result)
        }

        finish()
    }
}

// MARK: - GraphQLMutationType + toModelOperation
private extension GraphQLMutationType {
    func toModelOperation() -> ModelOperation {
        switch self {
        case .create:
            return .create
        case .update:
            return .update
        case .delete:
            return .delete
        }
    }
}

extension SyncMutationToCloudOperation: DefaultLogger { }

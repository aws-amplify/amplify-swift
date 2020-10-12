//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
@available(iOS 13.0, *)
class SyncMutationToCloudOperation: Operation {

    typealias MutationSyncCloudResult = GraphQLOperation<MutationSync<AnyModel>>.OperationResult

    private weak var api: APICategoryGraphQLBehavior?
    private let mutationEvent: MutationEvent
    private var mutationOperation: GraphQLOperation<MutationSync<AnyModel>>?
    private var networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?
    private let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener
    private var mutationRetryNotifier: MutationRetryNotifier?
    private var requestRetryablePolicy: RequestRetryablePolicy
    private var currentAttemptNumber: Int

    init(mutationEvent: MutationEvent,
         api: APICategoryGraphQLBehavior,
         networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>? = nil,
         currentAttemptNumber: Int = 1,
         requestRetryablePolicy: RequestRetryablePolicy? = RequestRetryablePolicy(),
         completion: @escaping GraphQLOperation<MutationSync<AnyModel>>.ResultListener) {
        self.mutationEvent = mutationEvent
        self.api = api
        self.networkReachabilityPublisher = networkReachabilityPublisher
        self.completion = completion
        self.currentAttemptNumber = currentAttemptNumber
        self.requestRetryablePolicy = requestRetryablePolicy ?? RequestRetryablePolicy()
        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failure(apiError))
            return
        }

        sendMutationToCloud()
    }

    override func cancel() {
        mutationOperation?.cancel()
        mutationRetryNotifier?.cancel()
        let apiError = APIError.unknown("Operation cancelled", "")
        finish(result: .failure(apiError))
    }

    private func sendMutationToCloud() {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failure(apiError))
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

        if let apiRequest = createAPIRequest(mutationType: mutationType) {
            makeAPIRequest(apiRequest)
        }
    }

    func createAPIRequest(mutationType: GraphQLMutationType) -> GraphQLRequest<MutationSync<AnyModel>>? {
        let request: GraphQLRequest<MutationSync<AnyModel>>

        do {
            var graphQLFilter: GraphQLFilter?
            if let graphQLFilterJSON = mutationEvent.graphQLFilterJSON {
                graphQLFilter = try GraphQLFilterConverter.fromJSON(graphQLFilterJSON)
            }

            switch mutationType {
            case .delete:
                request = GraphQLRequest<MutationSyncResult>.deleteMutation(modelName: mutationEvent.modelName,
                                                                            id: mutationEvent.modelId,
                                                                            where: graphQLFilter,
                                                                            version: mutationEvent.version)
            case .update:
                let model = try mutationEvent.decodeModel()
                guard let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName) else {
                    preconditionFailure("""
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
                    preconditionFailure("""
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
        return request
    }

    func makeAPIRequest(_ apiRequest: GraphQLRequest<MutationSync<AnyModel>>) {
        guard let api = api else {
            // TODO: This should be part of our error handling routines
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failure(apiError))
            return
        }
        log.verbose("\(#function) sending mutation with sync data: \(apiRequest)")
        mutationOperation = api.mutate(request: apiRequest) { result in
            self.log.verbose("sendMutationToCloud received result: \(result)")
            self.validate(cloudResult: result, request: apiRequest)
        }
    }

    private func validate(cloudResult: MutationSyncCloudResult,
                          request: GraphQLRequest<MutationSync<AnyModel>>) {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failure(apiError))
            return
        }

        if case .failure(let error) = cloudResult {
            let advice = getRetryAdviceIfRetryable(error: error)
            if advice.shouldRetry {
                resolveReachabilityPublisher(request: request)
                self.scheduleRetry(advice: advice)
            } else {
                self.finish(result: .failure(error))
            }
            return
        }

        finish(result: cloudResult)
    }

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

    private func getRetryAdviceIfRetryable(error: APIError) -> RequestRetryAdvice {
        var advice = RequestRetryAdvice(shouldRetry: false, retryInterval: DispatchTimeInterval.never)

        switch error {
        case .networkError(_, _, let error):
            //currently expecting APIOperationResponse to be an URLError
            let urlError = error as? URLError
            advice = requestRetryablePolicy.retryRequestAdvice(urlError: urlError,
                                                               httpURLResponse: nil,
                                                               attemptNumber: currentAttemptNumber)
        case .httpStatusError(_, let httpURLResponse):
            advice = requestRetryablePolicy.retryRequestAdvice(urlError: nil,
                                                               httpURLResponse: httpURLResponse,
                                                               attemptNumber: currentAttemptNumber)
        default:
            break
        }
        return advice
    }

    private func scheduleRetry(advice: RequestRetryAdvice) {
        log.verbose("\(#function) scheduling retry for mutation")
        mutationRetryNotifier = MutationRetryNotifier(advice: advice,
                                                      networkReachabilityPublisher: networkReachabilityPublisher) {
                                                        self.sendMutationToCloud()
                                                        self.mutationRetryNotifier = nil
        }
        currentAttemptNumber += 1
    }

    private func finish(result: MutationSyncCloudResult) {
        mutationOperation?.removeResultListener()
        mutationOperation = nil

        DispatchQueue.global().async {
            self.completion(result)
        }
    }
}

@available(iOS 13.0, *)
extension SyncMutationToCloudOperation: DefaultLogger { }

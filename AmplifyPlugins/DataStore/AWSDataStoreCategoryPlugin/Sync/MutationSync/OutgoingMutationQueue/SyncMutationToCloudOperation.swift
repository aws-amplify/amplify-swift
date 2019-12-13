//
// Copyright 2018-2019 Amazon.com,
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

    private weak var api: APICategoryGraphQLBehavior?
    private let mutationEvent: MutationEvent
    private var mutationOperation: GraphQLOperation<MutationSync<AnyModel>>?
    private let networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, DataStoreError>?
    private let completion: GraphQLOperation<MutationSync<AnyModel>>.EventListener
    private var mutationRetryNotifier: MutationRetryNotifier?
    private var requestRetryablePolicy: RequestRetryablePolicy
    private var currentAttemptNumber: Int

    init(mutationEvent: MutationEvent,
         api: APICategoryGraphQLBehavior,
         networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, DataStoreError>?,
         currentAttemptNumber: Int = 1,
         requestRetryablePolicy: RequestRetryablePolicy? = RequestRetryablePolicy(),
         completion: @escaping GraphQLOperation<MutationSync<AnyModel>>.EventListener) {
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
            finish(result: .failed(apiError))
            return
        }

        sendMutationToCloud()
    }

    override func cancel() {
        mutationOperation?.cancel()
        mutationRetryNotifier?.cancel()
        let apiError = APIError.unknown("Operation cancelled", "")
        finish(result: .failed(apiError))
    }

    private func sendMutationToCloud() {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failed(apiError))
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
            finish(result: .failed(apiError))
            return
        }

        if let apiRequest = createAPIRequest(mutationType: mutationType) {
            makeAPIRequest(apiRequest)
        }
    }

    func createAPIRequest(mutationType: GraphQLMutationType) -> GraphQLRequest<MutationSync<AnyModel>>? {
        let request: GraphQLRequest<MutationSync<AnyModel>>
        do {
            if mutationType == .delete {
                request = try deleteRequest(for: mutationEvent)
            } else {
                request = try createOrUpdateRequest(for: mutationEvent, mutationType: mutationType)
            }
        } catch {
            let apiError = APIError.unknown("Couldn't decode model", "", error)
            finish(result: .failed(apiError))
            return nil
        }
        return request
    }

    func makeAPIRequest(_ apiRequest: GraphQLRequest<MutationSync<AnyModel>>) {
        guard let api = api else {
            // TODO: This should be part of our error handling routines
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failed(apiError))
            return
        }
        log.verbose("\(#function) sending mutation with sync data: \(apiRequest)")
        mutationOperation = api.mutate(request: apiRequest) { asyncEvent in
            self.log.verbose("sendMutationToCloud received asyncEvent: \(asyncEvent)")
            self.validateResponseFromCloud(asyncEvent: asyncEvent)
        }
    }

    private func deleteRequest(for mutationEvent: MutationEvent)
        throws -> GraphQLRequest<MutationSync<AnyModel>> {
            let document = try GraphQLDeleteSyncMutation(of: mutationEvent.modelName,
                                                         id: mutationEvent.modelId,
                                                         version: mutationEvent.version)
            let request = GraphQLRequest(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: MutationSync<AnyModel>.self,
                                         decodePath: document.decodePath)
            return request
    }

    private func createOrUpdateRequest(for mutationEvent: MutationEvent, mutationType: GraphQLMutationType)
        throws -> GraphQLRequest<MutationSync<AnyModel>> {
            let model = try mutationEvent.decodeModel()
            let document = GraphQLSyncMutation(of: model,
                                               type: mutationType,
                                               version: mutationEvent.version)
            let request = GraphQLRequest(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: MutationSync<AnyModel>.self,
                                         decodePath: document.decodePath)
            return request
    }

    private func validateResponseFromCloud(asyncEvent: AsyncEvent<Void,
        GraphQLResponse<MutationSync<AnyModel>>, APIError>) {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failed(apiError))
            return
        }

        if case .failed(let error) = asyncEvent {
            let advice = getRetryAdviceIfRetryable(error: error)
            if advice.shouldRetry {
                self.scheduleRetry(advice: advice)
            } else {
                self.finish(result: .failed(error))
            }
            return
        }

        // TODO: Wire in actual event validation

        // This doesn't belong here--need to add a `delete` API to the MutationEventSource and pass a
        // reference into the mutation queue.
        Amplify.DataStore.delete(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                let apiError = APIError.pluginError(dataStoreError)
                self.finish(result: .failed(apiError))
            case .success:
                self.finish(result: asyncEvent)
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

    private func finish(result: AsyncEvent<Void, GraphQLResponse<MutationSync<AnyModel>>, APIError>) {
        mutationOperation?.removeListener()
        mutationOperation = nil

        DispatchQueue.global().async {
            self.completion(result)
        }
    }
}

@available(iOS 13.0, *)
extension SyncMutationToCloudOperation: DefaultLogger { }

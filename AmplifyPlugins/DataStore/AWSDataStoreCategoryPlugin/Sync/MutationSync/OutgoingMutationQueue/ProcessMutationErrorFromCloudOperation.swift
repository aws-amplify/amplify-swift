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

/// Checks the GraphQL error response for specific error scenarios related to data synchronziation to the local store.
/// 1. When there is a "conditional request failed" error, then emit to the Hub a 'conditionalSaveFailed' event.
/// 2. When there is a "conflict unahandled" error, trigger the conflict handler and reconcile the state of the system.
@available(iOS 13.0, *)
class ProcessMutationErrorFromCloudOperation: AsynchronousOperation {

    private let dataStoreConfiguration: DataStoreConfiguration
    private let storageAdapter: StorageEngineAdapter
    private let mutationEvent: MutationEvent
    private let error: GraphQLResponseError<MutationSync<AnyModel>>
    private let completion: (Result<MutationEvent?, Error>) -> Void
    private var mutationOperation: GraphQLOperation<MutationSync<AnyModel>>?
    private weak var api: APICategoryGraphQLBehavior?

    init(dataStoreConfiguration: DataStoreConfiguration,
         mutationEvent: MutationEvent,
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         error: GraphQLResponseError<MutationSync<AnyModel>>,
         completion: @escaping (Result<MutationEvent?, Error>) -> Void) {
        self.dataStoreConfiguration = dataStoreConfiguration
        self.mutationEvent = mutationEvent
        self.api = api
        self.storageAdapter = storageAdapter
        self.error = error
        self.completion = completion
        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            let error = DataStoreError.unknown("Operation cancelled", "")
            finish(result: .failure(error))
            return
        }

        guard case let .error(graphQLErrors) = error else {
            finish(result: .success(nil))
            return
        }

        guard graphQLErrors.count == 1 else {
            finish(result: .success(nil))
            return
        }

        guard let graphQLError = graphQLErrors.first else {
            finish(result: .success(nil))
            return
        }

        if let extensions = graphQLError.extensions, case let .string(errorTypeValue) = extensions["errorType"] {
            let errorType = AppSyncErrorType(errorTypeValue)
            switch errorType {
            case .conditionalCheck:
                let payload = HubPayload(eventName: HubPayload.EventName.DataStore.conditionalSaveFailed,
                                         data: mutationEvent)
                Amplify.Hub.dispatch(to: .dataStore, payload: payload)
                finish(result: .success(nil))
            case .conflictUnhandled:
                processConflictUnhandled(extensions)
            case .unknown(let errorType):
                log.debug("Unhandled error with errorType \(errorType)")
                finish(result: .success(nil))
            }
        }
    }

    private func processConflictUnhandled(_ extensions: [String: JSONValue]) {
        guard case let .object(data) = extensions["data"] else {
            let error = DataStoreError.unknown("Missing remote model from the response from AppSync.",
                                               "This indicates something unexpected was returned from the service")
            finish(result: .failure(error))
            return
        }

        let remote: MutationSync<AnyModel>
        do {
            let serializedJSON = try JSONEncoder().encode(data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            remote = try decoder.decode(MutationSync<AnyModel>.self, from: serializedJSON)
        } catch {
            finish(result: .failure(error))
            return
        }

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
            finish(result: .failure(dataStoreError))
            return
        }

        switch mutationType {
        case .create:
            let error = DataStoreError.unknown("Should never get conflict unhandled for create mutation",
                                               "This indicates something unexpected was returned from the service")
            finish(result: .failure(error))
            return
        case .delete:
            guard !remote.syncMetadata.deleted else {
                log.debug("Conflict Unhandled for data delete in local and remote. Nothing to do, skip processing.")
                finish(result: .success(nil))
                return
            }
            // Default conflict resolution is to `discard` the local changes. Since local model has been deleted and
            // remote has not, recreate the local model given the remote data.
            saveCreateOrUpdateMutation(remoteModel: remote)
        case .update:
            guard !remote.syncMetadata.deleted else {
                // Remote model has been deleted and there is nothing we can do to un-delete it
                // Reconcile the local store by deleting locally.
                saveDeleteMutation(remoteModel: remote)
                return
            }

            let localModel: Model
            do {
                localModel = try mutationEvent.decodeModel()
            } catch {
                let error = DataStoreError.unknown("Couldn't get model ", "")
                finish(result: .failure(error))
                return
            }

            let conflictData = DataStoreConflictData(local: localModel, remote: remote.model.instance)
            let latestVersion = remote.syncMetadata.version
            dataStoreConfiguration.conflictHandler(conflictData) { result in
                print("result called")
                switch result {
                case .applyRemote:
                    self.saveCreateOrUpdateMutation(remoteModel: remote)
                case .retryLocal:
                    let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: localModel,
                                                                                    version: latestVersion)
                    self.makeAPIRequest(request)
                case .retry(let model):
                    let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: model,
                                                                                    version: latestVersion)
                    self.makeAPIRequest(request)
                }
            }
        }
    }

    // MARK: Sync to cloud

    func makeAPIRequest(_ apiRequest: GraphQLRequest<MutationSync<AnyModel>>) {
        guard !isCancelled else {
            let error = DataStoreError.unknown("Operation cancelled", "")
            finish(result: .failure(error))
            return
        }

        guard let api = api else {
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failure(apiError))
            return
        }
        log.verbose("\(#function) sending mutation with data: \(apiRequest)")
        mutationOperation = api.mutate(request: apiRequest) { asyncEvent in
            self.log.verbose("sendMutationToCloud received asyncEvent: \(asyncEvent)")
            self.validateResponseFromCloud(asyncEvent: asyncEvent, request: apiRequest)
        }
    }

    private func validateResponseFromCloud(asyncEvent: AsyncEvent<Void,
        GraphQLResponse<MutationSync<AnyModel>>, APIError>,
                                           request: GraphQLRequest<MutationSync<AnyModel>>) {
        guard !isCancelled else {
            let error = DataStoreError.unknown("Operation cancelled", "")
            finish(result: .failure(error))
            return
        }

        if case .failed(let error) = asyncEvent {
            dataStoreConfiguration.errorHandler(error)
        }

        if case .completed(let response) = asyncEvent,
            case .failure(let error) = response {
            dataStoreConfiguration.errorHandler(error)
        }

        finish(result: .success(nil))
    }

    // MARK: Reconcile Local Store

    private func saveDeleteMutation(remoteModel: MutationSync<AnyModel>) {
        log.verbose(#function)
        let modelName = remoteModel.model.modelName
        let id = remoteModel.model.id

        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            let error = DataStoreError.unknown("Invalid Model \(modelName)", "")
            finish(result: .failure(error))
            return
        }

        storageAdapter.delete(untypedModelType: modelType, withId: id) { response in
            switch response {
            case .failure(let dataStoreError):
                let error = DataStoreError.unknown("Delete failed \(dataStoreError)", "")
                finish(result: .failure(error))
                return
            case .success:
                self.saveMetadata(storageAdapter: storageAdapter, inProcessModel: remoteModel)
            }
        }
    }

    private func saveCreateOrUpdateMutation(remoteModel: MutationSync<AnyModel>) {
        log.verbose(#function)
        storageAdapter.save(untypedModel: remoteModel.model.instance) { response in
            switch response {
            case .failure(let dataStoreError):
                let error = DataStoreError.unknown("Save failed \(dataStoreError)", "")
                self.finish(result: .failure(error))
                return
            case .success(let savedModel):
                let anyModel: AnyModel
                do {
                    anyModel = try savedModel.eraseToAnyModel()
                } catch {
                    let error = DataStoreError.unknown("eraseToAnyModel failed \(error)", "")
                    self.finish(result: .failure(error))
                    return
                }
                let inProcessModel = MutationSync(model: anyModel, syncMetadata: remoteModel.syncMetadata)
                self.saveMetadata(storageAdapter: self.storageAdapter, inProcessModel: inProcessModel)
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              inProcessModel: MutationSync<AnyModel>) {
        log.verbose(#function)
        storageAdapter.save(inProcessModel.syncMetadata, condition: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                let error = DataStoreError.unknown("Save metadata failed \(dataStoreError)", "")
                self.finish(result: .failure(error))
                return
            case .success(let syncMetadata):
                let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                self.notify(savedModel: appliedModel)
            }
        }
    }

    private func notify(savedModel: MutationSync<AnyModel>) {
        log.verbose(#function)

        guard !isCancelled else {
            let error = DataStoreError.unknown("Operation cancelled", "")
            finish(result: .failure(error))
            return
        }

        let mutationType: MutationEvent.MutationType
        let version = savedModel.syncMetadata.version
        if savedModel.syncMetadata.deleted {
            mutationType = .delete
        } else if version == 1 {
            mutationType = .create
        } else {
            mutationType = .update
        }

        guard let mutationEvent = try? MutationEvent(untypedModel: savedModel.model.instance,
                                                     mutationType: mutationType,
                                                     version: version)
            else {
                let error = DataStoreError.unknown("Could not create MutationEvent", "")
                finish(result: .failure(error))
                return
        }

        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncReceived,
                                 data: mutationEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)

        finish(result: .success(mutationEvent))
    }

    override func cancel() {
        mutationOperation?.cancel()
        let error = DataStoreError.unknown("Operation cancelled", "")
        finish(result: .failure(error))
    }

    private func finish(result: Result<MutationEvent?, Error>) {
        mutationOperation?.removeListener()
        mutationOperation = nil

        DispatchQueue.global().async {
            self.completion(result)
        }
        finish()
    }
}

@available(iOS 13.0, *)
extension ProcessMutationErrorFromCloudOperation: DefaultLogger { }

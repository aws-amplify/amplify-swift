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

/// Checks the GraphQL error response for specific error scenarios related to data synchronziation to the local store.
/// 1. When there is an APIError which is for an unauthenticated user, call the error handler.
/// 2. When there is a "conditional request failed" error, then emit to the Hub a 'conditionalSaveFailed' event.
/// 3. When there is a "conflict unahandled" error, trigger the conflict handler and reconcile the state of the system.
class ProcessMutationErrorFromCloudOperation: AsynchronousOperation {

    typealias MutationSyncAPIRequest = GraphQLRequest<MutationSyncResult>
    typealias MutationSyncCloudResult = GraphQLOperation<MutationSync<AnyModel>>.OperationResult

    private let dataStoreConfiguration: DataStoreConfiguration
    private let storageAdapter: StorageEngineAdapter
    private let mutationEvent: MutationEvent
    private let graphQLResponseError: GraphQLResponseError<MutationSync<AnyModel>>?
    private let apiError: APIError?
    private let completion: (Result<MutationEvent?, Error>) -> Void
    private var mutationOperation: AtomicValue<GraphQLOperation<MutationSync<AnyModel>>?>
    private weak var api: APICategoryGraphQLBehavior?

    init(dataStoreConfiguration: DataStoreConfiguration,
         mutationEvent: MutationEvent,
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         graphQLResponseError: GraphQLResponseError<MutationSync<AnyModel>>? = nil,
         apiError: APIError? = nil,
         completion: @escaping (Result<MutationEvent?, Error>) -> Void) {
        self.dataStoreConfiguration = dataStoreConfiguration
        self.mutationEvent = mutationEvent
        self.api = api
        self.storageAdapter = storageAdapter
        self.graphQLResponseError = graphQLResponseError
        self.apiError = apiError
        self.completion = completion
        self.mutationOperation = AtomicValue(initialValue: nil)

        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            return
        }

        if let apiError = apiError, isAuthSignedOutError(apiError: apiError) {
            dataStoreConfiguration.errorHandler(DataStoreError.api(apiError, mutationEvent))
            finish(result: .success(nil))
            return
        }

        guard let graphQLResponseError = graphQLResponseError,
            case let .error(graphQLErrors) = graphQLResponseError else {
                finish(result: .success(nil))
                return
        }

        guard graphQLErrors.count == 1 else {
            log.error("Received more than one error response: \(String(describing: graphQLResponseError))")
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
            case .unauthorized:
                // TODO: dispatch Hub event
                log.debug("Unauthorized mutation \(errorType)")
                finish(result: .success(nil))
            case .operationDisabled:
                log.debug("Operation disabled \(errorType)")
                finish(result: .success(nil))
            case .unknown(let errorType):
                log.debug("Unhandled error with errorType \(errorType)")
                finish(result: .success(nil))
            }
        } else {
            log.debug("GraphQLError missing extensions and errorType \(graphQLError)")
            finish(result: .success(nil))
        }
    }

    private func isAuthSignedOutError(apiError: APIError) -> Bool {
        if case let .operationError(_, _, underlyingError) = apiError,
            let authError = underlyingError as? AuthError,
            case .signedOut = authError {
            return true
        }

        return false
    }

    private func processConflictUnhandled(_ extensions: [String: JSONValue]) {
        let localModel: Model
        do {
            localModel = try mutationEvent.decodeModel()
        } catch {
            let error = DataStoreError.unknown("Couldn't decode local model", "")
            finish(result: .failure(error))
            return
        }

        let remoteModel: MutationSync<AnyModel>
        switch getRemoteModel(extensions) {
        case .success(let model):
            remoteModel = model
        case .failure(let error):
            finish(result: .failure(error))
            return
        }
        let latestVersion = remoteModel.syncMetadata.version

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
            processLocalModelDeleted(localModel: localModel, remoteModel: remoteModel, latestVersion: latestVersion)
        case .update:
            processLocalModelUpdated(localModel: localModel, remoteModel: remoteModel, latestVersion: latestVersion)
        }
    }

    private func getRemoteModel(_ extensions: [String: JSONValue]) -> Result<MutationSync<AnyModel>, Error> {
        guard case let .object(data) = extensions["data"] else {
            let error = DataStoreError.unknown("Missing remote model from the response from AppSync.",
                                               "This indicates something unexpected was returned from the service")
            return .failure(error)
        }
        do {
            let serializedJSON = try JSONEncoder().encode(data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            return .success(try decoder.decode(MutationSync<AnyModel>.self, from: serializedJSON))
        } catch {
            return .failure(error)
        }
    }

    private func processLocalModelDeleted(
        localModel: Model,
        remoteModel: MutationSync<AnyModel>,
        latestVersion: Int
    ) {
        guard !remoteModel.syncMetadata.deleted else {
            log.debug("Conflict Unhandled for data deleted in local and remote. Nothing to do, skip processing.")
            finish(result: .success(nil))
            return
        }

        let conflictData = DataStoreConflictData(local: localModel, remote: remoteModel.model.instance)
        dataStoreConfiguration.conflictHandler(conflictData) { result in
            switch result {
            case .applyRemote:
                self.saveCreateOrUpdateMutation(remoteModel: remoteModel)
            case .retryLocal:
                let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: localModel,
                                                                                modelSchema: localModel.schema,
                                                                                version: latestVersion)
                self.sendMutation(describedBy: request)
            case .retry(let model):
                guard let modelSchema = ModelRegistry.modelSchema(from: self.mutationEvent.modelName) else {
                    preconditionFailure("""
                    Could not retrieve schema for the model \(self.mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: model,
                                                                                modelSchema: modelSchema,
                                                                                version: latestVersion)
                self.sendMutation(describedBy: request)
            }
        }
    }

    private func processLocalModelUpdated(
        localModel: Model,
        remoteModel: MutationSync<AnyModel>,
        latestVersion: Int
    ) {
        guard !remoteModel.syncMetadata.deleted else {
            log.debug("Conflict Unhandled for updated local and deleted remote. Reconcile by deleting local")
            saveDeleteMutation(remoteModel: remoteModel)
            return
        }

        let conflictData = DataStoreConflictData(local: localModel, remote: remoteModel.model.instance)
        let latestVersion = remoteModel.syncMetadata.version
        dataStoreConfiguration.conflictHandler(conflictData) { result in
            switch result {
            case .applyRemote:
                self.saveCreateOrUpdateMutation(remoteModel: remoteModel)
            case .retryLocal:
                guard let modelSchema = ModelRegistry.modelSchema(from: self.mutationEvent.modelName) else {
                    preconditionFailure("""
                    Could not retrieve schema for the model \(self.mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: localModel,
                                                                                modelSchema: modelSchema,
                                                                                version: latestVersion)
                self.sendMutation(describedBy: request)
            case .retry(let model):
                guard let modelSchema = ModelRegistry.modelSchema(from: self.mutationEvent.modelName) else {
                    preconditionFailure("""
                    Could not retrieve schema for the model \(self.mutationEvent.modelName), verify that datastore is
                    initialized.
                    """)
                }
                let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: model,
                                                                                modelSchema: modelSchema,
                                                                                version: latestVersion)
                self.sendMutation(describedBy: request)
            }
        }
    }

    // MARK: Sync to cloud

    private func sendMutation(describedBy apiRequest: MutationSyncAPIRequest) {
        guard !isCancelled else {
            return
        }

        guard let api = self.api else {
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failure(apiError))
            return
        }

        log.verbose("\(#function) sending mutation with data: \(apiRequest)")
        let graphQLOperation = api.mutate(request: apiRequest) { [weak self] result in
            guard let self = self, !self.isCancelled else {
                return
            }

            self.log.verbose("sendMutationToCloud received asyncEvent: \(result)")
            self.validate(cloudResult: result, request: apiRequest)
        }
        mutationOperation.set(graphQLOperation)
    }

    private func validate(cloudResult: MutationSyncCloudResult, request: MutationSyncAPIRequest) {
        guard !isCancelled else {
            return
        }

        if case .failure(let error) = cloudResult {
            dataStoreConfiguration.errorHandler(error)
        }

        if case .success(let response) = cloudResult,
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
            let error = DataStoreError.invalidModelName("Invalid Model \(modelName)")
            finish(result: .failure(error))
            return
        }

        guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
            let error = DataStoreError.invalidModelName("Invalid Model \(modelName)")
            finish(result: .failure(error))
            return
        }

        storageAdapter.delete(untypedModelType: modelType,
                              modelSchema: modelSchema,
                              withId: id,
                              condition: nil) { response in
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
        mutationOperation.get()?.cancel()
        let error = DataStoreError(error: OperationCancelledError())
        finish(result: .failure(error))
    }

    private func finish(result: Result<MutationEvent?, Error>) {
        mutationOperation.with { operation in
            operation?.removeResultListener()
            operation = nil
        }
        DispatchQueue.global().async {
            self.completion(result)
        }
        finish()
    }
}

extension ProcessMutationErrorFromCloudOperation: DefaultLogger { }

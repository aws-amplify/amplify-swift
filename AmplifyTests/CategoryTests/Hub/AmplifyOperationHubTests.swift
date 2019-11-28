//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class AmplifyOperationHubTests: XCTestCase {

    override func setUp() {
        Amplify.reset()

        let storageConfiguration =
            StorageCategoryConfiguration(plugins: ["MockDispatchingStoragePlugin": nil])
        let config = AmplifyConfiguration(storage: storageConfiguration)
        do {
            try Amplify.add(plugin: MockDispatchingStoragePlugin())
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Given: An AmplifyOperation
    /// When: I invoke Hub.listen(to: operation)
    /// Then: I am notified of events for that operation, in the operation event listener format
    func testlistenerViaListenToOperation() throws {
        let options = StorageListRequest.Options(pluginOptions: ["pluginDelay": 0.5])
        let request = StorageListRequest(options: options)

        let operation = MockDispatchingStorageListOperation(request: request)

        let listenerWasInvoked = expectation(description: "listener was invoked")

        let listener: NonListeningStorageListOperation.EventListener = { event in
            listenerWasInvoked.fulfill()
        }

        let token = Amplify.Hub.listen(to: operation, listener: listener)

        try waitForToken(token)

        operation.doMockDispatch()

        waitForExpectations(timeout: 1.0)
    }

    /// Given: A configured system
    /// When: I perform an operation with an `listener` listener
    /// Then: That listener is notified when an event occurs
    func testlistenerViaOperationInit() {
        let listenerInvoked = expectation(description: "listener was invoked")
        _ = Amplify.Storage.getURL(key: "foo") { _ in
            listenerInvoked.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// Given: A configured system
    /// When: I subscribe to Hub events filtered by operation ID
    /// Then: My listener receives events for that ID
    func testListenerViaHubListen() throws {
        let listenerInvoked = expectation(description: "listener was invoked")
        let operation = Amplify.Storage.getURL(key: "foo") { _ in
            listenerInvoked.fulfill()
        }

        let operationId = operation.id

        let token = Amplify.Hub.listen(to: .storage) { payload in
            guard let context = payload.context as? AmplifyOperationContext<StorageListRequest> else {
                return
            }

            if context.operationId == operationId {
                listenerInvoked.fulfill()
            }
        }

        try waitForToken(token)

        waitForExpectations(timeout: 1.0)
    }

    // Convenience to let tests wait for a listener to be registered. Instead of returning a bool, simply throws if the
    // listener is not registered
    private func waitForToken(_ token: UnsubscribeToken) throws {
        // swiftlint:disable:next force_cast
        let hubPlugin = try Amplify.Hub.getPlugin(for: AWSHubPlugin.key) as! AWSHubPlugin
        guard try HubListenerTestUtilities.waitForListener(with: token, plugin: hubPlugin, timeout: 1.0) else {
            throw "Listener not registered"
        }
    }

}

class MockDispatchingStoragePlugin: StorageCategoryPlugin {
    var key: PluginKey = "MockDispatchingStoragePlugin"

    let queue = DispatchQueue(label: "MockDispatchingStoragePlugin.dispatch")

    func configure(using configuration: Any) throws {}

    func getURL(key: String,
                options: StorageGetURLRequest.Options? = nil,
                listener: StorageGetURLOperation.EventListener? = nil) -> StorageGetURLOperation {
        let options = options ?? StorageGetURLRequest.Options()

        let request = StorageGetURLRequest(key: key, options: options)

        let operation = MockDispatchingStorageGetURLOperation(request: request,
                                                              listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func downloadData(key: String,
                      options: StorageDownloadDataRequest.Options? = nil,
                      listener: StorageDownloadDataOperation.EventListener? = nil) -> StorageDownloadDataOperation {
        let options = options ?? StorageDownloadDataRequest.Options()

        let request = StorageDownloadDataRequest(key: key, options: options)

        let operation = MockDispatchingStorageDownloadDataOperation(request: request,
                                                               listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileRequest.Options? = nil,
                      listener: StorageDownloadFileOperation.EventListener? = nil)
        -> StorageDownloadFileOperation {
            let options = options ?? StorageDownloadFileRequest.Options()

            let request = StorageDownloadFileRequest(key: key, local: local, options: options)

            let operation = MockDispatchingStorageDownloadFileOperation(request: request,
                                                                        listener: listener)

            let delay = resolveDispatchDelay(options: options.pluginOptions)
            queue.asyncAfter(deadline: .now() + delay) {
                operation.dispatch(event: .notInProcess)
            }

            return operation

    }

    func uploadData(key: String,
                    data: Data,
                    options: StorageUploadDataRequest.Options? = nil,
                    listener: StorageUploadDataOperation.EventListener? = nil) -> StorageUploadDataOperation {
        let options = options ?? StorageUploadDataRequest.Options()

        let request = StorageUploadDataRequest(key: key, data: data, options: options)

        let operation = MockDispatchingStorageUploadDataOperation(request: request,
                                                               listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func uploadFile(key: String,
                    local: URL,
                    options: StorageUploadFileRequest.Options? = nil,
                    listener: StorageUploadFileOperation.EventListener? = nil) -> StorageUploadFileOperation {
        let options = options ?? StorageUploadFileRequest.Options()

        let request = StorageUploadFileRequest(key: key, local: local, options: options)

        let operation = MockDispatchingStorageUploadFileOperation(request: request,
                                                                  listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func remove(key: String,
                options: StorageRemoveRequest.Options? = nil,
                listener: StorageRemoveOperation.EventListener? = nil) -> StorageRemoveOperation {
        let options = options ?? StorageRemoveRequest.Options()

        let request = StorageRemoveRequest(key: key, options: options)

        let operation = MockDispatchingStorageRemoveOperation(request: request,
                                                              listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func list(options: StorageListRequest.Options?,
              listener: StorageListOperation.EventListener?) -> StorageListOperation {
        let options = options ?? StorageListRequest.Options()

        let request = StorageListRequest(options: options)

        let operation = MockDispatchingStorageListOperation(request: request,
                                                            listener: listener)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func reset(onComplete: @escaping BasicClosure) {
        onComplete()
    }

    func resolveDispatchDelay(options: Any?) -> TimeInterval {
        let delay: TimeInterval
        if let options = options as? [String: Double],
            let dispatchDelay = options["dispatchDelay"] {
            delay = dispatchDelay
        } else {
            delay = 0
        }
        return delay
    }

}

class MockDispatchingStorageDownloadFileOperation: AmplifyOperation<StorageDownloadFileRequest, Progress,
Void, StorageError>, StorageDownloadFileOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadFile,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageDownloadDataOperation: AmplifyOperation<StorageDownloadDataRequest, Progress,
Data, StorageError>, StorageDownloadDataOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadData,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageGetURLOperation: AmplifyOperation<StorageGetURLRequest, Void,
URL, StorageError>, StorageGetURLOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.getURL,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageListOperation: AmplifyOperation<StorageListRequest, Void,
StorageListResult, StorageError>, StorageListOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.list,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch(event: Event = .unknown) {
        super.dispatch(event: event)
    }
}

class MockDispatchingStorageRemoveOperation: AmplifyOperation<StorageRemoveRequest, Void,
String, StorageError>, StorageRemoveOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.remove,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageUploadDataOperation: AmplifyOperation<StorageUploadDataRequest, Progress,
String, StorageError>, StorageUploadDataOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadData,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageUploadFileOperation: AmplifyOperation<StorageUploadFileRequest, Progress,
String, StorageError>, StorageUploadFileOperation {
    init(request: Request, listener: EventListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadFile,
                   request: request,
                   listener: listener)
    }

    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class NonListeningStorageListOperation: AmplifyOperation<StorageListRequest, Void,
    StorageListResult, StorageError>,
StorageListOperation {
    init(request: Request) {
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadFile,
                   request: request)
    }
}

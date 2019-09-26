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
    func testOnEventViaListenToOperation() {
        let options = StorageListRequest.Options(pluginOptions: ["pluginDelay": 0.5])
        let request = StorageListRequest(options: options)

        let operation = MockDispatchingStorageListOperation(categoryType: .storage,
                                                            request: request)

        let onEventWasInvoked = expectation(description: "onEvent was invoked")

        let onEvent: NonListeningStorageListOperation.EventHandler = { event in
            onEventWasInvoked.fulfill()
        }

        _ = Amplify.Hub.listen(to: operation, onEvent: onEvent)

        operation.doMockDispatch()

        waitForExpectations(timeout: 1.0)
    }

    /// Given: A configured system
    /// When: I perform an operation with an `onEvent` listener
    /// Then: That listener is notified when an event occurs
    func testOnEventViaOperationInit() {
        let onEventInvoked = expectation(description: "onEvent listener was invoked")
        _ = Amplify.Storage.getURL(key: "foo") { _ in
            onEventInvoked.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// Given: A configured system
    /// When: I subscribe to Hub events filtered by operation ID
    /// Then: My listener receives events for that ID
    func testListenerViaHubListen() {
        let onEventInvoked = expectation(description: "onEvent listener was invoked")
        let operation = Amplify.Storage.getURL(key: "foo") { _ in
            onEventInvoked.fulfill()
        }

        let operationId = operation.id

        _ = Amplify.Hub.listen(to: .storage) { payload in
            guard let context = payload.context as? AmplifyOperationContext<StorageListRequest> else {
                return
            }

            if context.operationId == operationId {
                onEventInvoked.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
}

class MockDispatchingStoragePlugin: StorageCategoryPlugin {
    var key: PluginKey = "MockDispatchingStoragePlugin"

    let queue = DispatchQueue(label: "MockDispatchingStoragePlugin.dispatch")

    func configure(using configuration: Any) throws {}

    func getURL(key: String,
                options: StorageGetURLRequest.Options? = nil,
                onEvent: StorageGetURLOperation.EventHandler? = nil) -> StorageGetURLOperation {
        let options = options ?? StorageGetURLRequest.Options()

        let request = StorageGetURLRequest(key: key, options: options)

        let operation = MockDispatchingStorageGetURLOperation(categoryType: .storage,
                                                              request: request,
                                                              onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func getData(key: String,
                 options: StorageGetDataRequest.Options? = nil,
                 onEvent: StorageGetDataOperation.EventHandler? = nil) -> StorageGetDataOperation {
        let options = options ?? StorageGetDataRequest.Options()

        let request = StorageGetDataRequest(key: key, options: options)

        let operation = MockDispatchingStorageGetDataOperation(categoryType: .storage,
                                                               request: request,
                                                               onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func downloadFile(key: String,
                      local: URL,
                      options: StorageDownloadFileRequest.Options? = nil,
                      onEvent: StorageDownloadFileOperation.EventHandler? = nil)
        -> StorageDownloadFileOperation {
            let options = options ?? StorageDownloadFileRequest.Options()

            let request = StorageDownloadFileRequest(key: key, local: local, options: options)

            let operation = MockDispatchingStorageDownloadFileOperation(categoryType: .storage,
                                                                        request: request,
                                                                        onEvent: onEvent)

            let delay = resolveDispatchDelay(options: options.pluginOptions)
            queue.asyncAfter(deadline: .now() + delay) {
                operation.dispatch(event: .notInProcess)
            }

            return operation

    }

    func put(key: String,
             data: Data,
             options: StoragePutRequest.Options? = nil,
             onEvent: StoragePutOperation.EventHandler? = nil) -> StoragePutOperation {
        let options = options ?? StoragePutRequest.Options()

        let request = StoragePutRequest(key: key, source: .data(data), options: options)

        let operation = MockDispatchingStoragePutOperation(categoryType: .storage,
                                                           request: request,
                                                           onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func put(key: String,
             local: URL,
             options: StoragePutRequest.Options? = nil,
             onEvent: StoragePutOperation.EventHandler? = nil) -> StoragePutOperation {
        let options = options ?? StoragePutRequest.Options()

        let request = StoragePutRequest(key: key, source: .local(local), options: options)

        let operation = MockDispatchingStoragePutOperation(categoryType: .storage,
                                                           request: request,
                                                           onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func remove(key: String,
                options: StorageRemoveRequest.Options? = nil,
                onEvent: StorageRemoveOperation.EventHandler? = nil) -> StorageRemoveOperation {
        let options = options ?? StorageRemoveRequest.Options()

        let request = StorageRemoveRequest(key: key, options: options)

        let operation = MockDispatchingStorageRemoveOperation(categoryType: .storage,
                                                              request: request,
                                                              onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func list(options: StorageListRequest.Options?,
              onEvent: StorageListOperation.EventHandler?) -> StorageListOperation {
        let options = options ?? StorageListRequest.Options()

        let request = StorageListRequest(options: options)

        let operation = MockDispatchingStorageListOperation(categoryType: .storage,
                                                            request: request,
                                                            onEvent: onEvent)

        let delay = resolveDispatchDelay(options: options.pluginOptions)
        queue.asyncAfter(deadline: .now() + delay) {
            operation.dispatch(event: .notInProcess)
        }

        return operation
    }

    func reset(onComplete: @escaping (() -> Void)) {
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
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageGetDataOperation: AmplifyOperation<StorageGetDataRequest, Progress,
Data, StorageError>, StorageGetDataOperation {
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageGetURLOperation: AmplifyOperation<StorageGetURLRequest, Void,
URL, StorageError>, StorageGetURLOperation {
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageListOperation: AmplifyOperation<StorageListRequest, Void,
StorageListResult, StorageError>, StorageListOperation {
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStorageRemoveOperation: AmplifyOperation<StorageRemoveRequest, Void,
String, StorageError>, StorageRemoveOperation {
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class MockDispatchingStoragePutOperation: AmplifyOperation<StoragePutRequest, Progress,
String, StorageError>, StoragePutOperation {
    func doMockDispatch() {
        super.dispatch(event: .unknown)
    }
}

class NonListeningStorageListOperation: AmplifyOperation<StorageListRequest, Void,
    StorageListResult, StorageError>,
StorageListOperation {
    init(request: Request) {
        super.init(categoryType: .storage, request: request)
    }
}

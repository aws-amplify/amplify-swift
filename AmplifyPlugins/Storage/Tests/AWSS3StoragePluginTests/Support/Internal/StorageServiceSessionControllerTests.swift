//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin

import Amplify
import XCTest

final class StorageServiceSessionControllerTests: XCTestCase {
    
    enum TestError: Error {
        case urlSessionError
    }
    
    var systemUnderTest: StorageServiceSessionController!
    var serviceIdentifier: String!
    var logger: MockLogger!
    var tasksByIdentifier: [TaskIdentifier: StorageTransferTask]!
    var delegateInteractions: [String]!
    var notifications: [Notification]!
    var fileURL: URL!
    
    override func setUp() async throws {
        self.serviceIdentifier = "StorageServiceSessionControllerTests.\(UUID().uuidString)"
        self.logger = MockLogger()
        self.tasksByIdentifier = [:]
        self.delegateInteractions = []
        self.notifications = []
        self.systemUnderTest = StorageServiceSessionController(identifier: UUID().uuidString,
                                                               configuration: URLSessionConfiguration.ephemeral,
                                                               logger: self.logger)
        self.systemUnderTest.delegate = self
        self.fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingPathComponent(UUID().uuidString))
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        try data.write(to: fileURL, options: .atomic)
    }
    
    override func tearDown() async throws {
        NotificationCenter.default.removeObserver(self)
        try FileManager.default.removeItem(at: self.fileURL)
        self.systemUnderTest = nil
        self.serviceIdentifier = nil
        self.logger = nil
        self.tasksByIdentifier = nil
        self.delegateInteractions = nil
        self.notifications = nil
        self.fileURL = nil
    }
    
    func testurlSessionDidFinishEvents() throws {
        systemUnderTest.urlSessionDidFinishEvents(forBackgroundURLSession: systemUnderTest.session)
        XCTAssertEqual(self.logger.entries, [.init(level: .info, message: "[URLSession] Session did finish background events")])
    }
    
    func testUrlSessionDidBecomeInvalidWithError() throws {
        NotificationCenter.default.addObserver(forName: Notification.Name.StorageURLSessionDidBecomeInvalidNotification, object: systemUnderTest.session, queue: nil) { [weak self] notification in
            self?.notifications.append(notification)
        }
        
        XCTAssertEqual(self.notifications, [])
        let originalSession = systemUnderTest.session
        let originalSessionObjectIdentifier = ObjectIdentifier(originalSession)
        
        systemUnderTest.urlSession(systemUnderTest.session, didBecomeInvalidWithError: TestError.urlSessionError)
        
        let updatedSession = systemUnderTest.session
        let updatedSessionObjectIdentifier = ObjectIdentifier(updatedSession)
        XCTAssertNotEqual(originalSessionObjectIdentifier, updatedSessionObjectIdentifier)
        XCTAssertEqual(self.notifications.map { $0.name }, [Notification.Name.StorageURLSessionDidBecomeInvalidNotification])
        XCTAssertEqual(self.logger.entries, [.init(level: .warn, message: "[URLSession] Session did become invalid: \(systemUnderTest.identifier) [urlSessionError]")])
    }
    
    func testUrlSessionDidCompleteButNotHttp() throws {
        let request = URLRequest(url: self.fileURL)
        let task = systemUnderTest.session.downloadTask(with: request)
        self.tasksByIdentifier[task.taskIdentifier] = StorageTransferTask(transferID: "\(task.taskIdentifier)",
                                                                          transferType: .download(onEvent: { _ in }),
                                                                          bucket: UUID().uuidString,
                                                                          key: UUID().uuidString)
        
        systemUnderTest.urlSession(systemUnderTest.session, task: task, didCompleteWithError: nil)
        XCTAssertEqual(self.logger.entries.count, 2)
        XCTAssertEqual(self.logger.entries[0], .init(level: .info, message: "[URLSession] Session task did complete: \(task.taskIdentifier)"))
        XCTAssertEqual(self.logger.entries[1].level, .warn)
        XCTAssertTrue(self.logger.entries[1].message.hasPrefix("[URLSession] Failed with error: StorageError: Unexpected error occurred with message: Response is not an HTTP response"), self.logger.entries[1].message)
    }
    
    func testUrlSessionDidCompleteWithoutRegisteredTask() throws {
        let request = URLRequest(url: self.fileURL)
        let task = systemUnderTest.session.downloadTask(with: request)
        systemUnderTest.urlSession(systemUnderTest.session, task: task, didCompleteWithError: nil)
        XCTAssertEqual(self.logger.entries, [
            .init(level: .info, message: "[URLSession] Session task did complete: \(task.taskIdentifier)"),
            .init(level: .debug, message: "Did not find transfer task: \(task.taskIdentifier)"),
            .init(level: .info, message: "[URLSession] Session task not handled: \(task.taskIdentifier)"),
        ])
    }
    
    func testUrlSessionDidCompleteWithErrorWithoutRegisteredTask() throws {
        let request = URLRequest(url: self.fileURL)
        let task = systemUnderTest.session.downloadTask(with: request)
        systemUnderTest.urlSession(systemUnderTest.session, task: task, didCompleteWithError: TestError.urlSessionError)
        XCTAssertEqual(self.logger.entries, [
            .init(level: .warn, message: "[URLSession] Session task did complete with error: \(task.taskIdentifier) [urlSessionError]"),
            .init(level: .debug, message: "Did not find transfer task: \(task.taskIdentifier)"),
            .init(level: .info, message: "[URLSession] Session task not handled: \(task.taskIdentifier)"),
        ])
    }
    
}

extension StorageServiceSessionControllerTests: StorageServiceSessionControllerDelegate {
    
    var identifier: String {
        delegateInteractions.append(#function)
        return self.serviceIdentifier
    }
    
    func unregister(task: StorageTransferTask) {
        delegateInteractions.append(#function)
        guard let taskIdentifier = task.taskIdentifier else { return }
        self.tasksByIdentifier[taskIdentifier] = task
    }
    
    func findTask(taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        delegateInteractions.append(#function)
        return self.tasksByIdentifier[taskIdentifier]
    }
    
    func findMultipartUploadSession(uploadId: UploadID) -> StorageMultipartUploadSession? {
        delegateInteractions.append(#function)
        return nil
    }
    
    func completeDownload(taskIdentifier: TaskIdentifier, sourceURL: URL) {
        delegateInteractions.append(#function)
    }
    
}

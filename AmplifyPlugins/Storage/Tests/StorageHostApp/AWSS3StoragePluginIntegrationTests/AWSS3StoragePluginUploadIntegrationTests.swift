//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import SmithyHTTPAPI
import CryptoKit
import XCTest

class AWSS3StoragePluginUploadIntegrationTests: AWSS3StoragePluginTestBase {

    var uploadedKeys: [String]!

    /// Represents expected pieces of the User-Agent header of an SDK http request.
    ///
    /// Example SDK User-Agent:
    /// ```
    /// User-Agent: aws-sdk-swift/1.0 api/s3/1.0 os/iOS/16.4.0 lang/swift/5.8
    /// ```
    /// - Tag: SdkUserAgentComponent
    private enum SdkUserAgentComponent: String, CaseIterable {
        case api = "api/s3"
        case lang = "lang/swift"
        case os = "os/"
        case sdk = "aws-sdk-swift/"
    }

    /// Represents expected pieces of the User-Agent header of an URLRequest used for uploading or
    /// downloading.
    ///
    /// Example SDK User-Agent:
    /// ```
    /// User-Agent: lib/amplify-swift
    /// ```
    /// - Tag: SdkUserAgentComponent
    private enum URLUserAgentComponent: String, CaseIterable {
        case lib = "lib/amplify-swift"
        case os = "os/"
    }

    override func setUp() async throws {
        try await super.setUp()
        uploadedKeys = []
    }

    override func tearDown() async throws {
        for key in uploadedKeys {
            _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))
        }
        uploadedKeys = nil
        try await super.tearDown()
    }

    /// Given: An data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)

        await wait {
            _ = try await Amplify.Storage.uploadData(path: .fromString("public/\(key)"), data: data, options: nil).value
        }
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))

        // Only the remove operation results in an SDK request
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method } , [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A empty data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadEmptyData() async throws {
        let key = UUID().uuidString
        let data = Data("".utf8)
        await wait {
            _ = try await Amplify.Storage.uploadData(path: .fromString("public/\(key)"), data: data, options: nil).value
        }
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A file with contents
    /// When: Upload the file
    /// Then: The operation completes successfully and all URLSession and SDK requests include a user agent
    func testUploadFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: Data(key.utf8), attributes: nil)

        await wait {
            _ = try await Amplify.Storage.uploadFile(path: .fromString("public/\(key)"), local: fileURL, options: nil).value
        }
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))

        // Only the remove operation results in an SDK request
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A file with empty contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFileEmptyData() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: Data("".utf8), attributes: nil)

        await wait {
            _ = try await Amplify.Storage.uploadFile(path: .fromString("public/\(key)"), local: fileURL, options: nil).value
        }
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A large  data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadLargeData() async throws {
        let key = "public/" + UUID().uuidString

        await wait(timeout: 60) {
            let uploadKey = try await Amplify.Storage.uploadData(path: .fromString(key),
                                                                 data: AWSS3StoragePluginTestBase.largeDataObject,
                                                                 options: nil).value
            XCTAssertEqual(uploadKey, key)
        }

        try await Amplify.Storage.remove(path: .fromString(key))

        let userAgents = requestRecorder.urlRequests.compactMap { $0.allHTTPHeaderFields?["User-Agent"] }
        XCTAssertGreaterThan(userAgents.count, 1)
        for userAgent in userAgents {
            let expectedComponent = "MultiPart/UploadPart"
            XCTAssertTrue(userAgent.contains(expectedComponent), "\(userAgent) does not contain \(expectedComponent)")
        }
    }

    /// Given: A large file
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadLargeFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: AWSS3StoragePluginTestBase.largeDataObject,
                                       attributes: nil)

        await wait(timeout: 60) {
            _ = try await Amplify.Storage.uploadFile(path: .fromString("public/\(key)"), local: fileURL, options: nil).value
        }
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))

        let userAgents = requestRecorder.urlRequests.compactMap { $0.allHTTPHeaderFields?["User-Agent"] }
        XCTAssertGreaterThan(userAgents.count, 1)
        for userAgent in userAgents {
            let expectedComponent = "MultiPart/UploadPart"
            XCTAssertTrue(userAgent.contains(expectedComponent), "\(userAgent) does not contain \(expectedComponent)")
        }
    }

    func removeIfExists(_ fileURL: URL) {
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        if fileExists {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to delete file at \(fileURL)")
            }
        }
    }

    private func assertUserAgentComponents(sdkRequests: [HTTPRequest], file: StaticString = #filePath, line: UInt = #line) throws {
        for request in sdkRequests {
            let headers = request.headers.dictionary
            let userAgent = try XCTUnwrap(headers["User-Agent"]?.joined(separator:","))
            for component in SdkUserAgentComponent.allCases {
                XCTAssertTrue(userAgent.contains(component.rawValue), "\(userAgent.description) does not contain \(component)", file: file, line: line)
            }
        }
    }

    private func assertUserAgentComponents(urlRequests: [URLRequest], file: StaticString = #filePath, line: UInt = #line) throws {
        for request in urlRequests {
            let headers = try XCTUnwrap(request.allHTTPHeaderFields)
            let userAgent = try XCTUnwrap(headers["User-Agent"])
            for component in URLUserAgentComponent.allCases {
                XCTAssertTrue(userAgent.contains(component.rawValue), "\(userAgent.description) does not contain \(component)", file: file, line: line)
            }
        }
    }
}

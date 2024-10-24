//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import ClientRuntime
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import CryptoKit
import XCTest
import AWSS3

class AWSS3StoragePluginListObjectsIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: Multiple data object which is uploaded to a public path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedPublicData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        let uniqueStringPath = "public/\(key)"

        await wait {
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test1"), data: data, options: nil).value
        }

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        await wait {
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test2"), data: data, options: nil).value
        }

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test2"))
    }

    /// Given: Multiple data object which is uploaded to a protected path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedProtectedData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        var uniqueStringPath = ""

        // Sign in
        _ = try await Amplify.Auth.signIn(username: Self.user1, password: Self.password)

        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromIdentityID({ identityId in
                    uniqueStringPath = "protected/\(identityId)/\(key)"
                    return uniqueStringPath + "test1"
                }),
                data: data,
                options: nil).value
        }

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromIdentityID({ identityId in
                    uniqueStringPath = "protected/\(identityId)/\(key)"
                    return uniqueStringPath + "test2"
                }),
                data: data,
                options: nil).value
        }

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test2"))

    }

    /// Given: Multiple data object which is uploaded to a private path
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute successfully and list objects for path
    func testListObjectsUploadedPrivateData() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        var uniqueStringPath = ""

        // Sign in
        _ = try await Amplify.Auth.signIn(username: Self.user1, password: Self.password)

        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromIdentityID({ identityId in
                    uniqueStringPath = "private/\(identityId)/\(key)"
                    return uniqueStringPath + "test1"
                }),
                data: data,
                options: nil).value
        }

        let firstListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(firstListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 1)

        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromIdentityID({ identityId in
                    uniqueStringPath = "private/\(identityId)/\(key)"
                    return uniqueStringPath + "test2"
                }),
                data: data,
                options: nil).value
        }

        let secondListResult = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))

        // Validate the item was uploaded.
        XCTAssertEqual(secondListResult.items.filter({ $0.path.contains(uniqueStringPath)
        }).count, 2)

        // clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "test2"))

    }

    /// Given: Give a unique key that does not exist
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute and throw an error
    func testRemoveKeyDoesNotExist() async throws {
        let key = UUID().uuidString
        let uniqueStringPath = "public/\(key)"

        do {
            _ = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))
        }
        catch {
            guard let storageError = error as? StorageError else {
                XCTFail("Error should be of type StorageError but got \(error)")
                return
            }
            guard case .keyNotFound(_, _, _, let underlyingError) = storageError else {
                XCTFail("Error should be of type keyNotFound but got \(error)")
                return
            }

            guard underlyingError is AWSS3.NotFound else {
                XCTFail("Underlying error should be of type AWSS3.NotFound but got \(error)")
                return
            }
        }
    }

    /// Given: Give a unique key where is user is NOT logged in
    /// When: `Amplify.Storage.list` is run
    /// Then: The API should execute and throw an error
    func testRemoveKeyWhenNotSignedInForPrivateKey() async throws {
        let key = UUID().uuidString
        let uniqueStringPath = "private/\(key)"

        do {
            _ = try await Amplify.Storage.list(path: .fromString(uniqueStringPath))
        }
        catch {
            guard let storageError = error as? StorageError else {
                XCTFail("Error should be of type StorageError but got \(error)")
                return
            }
            guard case .accessDenied(_, _, let underlyingError) = storageError else {
                XCTFail("Error should be of type keyNotFound but got \(error)")
                return
            }

            guard underlyingError is UnknownAWSHTTPServiceError else {
                XCTFail("Underlying error should be of type UnknownAWSHTTPServiceError but got \(error)")
                return
            }
        }
    }

    /// Given: Multiple objects uploaded to a public path
    /// When: `Amplify.Storage.list` is invoked with `subpathStrategy: .exclude`
    /// Then: The API should execute successfully and list objects for the given path, without including contens from its subpaths
    func testList_withSubpathStrategyExclude_shouldExcludeSubpaths() async throws {
        let path = UUID().uuidString
        let data = Data(path.utf8)
        let uniqueStringPath = "public/\(path)"

        // Upload data
        await wait(timeout: 25) {
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test1"), data: data, options: nil).value
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/test2"), data: data, options: nil).value
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/subpath1/test"), data: data, options: nil).value
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "/subpath2/test"), data: data, options: nil).value
        }

        let result = try await Amplify.Storage.list(
            path: .fromString("\(uniqueStringPath)/"),
            options: .init(
                subpathStrategy: .exclude
            )
        )

        // Validate result
        XCTAssertEqual(result.items.count, 2)
        XCTAssertTrue(result.items.contains(where: { $0.path.hasPrefix("\(uniqueStringPath)/test") }), "Unexpected item")
        XCTAssertEqual(result.excludedSubpaths.count, 2)
        XCTAssertTrue(result.excludedSubpaths.contains(where: { $0.hasPrefix("\(uniqueStringPath)/subpath") }), "Unexpected excluded subpath")

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test1"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/test2"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/subpath1/test"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "/subpath2/test"))
    }

    /// Given: Multiple objects uploaded to a public path
    /// When: `Amplify.Storage.list` is invoked with `subpathStrategy: .exclude(delimitedBy:)`
    /// Then: The API should execute successfully and list objects for the given path, without including contents from any subpath that is determined by the given delimiter
    func testList_withSubpathStrategyExclude_andCustomDelimiter_shouldExcludeSubpaths() async throws {
        let path = UUID().uuidString
        let data = Data(path.utf8)
        let uniqueStringPath = "public/\(path)"

        // Upload data
        await wait(timeout: 10) {
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "-test"), data: data, options: nil).value
            _ = try await Amplify.Storage.uploadData(path: .fromString(uniqueStringPath + "-subpath-test"), data: data, options: nil).value
        }

        let result = try await Amplify.Storage.list(
            path: .fromString("\(uniqueStringPath)-"),
            options: .init(
                subpathStrategy: .exclude(delimitedBy: "-")
            )
        )

        // Validate result
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.first?.path, "\(uniqueStringPath)-test")
        XCTAssertEqual(result.excludedSubpaths.count, 1)
        XCTAssertEqual(result.excludedSubpaths.first, "\(uniqueStringPath)-subpath-")

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "-test"))
        _ = try await Amplify.Storage.remove(path: .fromString(uniqueStringPath + "-subpath-test"))
    }
}

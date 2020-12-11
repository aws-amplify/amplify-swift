//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class MockAmplifyFileManager: Mock, AmplifyFileManager {
    func resolveHomeDirectoryIn(path: String) -> String {
        methodCalled("resolveHomeDirectoryIn")
        return path
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        methodCalled("createDirectory")
    }

    func createFile(atPath: String, contents: Data?) -> Bool {
        methodCalled("createFile")
        return true
    }

    func directoryExists(atPath: String) -> Bool {
        methodCalled("directoryExists")
        return true
    }

    func contentsOfDirectory(atPath: String) throws -> [String] {
        methodCalled("contentsOfDirectory")
        return [""]
    }

    func glob(pattern: String) -> [String] {
        methodCalled("glob")
        return [""]
    }
}

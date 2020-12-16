//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class MockAmplifyFileManager: Mock, AmplifyFileManager {
    func resolveHomeDirectoryIn(path: String) -> String {
        captureCall("resolveHomeDirectoryIn")
        return path
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        captureCall("createDirectory")
    }

    func createFile(atPath: String, contents: Data?) -> Bool {
        captureCall("createFile")
        return true
    }

    func directoryExists(atPath: String) -> Bool {
        captureCall("directoryExists")
        return true
    }

    func contentsOfDirectory(atPath: String) throws -> [String] {
        captureCall("contentsOfDirectory")
        return [""]
    }

    func glob(pattern: String) -> [String] {
        captureCall("glob")
        return [""]
    }
}

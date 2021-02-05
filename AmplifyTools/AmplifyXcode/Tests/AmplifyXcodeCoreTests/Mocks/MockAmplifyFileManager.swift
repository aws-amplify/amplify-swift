//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AmplifyXcodeCore

class MockAmplifyFileManager: Mock, AmplifyFileManager {
    func fileExists(atPath filePath: String) -> Bool {
        captureCall("fileExists")
        return true
    }

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

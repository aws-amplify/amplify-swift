//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PackageDescription
import AWSCLIUtils

extension Process {

    enum SPR {
        /// Returns a process for executing `swift describe --type json` in a relative path
        static func describe(packagePath: String) -> Process {
            let process = Process(["swift", "package", "describe", "--type", "json"])
            process.currentDirectoryURL = packageFileURL(packagePath: packagePath)
            return process
        }

        static func archive(name: String, packagePath: String, archiveFileURL: URL) -> Process {
            let process = Process(["swift", "package", "archive-source", "--output", urlPath(archiveFileURL)])
            process.currentDirectoryURL = packageFileURL(packagePath: packagePath)
            return process
        }

        static func checksum(archiveFileURL: URL) -> Process {
            Process(["shasum", "-b", "-a", "256", urlPath(archiveFileURL)])
        }

        private static func packageFileURL(packagePath: String) -> URL {
            URL(fileURLWithPath: packagePath).standardizedFileURL
        }
    }
}

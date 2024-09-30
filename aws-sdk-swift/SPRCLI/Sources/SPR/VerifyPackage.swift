//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

extension SPRPublisher {

    func verifyPackage() throws {
        let description = try getPackageDescription()
        guard description.name == name else {
            throw Error("Supplied name does not match package")
        }
    }

    private func getPackageDescription() throws -> Describe {
        guard let stdout = try _runReturningStdOut(Process.SPR.describe(packagePath: path)) else {
            throw Error("no stdout from Describe command")
        }
        do {
            return try JSONDecoder().decode(Describe.self, from: Data(stdout.utf8))
        } catch {
            try printError("Error occurred while parsing JSON package description.")
            throw error
        }
    }
}

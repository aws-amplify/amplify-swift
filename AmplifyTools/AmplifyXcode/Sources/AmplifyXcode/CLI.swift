//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser
import AmplifyXcodeCore

/// This module defines a CLI (Command Line Interface) to commands defined in `Core/Commands`.
/// Each "CLI command"  is the actual executor of an `AmplifyCommand`, thus it's responsible
/// for providing an environment, instantiate and execute a command.
/// The `CommandExecutable` protocol glues an `AmplifyCommand` and the environment provided by the executor.

/// CLI interface entry point `amplify-xcode`
struct AmplifyXcode: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Amplify Xcode CLI",
        subcommands: [
            CLICommandImportConfig.self,
            CLICommandImportModels.self,
            CLICommandGenerateJSONSchema.self
        ])
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

/// The following extensions on ArgumentParser commands parameters property wrappers
/// help us providing a hook to generate a JSON representation of a CLI command.
/// As for now `@PropertyWrappers` APIs to access enclosing type are still "private", so the passed
/// `parameters` allows the property to reference an external type.
/// `Argument` has been left out on purpose as we'd rather use options and flags for clarity of use.
/// Also by providing these extra initializers we make parameter name explicit.
extension Option where Value: ExpressibleByArgument {
    init(wrappedValue: Value, name: String, help: String, updating parameters: inout Set<CLICommandParameter>) {
        self.init(
            wrappedValue: wrappedValue,
            name: .customLong(name),
            parsing: .next,
            completion: nil,
            help: ArgumentHelp(help)
          )
        let type = String(describing: Value.self)
        parameters.insert(.option(name: name, type: type, help: help))
    }

    init(name: String, help: String, updating parameters: inout Set<CLICommandParameter>) {
        self.init(
            name: .customLong(name),
            parsing: .next,
            help: ArgumentHelp(help),
            completion: nil
          )
        let type = String(describing: Value.self)
        parameters.insert(.option(name: name, type: type, help: help))
    }
}

extension Flag where Value == Bool {
    init(wrappedValue: Value, name: String, help: String, updating parameters: inout Set<CLICommandParameter>) {
        self.init(wrappedValue: wrappedValue, name: .customLong(name), help: ArgumentHelp(help))
        let type = String(describing: Value.self)
        parameters.insert(.flag(name: name, type: type, help: help))
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

typealias CommandClosure = (EventDispatcher, Environment) -> Void

protocol Command {
    /// Used for deduping and cancelling commands
    var identifier: String { get }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment)
}

extension Command {
    static func basic(identifier: String, closure: @escaping CommandClosure) -> Command {
        BasicCommand(identifier: identifier, closure: closure)
    }
}

struct BasicCommand: Command {
    let identifier: String

    let closure: (EventDispatcher, Environment) -> Void

    init(
        identifier: String,
        closure: @escaping ((EventDispatcher, Environment) -> Void)
    ) {
        self.identifier = identifier
        self.closure = closure
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        closure(dispatcher, environment)
    }
}

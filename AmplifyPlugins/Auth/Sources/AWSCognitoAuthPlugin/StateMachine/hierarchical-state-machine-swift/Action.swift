//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

typealias ActionClosure = (EventDispatcher, Environment) -> Void

protocol Action {
    /// Used for deduping and cancelling actions
    var identifier: String { get }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment)
}

extension Action {
    static func basic(identifier: String, closure: @escaping ActionClosure) -> Action {
        BasicAction(identifier: identifier, closure: closure)
    }
}

struct BasicAction: Action {
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

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct StateResolution<T: State> {
    let newState: T
    let commands: [Command]

    static func from(_ state: T) -> StateResolution<T> {
        StateResolution(newState: state)
    }

    init(
        newState: T,
        commands: [Command] = []
    ) {
        self.newState = newState
        self.commands = commands
    }
}

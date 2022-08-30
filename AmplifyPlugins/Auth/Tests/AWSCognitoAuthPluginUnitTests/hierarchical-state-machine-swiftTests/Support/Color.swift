//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import HSM

enum Color: State, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case indigo
    case violet

    static var next: Event { .next }

    enum Event: StateMachineEvent {
        case next
        var id: String { "Color.Event.\(type)" }
        var type: String { "next" }
        var time: Date? { nil }
    }

    struct Resolver: StateMachineResolver {
        typealias StateType = Color
        let defaultState = Color.red
        func resolve(
            oldState: Color,
            byApplying event: StateMachineEvent
        ) -> StateResolution<Color> {
            let index = Color.allCases.firstIndex(of: oldState)!
            let newIndex = (index + 1) % Color.allCases.count
            let newValue = Color.allCases[newIndex]
            return .from(newValue)
        }
    }

    var type: String {
        String(describing: self)
    }
}

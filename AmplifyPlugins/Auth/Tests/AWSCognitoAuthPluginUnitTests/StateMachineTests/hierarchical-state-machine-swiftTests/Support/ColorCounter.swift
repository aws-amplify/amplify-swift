//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin

struct ColorCounter: State {
    let color: Color
    let counter: Counter
    /// `true` if the state has ever been `yellow` and `2` at the same time
    let hasTriggered: Bool

    var type: String {
        "\(color.type).\(counter.type)"
    }

    init(
        color: Color,
        counter: Counter,
        hasTriggered: Bool
    ) {
        self.color = color
        self.counter = counter
        self.hasTriggered = hasTriggered
    }

    struct Resolver: StateMachineResolver {
        typealias StateType = ColorCounter

        var defaultState: ColorCounter {
            ColorCounter(
                color: .red,
                counter: Counter(value: 0),
                hasTriggered: false
            )
        }

        func resolve(oldState: ColorCounter, byApplying event: StateMachineEvent) -> StateResolution<ColorCounter> {

            var builder = ColorCounter.ColorBuilder(oldState)
            var actions = [Action]()

            switch event {
            case is Counter.Event:
                let resolution = Counter
                    .Resolver()
                    .resolve(oldState: oldState.counter, byApplying: event)
                builder.counter = resolution.newState
                actions = resolution.actions

            case is Color.Event:
                let resolution = Color
                    .Resolver()
                    .resolve(oldState: oldState.color, byApplying: event)
                builder.color = resolution.newState
                actions = resolution.actions

            default:
                return .from(oldState)
            }
            resolveHasTriggered(for: &builder)
            return StateResolution(newState: builder.build(), actions: actions)
        }

        private func resolveHasTriggered(for builder: inout ColorCounter.ColorBuilder) {
            if builder.color == .yellow && builder.counter.value == 2 {
                builder.hasTriggered = true
            }
        }
    }
}

extension ColorCounter {
    struct ColorBuilder: Builder {
        typealias Product = ColorCounter
        var counter: Counter
        var color: Color
        var hasTriggered: Bool

        init(_ previousProduct: ColorCounter) {
            self.counter = previousProduct.counter
            self.color = previousProduct.color
            self.hasTriggered = previousProduct.hasTriggered
        }

        init(
            counter: Counter = Counter(value: 0),
            color: Color = .red,
            hasTriggered: Bool = false
        ) {
            self.counter = counter
            self.color = color
            self.hasTriggered = hasTriggered
        }

        func build() -> ColorCounter {
            ColorCounter(
                color: color,
                counter: counter,
                hasTriggered: hasTriggered
            )
        }
    }
}

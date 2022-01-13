//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol StateMachineResolver {
    associatedtype StateType: State

    /// The default State--that is, the state before receiving any events
    var defaultState: StateType { get }

    /// Resolves a State by evaluating `event`
    func resolve(
        oldState: StateType,
        byApplying event: StateMachineEvent
    ) -> StateResolution<StateType>
}

struct AnyResolver<StateType: State>: StateMachineResolver {
    private let doResolve: (StateType, StateMachineEvent) -> StateResolution<StateType>
    private let getDefaultState: () -> StateType

    init<ResolverType>(
        _ resolver: ResolverType
    ) where ResolverType: StateMachineResolver, ResolverType.StateType == StateType {
        self.doResolve = resolver.resolve(oldState:byApplying:)
        self.getDefaultState = { resolver.defaultState }
    }

    var defaultState: StateType {
        getDefaultState()
    }

    func resolve(oldState: StateType, byApplying event: StateMachineEvent) -> StateResolution<StateType> {
        doResolve(oldState, event)
    }
}

extension StateMachineResolver {
    func eraseToAnyResolver() -> AnyResolver<StateType> {
        if let anyResolver = self as? AnyResolver<StateType> {
            return anyResolver
        }
        return AnyResolver(self)
    }
}

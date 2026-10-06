//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import InternalAWSCognitoAuth

/// What a state machine has done so far: how many states it has published, and how many of its actions
/// are still running. Filled in by `TrackingResolver`, so a test can tell when the machine is at rest.
///
/// `StateMachine` publishes its initial state and then every resolution whose new state differs from the
/// old one; it runs every action of every resolution on a task of its own. An action that sends its events
/// with `await dispatcher.send(_:)` from its own `execute` is counted as running until they are resolved,
/// so actions those events start are counted before it ends.
///
/// `runningActions == 0` does not cover work an action leaves behind on an unstructured task it does not
/// await: `PersistCredentials`, `InitiateAuthDeviceSRP` and `DeleteUser` send their events from a `Task {}`
/// and are counted as finished as soon as they have started it. A caller must know such work is over by
/// other means; the transcript scenarios do, because each awaits the plugin API call, and the calls
/// return only on the state those events lead to.
final class MachineActivity: @unchecked Sendable {

    private let lock = NSLock()
    private var published = 1
    private var running = 0
    private let onChange: @Sendable () -> Void

    /// - Parameter onChange: Called, outside the lock, after every change.
    init(onChange: @escaping @Sendable () -> Void = {}) {
        self.onChange = onChange
    }

    /// The initial state plus every state change.
    var publishedStates: Int {
        lock.withLock { published }
    }

    var runningActions: Int {
        lock.withLock { running }
    }

    fileprivate func resolved(changedState: Bool, actions: Int) {
        lock.withLock {
            if changedState {
                published += 1
            }
            running += actions
        }
        onChange()
    }

    fileprivate func actionFinished() {
        lock.withLock { running -= 1 }
        onChange()
    }
}

/// Resolves exactly as `base` does, and records the resolution in `activity`. Each action is wrapped so
/// that its end is recorded; the wrapper only delegates, so the actions log and behave as before.
struct TrackingResolver<Base: StateMachineResolver>: StateMachineResolver {

    typealias StateType = Base.StateType

    let base: Base
    let activity: MachineActivity
    /// Called with each resolution's old and new state, before `activity` records it.
    var onResolve: (@Sendable (_ oldState: StateType, _ newState: StateType) -> Void)?

    init(
        _ base: Base,
        activity: MachineActivity,
        onResolve: (@Sendable (_ oldState: StateType, _ newState: StateType) -> Void)? = nil
    ) {
        self.base = base
        self.activity = activity
        self.onResolve = onResolve
    }

    var defaultState: StateType {
        base.defaultState
    }

    func resolve(oldState: StateType, byApplying event: StateMachineEvent) -> StateResolution<StateType> {
        let resolution = base.resolve(oldState: oldState, byApplying: event)
        onResolve?(oldState, resolution.newState)
        activity.resolved(changedState: resolution.newState != oldState, actions: resolution.actions.count)
        return StateResolution(
            newState: resolution.newState,
            actions: resolution.actions.map { TrackedAction(base: $0, activity: activity) }
        )
    }
}

private struct TrackedAction: Action {

    let base: Action
    let activity: MachineActivity

    var identifier: String {
        base.identifier
    }

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        await base.execute(withDispatcher: dispatcher, environment: environment)
        activity.actionFinished()
    }
}

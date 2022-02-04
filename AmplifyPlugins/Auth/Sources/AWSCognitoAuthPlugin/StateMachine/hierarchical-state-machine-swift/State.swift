//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A protocol describing the discrete attributes describing a system, and
/// providing mechanisms for changing those attributes in a predictable,
/// mechanistic way.
///
/// ### Properties of a State
///
/// States are immutable, mutually-exclusive, trees of value attributes:
/// - **Immutable**: States are not directly mutable. Instead, new states are
/// resolved by applying a State's `resolve` logic against the current value of the
/// state and a new `StateMachineEvent` to return a new `State` value.
/// - **Mutually exclusive**: A system's State is exactly equivalent to the set of
/// values that compose it. Thus, if two State values have identical properties,
/// they are themselves identical. From a practical standpoint, this means States
/// have value, not reference, semantics.
/// - **Trees**: Each State has its own set of attributes, and zero or more
/// substates. The "local" attributes of a State may be derived from the values of
/// its substates, or they may evolve independently in response to Events. A State
/// may have at most one "parent" State.
///
/// ### Resolving a State
///
/// States evolve mechanistically by applying resolution rules that evaluate
/// incoming Events against the current values of a State's attributes and
/// substates. The algorithm by which a State resolves an StateMachineEvent is:
///
/// - Traverse the State tree depth-first
/// - Resolve each leaf State (that is, each State that has no substates) by
/// invoking `resolve(oldState:event:)`. The return value of that method is a
/// `StateResolution` that contains both a new State, and a set of zero or more
/// `Effect`s. (See "Side effects" below)
/// - The parent State assigns the new substate value to the appropriate property,
/// and appends the returned Effects to the list of Effects to be returned in the
/// parent State's own `StateResolution`
/// - Each inner node resolves its own attributes by evaluating the new values of
/// its substates, the current values of its own properties, and the triggering
/// StateMachineEvent
/// - The inner node appends zero or more Effects to the list of effects to be
/// performed
/// - The inner node returns its new values (which are the new local values plus
/// the new values of all substates), and a list of Effects (which are the effects
/// requested by all substates, plus the effects requested by local state
/// resolution) in a `StateResolution`
/// - The process continues up to the "root" State
/// - The State Machine stores the new composite state as the new state of the
/// System
/// - The State Machine dispatches Effects for resolution and execution
///
/// ### Side effects
///
/// States may wish to perform "side effects" in response to an StateMachineEvent.
/// Side effects are interactions outside the assignment of a State's own property
/// values, such as:
/// - Emitting a new StateMachineEvent to indicate an important state change
/// - Interacting with an outside system such as making a network call or reading
/// from storage
/// - Starting or canceling a timer
///
/// Side effects are part of the return value of a State's
/// `resolve(oldState:event:)` method. They are resolved and executed by the State
/// Machine after the new State is fully resolved and applied. See `Effect` for
/// more details on Effect resolution
///
/// ### Example
///
/// Consider this State tree with the specified initial values:
///
/// ```
/// AuthState
///   isReady = false
///   authNState: AuthenticationState()
///   authZState: AuthorizationState()
///
/// AuthenticationState:
///   isSignedIn: false
///   lastSignedIn: Date? = nil
///
/// AuthorizationState:
///   isAuthorized = false
///   credentials: [String:String] = [:]
/// ```
///
/// ```
/// Event            State                              Effects
/// ---------------  -------------------------------    --------------------
/// Starting state   {  isReady: false,
/// [1]                 authNState: {
///                       isSignedIn: false,
///                       lastSignedIn: nil
///                     },
///                     authZState: {
///                       isAuthorized: false,
///                       credentials: {}
///                     }
///                  }
///
/// Event:           {  isReady: false,
///   signIn(           authNState: {                   dispatch(didSignIn) [4]
///     user,             isSignedIn: true, [3]
///     pass              lastSignedIn: 11/26 9:43am
///   )                 },
/// [2]                 authZState: {
///                       isAuthorized: false,
///                       credentials: {}
///                     }
///                  }
///
/// Event:           {  isReady: false,
///   didSignIn         authNState: {
/// [5]                   isSignedIn: true,
///                       lastSignedIn: 11/26 9:43am
///                     },
///                     authZState: {                  getCreds() {
///                       isAuthorized: false,           dispatch(didGetCreds(result))
///                       credentials: {}              }
///                     }                              [6]
///                  }
///
///
/// Event:           {  isReady: true, [9]             dispatch(authIsReady)
///   didGetCreds(      authNState: {                  [10]
///     creds             isSignedIn: true,
///   )                   lastSignedIn: 11/26 9:43am
///   [7]               },
///                     authZState: { [8]
///                       isAuthorized: true,
///                       credentials: {"token":"abc"}
///                     }
///                  }
///
/// ```
///
/// 1. The State Machine initializes. All states are initialized with their default
/// values.
/// 2. The State Machine receives a `signIn` event with the user/pass payload.
/// `AuthState` invokes `authNState.resolve(authNState, signIn)`
/// 3. For this exercise, we'll assume that the signIn event is a simple
/// validation, so `authNState` returns a new state with values of
/// `isSignedIn=true` and `lastSignedIn` set to the current timestamp.
/// 4. `authNState` returns both its new state plus an Effect to notify the the
/// state machine of the important state change
/// 5. The State Machine resolves the Effect from the last step by dispatching a
/// `didSignIn` event
/// 6. The `authNState` does not respond to this StateMachineEvent. However, the
/// `authZState` recognizes that it should take action on this, so it dispatches an
/// Effect to execute a `getCreds()` call. The completion block of that call will
/// dispatch the results in a `didGetCreds` StateMachineEvent
/// 7. The State Machine executes the Effect from the previous step, and receives a
/// `didGetCreds` when the completion block runs. The State Machine dispatches a
/// `didGetCreds` StateMachineEvent
/// 8. The `authZState` recognizes the `didGetCreds` event and updates its
/// attribute values to show `isAuthorized=true` and to store the value of the
/// retrieved credentials
/// 9. After `authZState` resolves, the parent `AuthState` inspects both the
/// `authNState.isSignedIn` and the `authZState.isAuthorized` and recognizes the
/// important state change
/// 10. The parent `AuthState` returns an Effect to dispatch an `authIsReady` event
///
/// - seealso: `Effect`
protocol State: Equatable {

    var type: String { get }
}

struct StateID: Hashable {
    let id: String
}

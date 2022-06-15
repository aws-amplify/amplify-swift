//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

class StateMachine<State, Event> {
  typealias Reducer = (State, Event) -> State
  private let queue = DispatchQueue(
    label: "com.amazonaws.Amplify.StateMachine<\(State.self), \(Event.self)>",
    target: DispatchQueue.global())
  private var reducer: Reducer
  @Published var state: State

  init(initialState: State, resolver: @escaping Reducer) {
    self.state = initialState
    self.reducer = resolver
  }

  func process(_ event: Event) {
    queue.sync {
      log.verbose("Processing event \(event) for current state \(self.state)")
      let newState = self.reducer(self.state, event)
      log.verbose("New state: \(newState)")
      self.state = newState
    }
  }
}

extension StateMachine: DefaultLogger {}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class RepeatingTimer {
  static func createRepeatingTimer(
    timeInterval: TimeInterval,
    eventHandler: @escaping BasicClosure
  ) -> DispatchSourceTimer {
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
    timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
    timer.setEventHandler(handler: eventHandler)
    return timer
  }
}

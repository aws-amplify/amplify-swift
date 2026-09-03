//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(visionOS)
import Foundation
import UIKit

/// A class for recognizing long press gesture which notifies a `TriggerDelegate` of the event
///
/// - Note: `@preconcurrency` on the `TriggerRecognizer` conformance: this type is main-actor-isolated
///   because it holds and configures UIKit objects, while `TriggerRecognizer` is not isolated, so the
///   conformance crosses isolation. Gesture callbacks only ever arrive on the main thread. This matches
///   the `@preconcurrency` conformances already on `AmplifyDevMenu`, and avoids isolating the public
///   `TriggerRecognizer` protocol.
class LongPressGestureRecognizer: NSObject, @preconcurrency TriggerRecognizer, UIGestureRecognizerDelegate {

    weak var triggerDelegate: TriggerDelegate?
    weak var uiWindow: UIWindow?
    let recognizer: UILongPressGestureRecognizer

    init(uiWindow: UIWindow) {
        self.uiWindow = uiWindow
        self.recognizer = UILongPressGestureRecognizer(target: nil, action: nil)
        self.triggerDelegate = nil
        super.init()
        registerLongPressRecognizer()
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    )
        -> Bool {
        return true
    }

    @objc private func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            triggerDelegate?.onTrigger(triggerRecognizer: self)
        }
    }

    func updateTriggerDelegate(delegate: TriggerDelegate) {
        triggerDelegate = delegate
    }

    /// Register a `UILongPressGestureRecognizer` to `uiWindow`
    /// to listen to long press events
    private func registerLongPressRecognizer() {
        recognizer.addTarget(self, action: #selector(longPressed(sender:)))
        uiWindow?.addGestureRecognizer(recognizer)
        recognizer.delegate = self
    }
}
#endif

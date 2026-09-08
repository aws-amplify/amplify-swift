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
/// - Note: `@preconcurrency` on the `TriggerRecognizer` conformance. `UIGestureRecognizerDelegate` is
///   declared `NS_SWIFT_UI_ACTOR`, so conforming to it here infers `@MainActor` for this whole class —
///   there is no explicit annotation to find, and neither `NSObject` nor the UIKit calls in the body are
///   what causes it. `TriggerRecognizer` is nonisolated, so `updateTriggerDelegate(delegate:)` becomes a
///   main-actor witness for a nonisolated requirement, which is the isolation crossing the compiler
///   objects to. `@preconcurrency` turns that into a runtime check, and the check holds: the only caller
///   through the protocol is `AmplifyDevMenu`, which is itself `@MainActor`, and gesture callbacks arrive
///   on the main thread. Isolating the public `TriggerRecognizer` protocol instead would be an API change.
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

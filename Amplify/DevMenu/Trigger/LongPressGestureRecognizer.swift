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
/// - Note: `@preconcurrency` on the `TriggerRecognizer` conformance. The class is not itself annotated
///   `@MainActor`; the isolation comes from the members it inherits and the `@MainActor` UIKit API it
///   touches, which is enough for the compiler to treat the conformance as crossing isolation.
///   `@preconcurrency` defers that to a runtime check, which holds because gesture callbacks only ever
///   arrive on the main thread. This matches the `@preconcurrency` conformances already on
///   `AmplifyDevMenu`, and avoids isolating the public `TriggerRecognizer` protocol.
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

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// A class for recognizing long press gesture which notifies a `TriggerDelegate` of the event
@available(iOS 13.0.0, *)
class LongPressGestureRecognizer: NSObject, TriggerRecognizer, UIGestureRecognizerDelegate {

    weak var triggerDelegate: TriggerDelegate?

    init(uiWindow: UIWindow) {
        super.init()
        registerLongPressRecognizer(window: uiWindow)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
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
    @available(iOS 13.0.0, *)
    private func registerLongPressRecognizer(window: UIWindow) {
        let longPressRecognizer = UILongPressGestureRecognizer(
                                    target: self,
                                    action: #selector(LongPressGestureRecognizer.longPressed(sender:)))
        longPressRecognizer.delegate = self
        window.addGestureRecognizer(longPressRecognizer)
    }
}

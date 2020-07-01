//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

@available(iOS 13.0.0, *)
class LongPressGestureRecognizer: NSObject, UIGestureRecognizerDelegate {

    weak var uiWindow: UIWindow?
    weak var triggerDelegate: TriggerDelegate?

    init(uiWindow: UIWindow, triggerDelegate: TriggerDelegate) {
        super.init()
        self.uiWindow = uiWindow
        self.triggerDelegate = triggerDelegate
        registerLongPressRecognizer()
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
        return true
    }

    @objc private func longPressed(sender: UILongPressGestureRecognizer) {
        triggerDelegate?.onTrigger()
    }

    @available(iOS 13.0.0, *)
    private func registerLongPressRecognizer() {
        let longPressRecognizer = UILongPressGestureRecognizer(
                                    target: self,
                                    action: #selector(LongPressGestureRecognizer.longPressed(sender:)))
        longPressRecognizer.delegate = self
        uiWindow?.addGestureRecognizer(longPressRecognizer)
    }
}

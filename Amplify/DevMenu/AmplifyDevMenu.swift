//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0.0, *)
public final class AmplifyDevMenu: TriggerDelegate {

    weak var devMenuDelegate: DevMenuDelegate?
    var longPressGestureRecognizer: LongPressGestureRecognizer?

    init(delegate: DevMenuDelegate) {
        self.devMenuDelegate = delegate
        self.longPressGestureRecognizer = LongPressGestureRecognizer(
                                                uiWindow: delegate.presentationContext(),
                                                triggerDelegate: self)
    }

    public func onTrigger() {
        showMenu()
    }

    private func showMenu() {
        print("showMenu")
        guard let rootViewController = devMenuDelegate?.presentationContext().rootViewController else {
            print("Warning: RootViewController is nil")
            return
        }
        let viewController = UIHostingController(rootView: AmplifyDevMenuList())
        rootViewController.present(viewController, animated: true)
    }

}

public protocol DevMenuDelegate: AnyObject {
    func presentationContext() -> UIWindow
}

public protocol TriggerDelegate: AnyObject {
    func onTrigger()
}

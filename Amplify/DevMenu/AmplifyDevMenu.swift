//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SwiftUI

/// Presents a developer menu using the provided `DevMenuPresentationContextProvider`
/// upon notification from a `TriggerRecognizer`. Default recognizer is a `LongPressGestureRecognizer`
@available(iOS 13.0.0, *)
public final class AmplifyDevMenu: DevMenuBehavior, TriggerDelegate {

    /// <#Description#>
    weak var devMenuPresentationContextProvider: DevMenuPresentationContextProvider?

    /// <#Description#>
    var triggerRecognizer: TriggerRecognizer?

    /// <#Description#>
    /// - Parameter devMenuPresentationContextProvider: <#devMenuPresentationContextProvider description#>
    init(devMenuPresentationContextProvider: DevMenuPresentationContextProvider) {
        self.devMenuPresentationContextProvider = devMenuPresentationContextProvider
        self.triggerRecognizer = LongPressGestureRecognizer(
            uiWindow: devMenuPresentationContextProvider.devMenuPresentationContext())
        triggerRecognizer?.updateTriggerDelegate(delegate: self)
    }

    /// <#Description#>
    /// - Parameter triggerRecognizer: <#triggerRecognizer description#>
    public func onTrigger(triggerRecognizer: TriggerRecognizer) {
        showMenu()
    }

    /// <#Description#>
    public func showMenu() {
        guard let rootViewController =
            devMenuPresentationContextProvider?.devMenuPresentationContext().rootViewController else {
                Amplify.Logging.warn(DevMenuStringConstants.logTag +
                    "RootViewController of the UIWindow is nil")
                return
        }
        let viewController = UIHostingController(rootView: DevMenuList())
        rootViewController.present(viewController, animated: true)
    }
}

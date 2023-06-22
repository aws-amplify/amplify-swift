//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS)
import Amplify
import UIKit

/// Mock class for presenting UI context to developer menu
class MockDevMenuContextProvider: DevMenuPresentationContextProvider {

    let uiWindow = UIWindow()

    func devMenuPresentationContext() -> UIWindow {
        return uiWindow
    }
}
#endif

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// A protocol which provides a UI context over which views can be presented
@available(iOS 13.0, *)
public protocol DevMenuPresentationContextProvider: AnyObject {
    func devMenuPresentationContext() -> UIWindow
}

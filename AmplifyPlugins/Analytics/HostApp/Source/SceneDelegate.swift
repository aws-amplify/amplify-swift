//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions
  ) {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene
    // `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see
    // `application:configurationForConnectingSceneSession` instead).
    guard scene is UIWindowScene else { return }
  }
}

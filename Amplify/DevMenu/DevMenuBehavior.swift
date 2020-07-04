//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A protocol describing the behaviors of a Developer Menu
public protocol DevMenuBehavior {
    /// Display the menu
    func showMenu()

    /// Set  a `TriggerRecognizer` to listen to corresponding trigger events for showing the developer menu
    func updateTriggerRecognizer(triggerRecognizer: TriggerRecognizer)
}

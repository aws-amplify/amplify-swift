//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A protocol to be implemented for recognizing user interaction events
/// which notifies a `TriggerDelegate` if it has one
public protocol TriggerRecognizer {
    func updateTriggerDelegate(delegate: TriggerDelegate)
}

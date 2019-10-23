//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Predictions category that clients will use
public protocol PredictionsCategoryClientBehavior {
    
    func identify()

    func infer()
}

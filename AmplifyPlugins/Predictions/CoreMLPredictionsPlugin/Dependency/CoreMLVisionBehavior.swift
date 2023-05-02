//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol CoreMLVisionBehavior: AnyObject {
    func detectLabels(_ imageURL: URL) throws -> Predictions.Identify.Labels.Result?
    func detectText(_ imageURL: URL) throws -> Predictions.Identify.Text.Result?
    func detectEntities(_ imageURL: URL) throws -> Predictions.Identify.Entities.Result?
}

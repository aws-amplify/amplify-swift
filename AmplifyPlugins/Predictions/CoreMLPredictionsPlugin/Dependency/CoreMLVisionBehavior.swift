//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol CoreMLVisionBehavior: AnyObject {
    func detectLabels(_ imageURL: URL) -> IdentifyLabelsResult?
    func detectText(_ imageURL: URL) -> IdentifyTextResult?
    func detectEntities(_ imageURL: URL) -> Predictions.Identify.Entities.Result?
}

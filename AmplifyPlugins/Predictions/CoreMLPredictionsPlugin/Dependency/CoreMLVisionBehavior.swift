//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol CoreMLVisionBehavior: class {

    func detectLabels(_ imageURL: URL) -> IdentifyLabelsResult?

    func detectText(_ imageURL: URL) -> IdentifyTextResult?
}

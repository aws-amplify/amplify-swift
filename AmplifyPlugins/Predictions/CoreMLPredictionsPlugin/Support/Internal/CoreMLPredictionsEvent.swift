//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum CoreMLPredictionsEvent<CompletedType, ErrorType: AmplifyError> {

    case completed(CompletedType)

    case failed(ErrorType)
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSTranslateOperation: AmplifyOperation<PredictionsConvertRequest, Void, Void, PredictionsError>, PredictionsConvertOperation {

    let translateService: AWSTranslateService

}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol CoreMLSpeechBehavior: class {

    func getTranscription(_ audioData: URL, callback: @escaping (SpeechToTextResult?) -> Void)
}

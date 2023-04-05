//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate

protocol AWSTranslateBehavior {

    func translateText(request: AWSTranslateTranslateTextRequest) -> AWSTask<AWSTranslateTranslateTextResponse>

    func getTranslate() -> AWSTranslate
}

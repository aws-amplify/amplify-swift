//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate

class AWSTranslateAdapter: AWSTranslateBehavior {

    let awsTranslate: AWSTranslate

    init(_ awsTranslate: AWSTranslate) {
        self.awsTranslate = awsTranslate
    }

    func translateText(request: AWSTranslateTranslateTextRequest) -> AWSTask<AWSTranslateTranslateTextResponse> {
        return awsTranslate.translateText(request)
    }

    func getTranslate() -> AWSTranslate {
        return awsTranslate
    }

}

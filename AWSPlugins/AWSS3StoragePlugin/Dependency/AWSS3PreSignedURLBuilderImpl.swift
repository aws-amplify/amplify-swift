//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

class AWSS3PreSignedURLBuilderImpl: AWSS3PreSignedURLBuilderBehavior {
    let preSignedURLBuilder: AWSS3PreSignedURLBuilder
    public init(_ preSignedURLBuilder: AWSS3PreSignedURLBuilder) {
        self.preSignedURLBuilder = preSignedURLBuilder
    }

    public func getPreSignedURL(_ getPreSignedURLRequest: AWSS3GetPreSignedURLRequest) -> AWSTask<NSURL> {
        return self.preSignedURLBuilder.getPreSignedURL(getPreSignedURLRequest)
    }
}

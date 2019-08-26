//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

public protocol AWSS3PreSignedURLBuilderBehavior {
    func getPreSignedURL(_ getPreSignedURLRequest: AWSS3GetPreSignedURLRequest) -> AWSTask<NSURL>

}

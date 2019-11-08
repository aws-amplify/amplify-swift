//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend

class AWSComprehendAdapter: AWSComprehendBehavior {

    let awsComprehend: AWSComprehend

    init(_ awsComprehend: AWSComprehend) {
        self.awsComprehend = awsComprehend
    }

    func getComprehend() -> AWSComprehend {
        return awsComprehend
    }
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSAPICategoryPlugin {
    var log: Logger {
        Amplify.Logging.logger(forCategory: key)
    }
}

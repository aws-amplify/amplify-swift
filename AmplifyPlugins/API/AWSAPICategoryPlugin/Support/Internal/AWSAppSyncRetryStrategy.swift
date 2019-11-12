//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AWSAppSyncRetryStrategy {

    ///  Backs off exponentially before retrying a HTTP request. Starts from 400ms and grows exponentially
    /// w/ jitter; stops the retries after the back off reaches 5 minutes.
    case exponential

    /// Aggressively retries every 1s w/ jitter for up to 12 attempts.
    case aggressive
}

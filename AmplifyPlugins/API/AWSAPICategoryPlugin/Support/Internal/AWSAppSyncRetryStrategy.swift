//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// The retry strategy to be used by the `AWSAppSyncClient`.
/// You can specify this in the `AWSAppSyncClientConfiguration`.
///
/// - exponential: Backs off exponentially before retrying a HTTP request. Starts from 400ms and grows exponentially w/ jitter; stops the retries after the back off reaches 5 minutes.
/// - aggressive: Aggressively retries every 1s w/ jitter for up to 12 attempts.
public enum AWSAppSyncRetryStrategy {
    case exponential, aggressive
}

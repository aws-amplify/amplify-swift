//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore

public struct AWSIAMConfiguration {
    public let region: AWSRegionType

    public init(region: AWSRegionType) {
        self.region = region
    }
}

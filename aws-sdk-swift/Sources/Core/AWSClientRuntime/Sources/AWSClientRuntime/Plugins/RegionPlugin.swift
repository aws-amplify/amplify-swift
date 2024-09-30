//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public class RegionPlugin: Plugin {
    private var region: String

    public init(_ region: String) {
        self.region = region
    }

    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? AWSRegionClientConfiguration {
            config.region = self.region
            config.signingRegion = self.region
        }
    }
}

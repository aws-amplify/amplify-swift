//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class MockProvisioningProfileReader: ProvisioningProfileReader {
    var mockedProfile: ProvisioningProfile?

    func profile() -> ProvisioningProfile? {
        return mockedProfile
    }
}

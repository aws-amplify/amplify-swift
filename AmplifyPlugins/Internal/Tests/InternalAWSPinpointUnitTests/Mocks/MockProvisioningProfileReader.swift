//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class MockProvisioningProfileReader: ProvisioningProfileReader {
    var mockedProfile: ProvisioningProfile? {
        didSet {
            print("ROBOCITO: Set mockedProfile to \(mockedProfile)")
        }
    }

    func profile() -> ProvisioningProfile? {
        return mockedProfile
    }
}

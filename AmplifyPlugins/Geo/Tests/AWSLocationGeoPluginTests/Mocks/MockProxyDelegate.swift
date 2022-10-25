//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreLocation

class MockProxyDelegate: LocationProxyDelegate {
    
    // MARK: - Method call counts for MockProxyDelegate
    static var didUpdateLocationsCalled = 0
    
    var didUpdateLocations: (CLLocationManager, [CLLocation]) -> Void = {
        manager, locations in
        MockProxyDelegate.didUpdateLocationsCalled += 1
    }

}

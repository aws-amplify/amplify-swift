//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension AWSMobileClient: Resettable {

    /// Resets the AWSMobileClient for tests
    ///
    /// We cannot fully reset AWSMobileClient because it is a singleton object. The same instance of AWSMobileClient
    /// will be re-used between different tests. In this reset method, we just try to mock a reset behavior by signing
    /// out any user, clearing credentials and clearing keychain. Before calling this method make sure to remove all the
    /// listeners that are listening to AWSMobileClient.
    public func reset(onComplete: @escaping BasicClosure) {
        signOut()
        clearCredentials()
        clearKeychain()
        onComplete()
    }
}

//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient
import AWSS3

public class AWSAuthService: AWSAuthServiceBehavior {

    var mobileClient: AWSMobileClientBehavior!

    public init() {
    }

    func configure() {
        // TODO any validation on mobile client instance?
        configure(mobileClient: AWSMobileClientImpl(AWSMobileClient.sharedInstance()))
    }

    func configure(mobileClient: AWSMobileClientBehavior) {
        self.mobileClient = mobileClient
    }

    func reset() {
        self.mobileClient = nil
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return mobileClient.getCognitoCredentialsProvider()
    }

    func getIdentityId() -> Result<String, Error> {
        let task = mobileClient.getIdentityId()
        task.waitUntilFinished()

        guard task.error == nil else {
            //let error = task.error!
            // MAP Error

            let error = StorageGetError.unknown("Error in getIdneittyId", "no identity!")
            return Result.failure(error)
        }

        guard let identityId = task.result else {
            let error = StorageGetError.unknown("No Identity", "no identity!")
            return Result.failure(error)

        }

        return .success(identityId as String)
    }
}

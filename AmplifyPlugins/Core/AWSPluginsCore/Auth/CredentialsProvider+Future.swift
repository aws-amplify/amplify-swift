//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AwsCommonRuntimeKit
import AWSClientRuntime
import ClientRuntime

extension CredentialsProvider {
    func getCredentials() throws -> SdkFuture<AWSCredentials> {
        let future = Future<AWSCredentials>()
        Task {
            do {
                let credentials = try await getCredentials()
                future.fulfill(credentials)
            } catch {
                let error = AuthError.unknown("Auth session does not include AWS credentials information")
                future.fail(error)
            }
        }
        return future
    }
}

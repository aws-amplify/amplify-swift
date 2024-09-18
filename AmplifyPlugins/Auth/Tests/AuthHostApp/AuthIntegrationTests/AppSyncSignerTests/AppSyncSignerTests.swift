//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AppSyncSignerTests: AWSAuthBaseTest {

    /// Test signing an AppSync request with a live credentials provider
    ///
    /// - Given: Base test configures Amplify and adds AWSCognitoAuthPlugin
    /// - When:
    ///    - I invoke AWSCognitoAuthPlugin's AppSync signer
    /// - Then:
    ///    - I should get a signed request.
    ///
    func testSignAppSyncRequest() async throws {
        let request = URLRequest(url: URL(string: "http://graphql.com?param=value")!)
        let signer = AWSCognitoAuthPlugin.createAppSyncSigner(region: "us-east-1")
        let signedRequest = try await signer(request)
        guard let headers = signedRequest.allHTTPHeaderFields else {
            XCTFail("Missing headers")
            return
        }
        XCTAssertEqual(headers.count, 4)
        let containsExpectedHeaders = headers.keys.contains(where: { key in
            key == "Authorization" || key == "Host" || key == "X-Amz-Security-Token" || key == "X-Amz-Date"
        })
        XCTAssertTrue(containsExpectedHeaders)
    }
}

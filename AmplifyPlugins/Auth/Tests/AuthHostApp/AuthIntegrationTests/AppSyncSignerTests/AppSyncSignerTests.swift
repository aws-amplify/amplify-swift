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
    ///    - I invoke AWSCognitoAuthPlugin.signAppSyncRequest(request, region)
    /// - Then:
    ///    - I should get a signed request.
    ///
    func testSignAppSyncRequest() async throws {
        let request = URLRequest(url: URL(string: "http://graphql.com")!)
        let signedRequest = try await AWSCognitoAuthPlugin.signAppSyncRequest(request, region: "us-east-1")

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

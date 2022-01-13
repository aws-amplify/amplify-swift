//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

struct MockSessionFactory: URLSessionBehaviorFactory {
    let session: MockURLSession

    init(returning session: MockURLSession) {
        self.session = session
    }

    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior {
        session.sessionBehaviorDelegate = delegate
        return session
    }
}

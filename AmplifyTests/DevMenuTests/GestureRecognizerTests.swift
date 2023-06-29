//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) && !os(xrOS)
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

@available(iOS 13.0.0, *)
class GestureRecognizerTests: XCTestCase {

    /// Test if long press gesture recognizer is added to UIWindow
    ///
    /// - Given: `LongPressGestureRecognizer` is initialized
    /// - When:
    ///    - I check if the `UIWindow` contains the `UILongPressGestureRecognizer`instance
    ///    inside `LongPressGestureRecognizer`
    /// - Then:
    ///    - It should return true

    func testGestureRecognizerAddedToWindow() {
        let contextProvider = MockDevMenuContextProvider()
        let longPressGestureRecognizer =
            LongPressGestureRecognizer(uiWindow: contextProvider.devMenuPresentationContext())
        if let recognizerList = contextProvider.devMenuPresentationContext().gestureRecognizers {
            XCTAssertTrue(recognizerList.contains(longPressGestureRecognizer.recognizer))
        } else {
            XCTFail("List of recognizers added to UIWindow is nil")
        }
    }

}
#endif

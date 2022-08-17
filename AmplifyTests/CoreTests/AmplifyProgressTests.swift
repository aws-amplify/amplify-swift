//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
#if canImport(Combine)
import Combine
#endif

@testable import Amplify
@testable import AmplifyTestCommon

class AmplifyProgressTests: XCTestCase {
    
    func testConvertingProgress() {
        let progress = Progress.discreteProgress(totalUnitCount: 10)
        progress.completedUnitCount = 5
        XCTAssertEqual(progress.fractionCompleted, 0.5)
        let amplifyProgress = AmplifyProgress(progress: progress)
        
        XCTAssertEqual(progress.totalUnitCount, Int64(amplifyProgress.totalUnitCount))
        XCTAssertEqual(progress.completedUnitCount, Int64(amplifyProgress.completedUnitCount))
        XCTAssertEqual(progress.fractionCompleted, amplifyProgress.fractionCompleted)
        
        let convertedProgress = Progress(progress: amplifyProgress)

        XCTAssertEqual(progress.totalUnitCount, convertedProgress.totalUnitCount)
        XCTAssertEqual(progress.completedUnitCount, convertedProgress.completedUnitCount)
        XCTAssertEqual(progress.fractionCompleted, convertedProgress.fractionCompleted)

        XCTAssertEqual(convertedProgress.totalUnitCount, Int64(amplifyProgress.totalUnitCount))
        XCTAssertEqual(convertedProgress.completedUnitCount, Int64(amplifyProgress.completedUnitCount))
        XCTAssertEqual(convertedProgress.fractionCompleted, amplifyProgress.fractionCompleted)
    }

}

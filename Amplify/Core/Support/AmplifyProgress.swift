//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Progress type which conforms to Sendable
public struct AmplifyProgress: Sendable {
    public let fractionCompleted: Double
    public let totalUnitCount: Int
    public let completedUnitCount: Int
    
    public init(progress: Progress) {
        self.fractionCompleted = progress.fractionCompleted
        self.totalUnitCount = Int(progress.totalUnitCount)
        self.completedUnitCount = Int(progress.completedUnitCount)
    }
}

public extension Progress {
    convenience init(progress: AmplifyProgress) {
        self.init(totalUnitCount: Int64(progress.totalUnitCount))
        completedUnitCount = Int64(progress.completedUnitCount)
    }
}

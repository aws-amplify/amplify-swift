//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

/// A class that enables lazy loading a value.
/// This is useful when you want to lazy load a value within a local scope.
public class LazyValue<T> {
    public lazy var value: T = {
        do {
            return try valueProducer()
        } catch {
            log(level: .error, "\(error.localizedDescription)")
            fatalError(error.localizedDescription)
        }
    }()
    private let valueProducer: () throws -> T
    public init(_ valueProducer: @escaping () throws -> T) {
        self.valueProducer = valueProducer
    }
}

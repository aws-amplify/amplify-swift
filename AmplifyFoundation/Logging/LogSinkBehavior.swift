//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol LogSinkBehavior: Identifiable {
    var id: String { get }
    
    func isEnabled(for logLevel: LogLevel) -> Bool
    
    func emit(message: LogMessage)
}

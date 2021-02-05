//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Command execution result type.
/// A failure in any underlying task results in the overall command failing.
public typealias AmplifyCommandResult = Result<[AmplifyCommandTaskResult], AmplifyCommandError>

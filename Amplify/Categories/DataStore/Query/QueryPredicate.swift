//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that indicates concrete types conforming to it can be used a predicate member.
public protocol QueryPredicate: Evaluable, Encodable {}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import Foundation
import SmithyHTTPAPI

public typealias NetworkResult = (Result<HTTPResponse, Error>) -> Void

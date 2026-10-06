//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// `Amplify`'s `Logger`, for the `EngineBridge/` files that also import `AmplifyFoundation`.
///
/// Both modules declare `Logger` and `LogLevel`, and `Amplify.Logger` cannot disambiguate them,
/// because there `Amplify` resolves to the `Amplify` class rather than the module. This file
/// imports only `Amplify`, so the names here are unambiguous.
typealias AmplifyCategoryLogger = Logger

/// `Amplify`'s `LogLevel`. See `AmplifyCategoryLogger`.
typealias AmplifyCategoryLogLevel = LogLevel

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime

struct EndpointResolving {
    let run: (String) throws -> ClientRuntime.Endpoint
}

extension EndpointResolving {
    private static func validate<T, U>(
        _ input: T,
        with validationStep: ValidationStep<T, U>
    ) throws -> U {
        try validationStep.validate(input)
    }
    
    static let userPool = EndpointResolving { endpoint in
        // We want to enforce that the endpoint is excluded from the
        // configuration so as not to give the impression that other
        // schemes are supported. While we could check for, and allow,
        // explicit `https` input as a convenience, that would provide
        // two valid paths and be an unnecessary source of confusion.
        // So we're going to fail if any scheme is included
        // in the configuration.
        try validate(endpoint, with: .schemeIsEmpty())
        
        // Next let's prepend the https scheme and confirm that the url
        // itself is valid. If not, we'll throw an error.
        let (components, host) = try validate(endpoint, with: .validURL())
        
        // Finally, let's confirm that the endpoint doesn't contain a path.
        try validate((components, endpoint), with: .pathIsEmpty())
        
        return ClientRuntime.Endpoint(host: host)
    }
}

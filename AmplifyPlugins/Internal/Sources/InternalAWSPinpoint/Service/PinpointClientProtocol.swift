//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

public protocol PinpointClientProtocol {

    /// Performs the `UpdateEndpoint` operation on the `Pinpoint` service.
    ///
    /// Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes for an endpoint. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
    ///
    /// - Parameter UpdateEndpointInput : [no documentation found]
    ///
    /// - Returns: `UpdateEndpointOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `NotFoundException` : Provides information about an API request or response.
    /// - `PayloadTooLargeException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func updateEndpoint(input: UpdateEndpointInput) async throws -> UpdateEndpointOutput

    /// Performs the `PutEvents` operation on the `Pinpoint` service.
    ///
    /// Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
    ///
    /// - Parameter PutEventsInput : [no documentation found]
    ///
    /// - Returns: `PutEventsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `NotFoundException` : Provides information about an API request or response.
    /// - `PayloadTooLargeException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func putEvents(input: PutEventsInput) async throws -> PutEventsOutput

    /// Performs the `DeleteUserEndpoints` operation on the `Pinpoint` service.
    ///
    /// Deletes all the endpoints that are associated with a specific user ID.
    ///
    /// - Parameter DeleteUserEndpointsInput : [no documentation found]
    ///
    /// - Returns: `DeleteUserEndpointsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `NotFoundException` : Provides information about an API request or response.
    /// - `PayloadTooLargeException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func deleteUserEndpoints(input: DeleteUserEndpointsInput) async throws -> DeleteUserEndpointsOutput

}

extension PinpointClient: PinpointClientProtocol { }

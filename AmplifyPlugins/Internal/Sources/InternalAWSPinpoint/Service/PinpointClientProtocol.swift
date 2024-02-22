//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

// swiftlint:disable file_length
public protocol PinpointClientProtocol {
    /// Performs the `CreateApp` operation on the `Pinpoint` service.
    ///
    /// Creates an application.
    ///
    /// - Parameter CreateAppInput : [no documentation found]
    ///
    /// - Returns: `CreateAppOutput` : [no documentation found]
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
    func createApp(input: CreateAppInput) async throws -> CreateAppOutput
    /// Performs the `CreateCampaign` operation on the `Pinpoint` service.
    ///
    /// Creates a new campaign for an application or updates the settings of an existing campaign for an application.
    ///
    /// - Parameter CreateCampaignInput : [no documentation found]
    ///
    /// - Returns: `CreateCampaignOutput` : [no documentation found]
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
    func createCampaign(input: CreateCampaignInput) async throws -> CreateCampaignOutput
    /// Performs the `CreateEmailTemplate` operation on the `Pinpoint` service.
    ///
    /// Creates a message template for messages that are sent through the email channel.
    ///
    /// - Parameter CreateEmailTemplateInput : [no documentation found]
    ///
    /// - Returns: `CreateEmailTemplateOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func createEmailTemplate(input: CreateEmailTemplateInput) async throws -> CreateEmailTemplateOutput
    /// Performs the `CreateExportJob` operation on the `Pinpoint` service.
    ///
    /// Creates an export job for an application.
    ///
    /// - Parameter CreateExportJobInput : [no documentation found]
    ///
    /// - Returns: `CreateExportJobOutput` : [no documentation found]
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
    func createExportJob(input: CreateExportJobInput) async throws -> CreateExportJobOutput
    /// Performs the `CreateImportJob` operation on the `Pinpoint` service.
    ///
    /// Creates an import job for an application.
    ///
    /// - Parameter CreateImportJobInput : [no documentation found]
    ///
    /// - Returns: `CreateImportJobOutput` : [no documentation found]
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
    func createImportJob(input: CreateImportJobInput) async throws -> CreateImportJobOutput
    /// Performs the `CreateInAppTemplate` operation on the `Pinpoint` service.
    ///
    /// Creates a new message template for messages using the in-app message channel.
    ///
    /// - Parameter CreateInAppTemplateInput : [no documentation found]
    ///
    /// - Returns: `CreateInAppTemplateOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func createInAppTemplate(input: CreateInAppTemplateInput) async throws -> CreateInAppTemplateOutput
    /// Performs the `CreateJourney` operation on the `Pinpoint` service.
    ///
    /// Creates a journey for an application.
    ///
    /// - Parameter CreateJourneyInput : [no documentation found]
    ///
    /// - Returns: `CreateJourneyOutput` : [no documentation found]
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
    func createJourney(input: CreateJourneyInput) async throws -> CreateJourneyOutput
    /// Performs the `CreatePushTemplate` operation on the `Pinpoint` service.
    ///
    /// Creates a message template for messages that are sent through a push notification channel.
    ///
    /// - Parameter CreatePushTemplateInput : [no documentation found]
    ///
    /// - Returns: `CreatePushTemplateOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func createPushTemplate(input: CreatePushTemplateInput) async throws -> CreatePushTemplateOutput
    /// Performs the `CreateRecommenderConfiguration` operation on the `Pinpoint` service.
    ///
    /// Creates an Amazon Pinpoint configuration for a recommender model.
    ///
    /// - Parameter CreateRecommenderConfigurationInput : [no documentation found]
    ///
    /// - Returns: `CreateRecommenderConfigurationOutput` : [no documentation found]
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
    func createRecommenderConfiguration(input: CreateRecommenderConfigurationInput) async throws -> CreateRecommenderConfigurationOutput
    /// Performs the `CreateSegment` operation on the `Pinpoint` service.
    ///
    /// Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
    ///
    /// - Parameter CreateSegmentInput : [no documentation found]
    ///
    /// - Returns: `CreateSegmentOutput` : [no documentation found]
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
    func createSegment(input: CreateSegmentInput) async throws -> CreateSegmentOutput
    /// Performs the `CreateSmsTemplate` operation on the `Pinpoint` service.
    ///
    /// Creates a message template for messages that are sent through the SMS channel.
    ///
    /// - Parameter CreateSmsTemplateInput : [no documentation found]
    ///
    /// - Returns: `CreateSmsTemplateOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func createSmsTemplate(input: CreateSmsTemplateInput) async throws -> CreateSmsTemplateOutput
    /// Performs the `CreateVoiceTemplate` operation on the `Pinpoint` service.
    ///
    /// Creates a message template for messages that are sent through the voice channel.
    ///
    /// - Parameter CreateVoiceTemplateInput : [no documentation found]
    ///
    /// - Returns: `CreateVoiceTemplateOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func createVoiceTemplate(input: CreateVoiceTemplateInput) async throws -> CreateVoiceTemplateOutput
    /// Performs the `DeleteAdmChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the ADM channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteAdmChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteAdmChannelOutput` : [no documentation found]
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
    func deleteAdmChannel(input: DeleteAdmChannelInput) async throws -> DeleteAdmChannelOutput
    /// Performs the `DeleteApnsChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the APNs channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteApnsChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteApnsChannelOutput` : [no documentation found]
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
    func deleteApnsChannel(input: DeleteApnsChannelInput) async throws -> DeleteApnsChannelOutput
    /// Performs the `DeleteApnsSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteApnsSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteApnsSandboxChannelOutput` : [no documentation found]
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
    func deleteApnsSandboxChannel(input: DeleteApnsSandboxChannelInput) async throws -> DeleteApnsSandboxChannelOutput
    /// Performs the `DeleteApnsVoipChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteApnsVoipChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteApnsVoipChannelOutput` : [no documentation found]
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
    func deleteApnsVoipChannel(input: DeleteApnsVoipChannelInput) async throws -> DeleteApnsVoipChannelOutput
    /// Performs the `DeleteApnsVoipSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteApnsVoipSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteApnsVoipSandboxChannelOutput` : [no documentation found]
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
    func deleteApnsVoipSandboxChannel(input: DeleteApnsVoipSandboxChannelInput) async throws -> DeleteApnsVoipSandboxChannelOutput
    /// Performs the `DeleteApp` operation on the `Pinpoint` service.
    ///
    /// Deletes an application.
    ///
    /// - Parameter DeleteAppInput : [no documentation found]
    ///
    /// - Returns: `DeleteAppOutput` : [no documentation found]
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
    func deleteApp(input: DeleteAppInput) async throws -> DeleteAppOutput
    /// Performs the `DeleteBaiduChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the Baidu channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteBaiduChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteBaiduChannelOutput` : [no documentation found]
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
    func deleteBaiduChannel(input: DeleteBaiduChannelInput) async throws -> DeleteBaiduChannelOutput
    /// Performs the `DeleteCampaign` operation on the `Pinpoint` service.
    ///
    /// Deletes a campaign from an application.
    ///
    /// - Parameter DeleteCampaignInput : [no documentation found]
    ///
    /// - Returns: `DeleteCampaignOutput` : [no documentation found]
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
    func deleteCampaign(input: DeleteCampaignInput) async throws -> DeleteCampaignOutput
    /// Performs the `DeleteEmailChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the email channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteEmailChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteEmailChannelOutput` : [no documentation found]
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
    func deleteEmailChannel(input: DeleteEmailChannelInput) async throws -> DeleteEmailChannelOutput
    /// Performs the `DeleteEmailTemplate` operation on the `Pinpoint` service.
    ///
    /// Deletes a message template for messages that were sent through the email channel.
    ///
    /// - Parameter DeleteEmailTemplateInput : [no documentation found]
    ///
    /// - Returns: `DeleteEmailTemplateOutput` : [no documentation found]
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
    func deleteEmailTemplate(input: DeleteEmailTemplateInput) async throws -> DeleteEmailTemplateOutput
    /// Performs the `DeleteEndpoint` operation on the `Pinpoint` service.
    ///
    /// Deletes an endpoint from an application.
    ///
    /// - Parameter DeleteEndpointInput : [no documentation found]
    ///
    /// - Returns: `DeleteEndpointOutput` : [no documentation found]
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
    func deleteEndpoint(input: DeleteEndpointInput) async throws -> DeleteEndpointOutput
    /// Performs the `DeleteEventStream` operation on the `Pinpoint` service.
    ///
    /// Deletes the event stream for an application.
    ///
    /// - Parameter DeleteEventStreamInput : [no documentation found]
    ///
    /// - Returns: `DeleteEventStreamOutput` : [no documentation found]
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
    func deleteEventStream(input: DeleteEventStreamInput) async throws -> DeleteEventStreamOutput
    /// Performs the `DeleteGcmChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the GCM channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteGcmChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteGcmChannelOutput` : [no documentation found]
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
    func deleteGcmChannel(input: DeleteGcmChannelInput) async throws -> DeleteGcmChannelOutput
    /// Performs the `DeleteInAppTemplate` operation on the `Pinpoint` service.
    ///
    /// Deletes a message template for messages sent using the in-app message channel.
    ///
    /// - Parameter DeleteInAppTemplateInput : [no documentation found]
    ///
    /// - Returns: `DeleteInAppTemplateOutput` : [no documentation found]
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
    func deleteInAppTemplate(input: DeleteInAppTemplateInput) async throws -> DeleteInAppTemplateOutput
    /// Performs the `DeleteJourney` operation on the `Pinpoint` service.
    ///
    /// Deletes a journey from an application.
    ///
    /// - Parameter DeleteJourneyInput : [no documentation found]
    ///
    /// - Returns: `DeleteJourneyOutput` : [no documentation found]
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
    func deleteJourney(input: DeleteJourneyInput) async throws -> DeleteJourneyOutput
    /// Performs the `DeletePushTemplate` operation on the `Pinpoint` service.
    ///
    /// Deletes a message template for messages that were sent through a push notification channel.
    ///
    /// - Parameter DeletePushTemplateInput : [no documentation found]
    ///
    /// - Returns: `DeletePushTemplateOutput` : [no documentation found]
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
    func deletePushTemplate(input: DeletePushTemplateInput) async throws -> DeletePushTemplateOutput
    /// Performs the `DeleteRecommenderConfiguration` operation on the `Pinpoint` service.
    ///
    /// Deletes an Amazon Pinpoint configuration for a recommender model.
    ///
    /// - Parameter DeleteRecommenderConfigurationInput : [no documentation found]
    ///
    /// - Returns: `DeleteRecommenderConfigurationOutput` : [no documentation found]
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
    func deleteRecommenderConfiguration(input: DeleteRecommenderConfigurationInput) async throws -> DeleteRecommenderConfigurationOutput
    /// Performs the `DeleteSegment` operation on the `Pinpoint` service.
    ///
    /// Deletes a segment from an application.
    ///
    /// - Parameter DeleteSegmentInput : [no documentation found]
    ///
    /// - Returns: `DeleteSegmentOutput` : [no documentation found]
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
    func deleteSegment(input: DeleteSegmentInput) async throws -> DeleteSegmentOutput
    /// Performs the `DeleteSmsChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the SMS channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteSmsChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteSmsChannelOutput` : [no documentation found]
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
    func deleteSmsChannel(input: DeleteSmsChannelInput) async throws -> DeleteSmsChannelOutput
    /// Performs the `DeleteSmsTemplate` operation on the `Pinpoint` service.
    ///
    /// Deletes a message template for messages that were sent through the SMS channel.
    ///
    /// - Parameter DeleteSmsTemplateInput : [no documentation found]
    ///
    /// - Returns: `DeleteSmsTemplateOutput` : [no documentation found]
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
    func deleteSmsTemplate(input: DeleteSmsTemplateInput) async throws -> DeleteSmsTemplateOutput
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
    /// Performs the `DeleteVoiceChannel` operation on the `Pinpoint` service.
    ///
    /// Disables the voice channel for an application and deletes any existing settings for the channel.
    ///
    /// - Parameter DeleteVoiceChannelInput : [no documentation found]
    ///
    /// - Returns: `DeleteVoiceChannelOutput` : [no documentation found]
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
    func deleteVoiceChannel(input: DeleteVoiceChannelInput) async throws -> DeleteVoiceChannelOutput
    /// Performs the `DeleteVoiceTemplate` operation on the `Pinpoint` service.
    ///
    /// Deletes a message template for messages that were sent through the voice channel.
    ///
    /// - Parameter DeleteVoiceTemplateInput : [no documentation found]
    ///
    /// - Returns: `DeleteVoiceTemplateOutput` : [no documentation found]
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
    func deleteVoiceTemplate(input: DeleteVoiceTemplateInput) async throws -> DeleteVoiceTemplateOutput
    /// Performs the `GetAdmChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the ADM channel for an application.
    ///
    /// - Parameter GetAdmChannelInput : [no documentation found]
    ///
    /// - Returns: `GetAdmChannelOutput` : [no documentation found]
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
    func getAdmChannel(input: GetAdmChannelInput) async throws -> GetAdmChannelOutput
    /// Performs the `GetApnsChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the APNs channel for an application.
    ///
    /// - Parameter GetApnsChannelInput : [no documentation found]
    ///
    /// - Returns: `GetApnsChannelOutput` : [no documentation found]
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
    func getApnsChannel(input: GetApnsChannelInput) async throws -> GetApnsChannelOutput
    /// Performs the `GetApnsSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the APNs sandbox channel for an application.
    ///
    /// - Parameter GetApnsSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `GetApnsSandboxChannelOutput` : [no documentation found]
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
    func getApnsSandboxChannel(input: GetApnsSandboxChannelInput) async throws -> GetApnsSandboxChannelOutput
    /// Performs the `GetApnsVoipChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the APNs VoIP channel for an application.
    ///
    /// - Parameter GetApnsVoipChannelInput : [no documentation found]
    ///
    /// - Returns: `GetApnsVoipChannelOutput` : [no documentation found]
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
    func getApnsVoipChannel(input: GetApnsVoipChannelInput) async throws -> GetApnsVoipChannelOutput
    /// Performs the `GetApnsVoipSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
    ///
    /// - Parameter GetApnsVoipSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `GetApnsVoipSandboxChannelOutput` : [no documentation found]
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
    func getApnsVoipSandboxChannel(input: GetApnsVoipSandboxChannelInput) async throws -> GetApnsVoipSandboxChannelOutput
    /// Performs the `GetApp` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about an application.
    ///
    /// - Parameter GetAppInput : [no documentation found]
    ///
    /// - Returns: `GetAppOutput` : [no documentation found]
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
    func getApp(input: GetAppInput) async throws -> GetAppOutput
    /// Performs the `GetApplicationDateRangeKpi` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
    ///
    /// - Parameter GetApplicationDateRangeKpiInput : [no documentation found]
    ///
    /// - Returns: `GetApplicationDateRangeKpiOutput` : [no documentation found]
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
    func getApplicationDateRangeKpi(input: GetApplicationDateRangeKpiInput) async throws -> GetApplicationDateRangeKpiOutput
    /// Performs the `GetApplicationSettings` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the settings for an application.
    ///
    /// - Parameter GetApplicationSettingsInput : [no documentation found]
    ///
    /// - Returns: `GetApplicationSettingsOutput` : [no documentation found]
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
    func getApplicationSettings(input: GetApplicationSettingsInput) async throws -> GetApplicationSettingsOutput
    /// Performs the `GetApps` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
    ///
    /// - Parameter GetAppsInput : [no documentation found]
    ///
    /// - Returns: `GetAppsOutput` : [no documentation found]
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
    func getApps(input: GetAppsInput) async throws -> GetAppsOutput
    /// Performs the `GetBaiduChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the Baidu channel for an application.
    ///
    /// - Parameter GetBaiduChannelInput : [no documentation found]
    ///
    /// - Returns: `GetBaiduChannelOutput` : [no documentation found]
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
    func getBaiduChannel(input: GetBaiduChannelInput) async throws -> GetBaiduChannelOutput
    /// Performs the `GetCampaign` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for a campaign.
    ///
    /// - Parameter GetCampaignInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignOutput` : [no documentation found]
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
    func getCampaign(input: GetCampaignInput) async throws -> GetCampaignOutput
    /// Performs the `GetCampaignActivities` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the activities for a campaign.
    ///
    /// - Parameter GetCampaignActivitiesInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignActivitiesOutput` : [no documentation found]
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
    func getCampaignActivities(input: GetCampaignActivitiesInput) async throws -> GetCampaignActivitiesOutput
    /// Performs the `GetCampaignDateRangeKpi` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
    ///
    /// - Parameter GetCampaignDateRangeKpiInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignDateRangeKpiOutput` : [no documentation found]
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
    func getCampaignDateRangeKpi(input: GetCampaignDateRangeKpiInput) async throws -> GetCampaignDateRangeKpiOutput
    /// Performs the `GetCampaigns` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
    ///
    /// - Parameter GetCampaignsInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignsOutput` : [no documentation found]
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
    func getCampaigns(input: GetCampaignsInput) async throws -> GetCampaignsOutput
    /// Performs the `GetCampaignVersion` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
    ///
    /// - Parameter GetCampaignVersionInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignVersionOutput` : [no documentation found]
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
    func getCampaignVersion(input: GetCampaignVersionInput) async throws -> GetCampaignVersionOutput
    /// Performs the `GetCampaignVersions` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for all versions of a campaign.
    ///
    /// - Parameter GetCampaignVersionsInput : [no documentation found]
    ///
    /// - Returns: `GetCampaignVersionsOutput` : [no documentation found]
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
    func getCampaignVersions(input: GetCampaignVersionsInput) async throws -> GetCampaignVersionsOutput
    /// Performs the `GetChannels` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the history and status of each channel for an application.
    ///
    /// - Parameter GetChannelsInput : [no documentation found]
    ///
    /// - Returns: `GetChannelsOutput` : [no documentation found]
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
    func getChannels(input: GetChannelsInput) async throws -> GetChannelsOutput
    /// Performs the `GetEmailChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the email channel for an application.
    ///
    /// - Parameter GetEmailChannelInput : [no documentation found]
    ///
    /// - Returns: `GetEmailChannelOutput` : [no documentation found]
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
    func getEmailChannel(input: GetEmailChannelInput) async throws -> GetEmailChannelOutput
    /// Performs the `GetEmailTemplate` operation on the `Pinpoint` service.
    ///
    /// Retrieves the content and settings of a message template for messages that are sent through the email channel.
    ///
    /// - Parameter GetEmailTemplateInput : [no documentation found]
    ///
    /// - Returns: `GetEmailTemplateOutput` : [no documentation found]
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
    func getEmailTemplate(input: GetEmailTemplateInput) async throws -> GetEmailTemplateOutput
    /// Performs the `GetEndpoint` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the settings and attributes of a specific endpoint for an application.
    ///
    /// - Parameter GetEndpointInput : [no documentation found]
    ///
    /// - Returns: `GetEndpointOutput` : [no documentation found]
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
    func getEndpoint(input: GetEndpointInput) async throws -> GetEndpointOutput
    /// Performs the `GetEventStream` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the event stream settings for an application.
    ///
    /// - Parameter GetEventStreamInput : [no documentation found]
    ///
    /// - Returns: `GetEventStreamOutput` : [no documentation found]
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
    func getEventStream(input: GetEventStreamInput) async throws -> GetEventStreamOutput
    /// Performs the `GetExportJob` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of a specific export job for an application.
    ///
    /// - Parameter GetExportJobInput : [no documentation found]
    ///
    /// - Returns: `GetExportJobOutput` : [no documentation found]
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
    func getExportJob(input: GetExportJobInput) async throws -> GetExportJobOutput
    /// Performs the `GetExportJobs` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of all the export jobs for an application.
    ///
    /// - Parameter GetExportJobsInput : [no documentation found]
    ///
    /// - Returns: `GetExportJobsOutput` : [no documentation found]
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
    func getExportJobs(input: GetExportJobsInput) async throws -> GetExportJobsOutput
    /// Performs the `GetGcmChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the GCM channel for an application.
    ///
    /// - Parameter GetGcmChannelInput : [no documentation found]
    ///
    /// - Returns: `GetGcmChannelOutput` : [no documentation found]
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
    func getGcmChannel(input: GetGcmChannelInput) async throws -> GetGcmChannelOutput
    /// Performs the `GetImportJob` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of a specific import job for an application.
    ///
    /// - Parameter GetImportJobInput : [no documentation found]
    ///
    /// - Returns: `GetImportJobOutput` : [no documentation found]
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
    func getImportJob(input: GetImportJobInput) async throws -> GetImportJobOutput
    /// Performs the `GetImportJobs` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of all the import jobs for an application.
    ///
    /// - Parameter GetImportJobsInput : [no documentation found]
    ///
    /// - Returns: `GetImportJobsOutput` : [no documentation found]
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
    func getImportJobs(input: GetImportJobsInput) async throws -> GetImportJobsOutput
    /// Performs the `GetInAppMessages` operation on the `Pinpoint` service.
    ///
    /// Retrieves the in-app messages targeted for the provided endpoint ID.
    ///
    /// - Parameter GetInAppMessagesInput : [no documentation found]
    ///
    /// - Returns: `GetInAppMessagesOutput` : [no documentation found]
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
    func getInAppMessages(input: GetInAppMessagesInput) async throws -> GetInAppMessagesOutput
    /// Performs the `GetInAppTemplate` operation on the `Pinpoint` service.
    ///
    /// Retrieves the content and settings of a message template for messages sent through the in-app channel.
    ///
    /// - Parameter GetInAppTemplateInput : [no documentation found]
    ///
    /// - Returns: `GetInAppTemplateOutput` : [no documentation found]
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
    func getInAppTemplate(input: GetInAppTemplateInput) async throws -> GetInAppTemplateOutput
    /// Performs the `GetJourney` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for a journey.
    ///
    /// - Parameter GetJourneyInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyOutput` : [no documentation found]
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
    func getJourney(input: GetJourneyInput) async throws -> GetJourneyOutput
    /// Performs the `GetJourneyDateRangeKpi` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
    ///
    /// - Parameter GetJourneyDateRangeKpiInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyDateRangeKpiOutput` : [no documentation found]
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
    func getJourneyDateRangeKpi(input: GetJourneyDateRangeKpiInput) async throws -> GetJourneyDateRangeKpiOutput
    /// Performs the `GetJourneyExecutionActivityMetrics` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
    ///
    /// - Parameter GetJourneyExecutionActivityMetricsInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyExecutionActivityMetricsOutput` : [no documentation found]
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
    func getJourneyExecutionActivityMetrics(input: GetJourneyExecutionActivityMetricsInput) async throws -> GetJourneyExecutionActivityMetricsOutput
    /// Performs the `GetJourneyExecutionMetrics` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
    ///
    /// - Parameter GetJourneyExecutionMetricsInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyExecutionMetricsOutput` : [no documentation found]
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
    func getJourneyExecutionMetrics(input: GetJourneyExecutionMetricsInput) async throws -> GetJourneyExecutionMetricsOutput
    /// Performs the `GetJourneyRunExecutionActivityMetrics` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard run execution metric that applies to a journey activity.
    ///
    /// - Parameter GetJourneyRunExecutionActivityMetricsInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyRunExecutionActivityMetricsOutput` : [no documentation found]
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
    func getJourneyRunExecutionActivityMetrics(input: GetJourneyRunExecutionActivityMetricsInput) async throws -> GetJourneyRunExecutionActivityMetricsOutput
    /// Performs the `GetJourneyRunExecutionMetrics` operation on the `Pinpoint` service.
    ///
    /// Retrieves (queries) pre-aggregated data for a standard run execution metric that applies to a journey.
    ///
    /// - Parameter GetJourneyRunExecutionMetricsInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyRunExecutionMetricsOutput` : [no documentation found]
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
    func getJourneyRunExecutionMetrics(input: GetJourneyRunExecutionMetricsInput) async throws -> GetJourneyRunExecutionMetricsOutput
    /// Performs the `GetJourneyRuns` operation on the `Pinpoint` service.
    ///
    /// Provides information about the runs of a journey.
    ///
    /// - Parameter GetJourneyRunsInput : [no documentation found]
    ///
    /// - Returns: `GetJourneyRunsOutput` : [no documentation found]
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
    func getJourneyRuns(input: GetJourneyRunsInput) async throws -> GetJourneyRunsOutput
    /// Performs the `GetPushTemplate` operation on the `Pinpoint` service.
    ///
    /// Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
    ///
    /// - Parameter GetPushTemplateInput : [no documentation found]
    ///
    /// - Returns: `GetPushTemplateOutput` : [no documentation found]
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
    func getPushTemplate(input: GetPushTemplateInput) async throws -> GetPushTemplateOutput
    /// Performs the `GetRecommenderConfiguration` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about an Amazon Pinpoint configuration for a recommender model.
    ///
    /// - Parameter GetRecommenderConfigurationInput : [no documentation found]
    ///
    /// - Returns: `GetRecommenderConfigurationOutput` : [no documentation found]
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
    func getRecommenderConfiguration(input: GetRecommenderConfigurationInput) async throws -> GetRecommenderConfigurationOutput
    /// Performs the `GetRecommenderConfigurations` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the recommender model configurations that are associated with your Amazon Pinpoint account.
    ///
    /// - Parameter GetRecommenderConfigurationsInput : [no documentation found]
    ///
    /// - Returns: `GetRecommenderConfigurationsOutput` : [no documentation found]
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
    func getRecommenderConfigurations(input: GetRecommenderConfigurationsInput) async throws -> GetRecommenderConfigurationsOutput
    /// Performs the `GetSegment` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
    ///
    /// - Parameter GetSegmentInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentOutput` : [no documentation found]
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
    func getSegment(input: GetSegmentInput) async throws -> GetSegmentOutput
    /// Performs the `GetSegmentExportJobs` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the export jobs for a segment.
    ///
    /// - Parameter GetSegmentExportJobsInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentExportJobsOutput` : [no documentation found]
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
    func getSegmentExportJobs(input: GetSegmentExportJobsInput) async throws -> GetSegmentExportJobsOutput
    /// Performs the `GetSegmentImportJobs` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the import jobs for a segment.
    ///
    /// - Parameter GetSegmentImportJobsInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentImportJobsOutput` : [no documentation found]
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
    func getSegmentImportJobs(input: GetSegmentImportJobsInput) async throws -> GetSegmentImportJobsOutput
    /// Performs the `GetSegments` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
    ///
    /// - Parameter GetSegmentsInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentsOutput` : [no documentation found]
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
    func getSegments(input: GetSegmentsInput) async throws -> GetSegmentsOutput
    /// Performs the `GetSegmentVersion` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
    ///
    /// - Parameter GetSegmentVersionInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentVersionOutput` : [no documentation found]
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
    func getSegmentVersion(input: GetSegmentVersionInput) async throws -> GetSegmentVersionOutput
    /// Performs the `GetSegmentVersions` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
    ///
    /// - Parameter GetSegmentVersionsInput : [no documentation found]
    ///
    /// - Returns: `GetSegmentVersionsOutput` : [no documentation found]
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
    func getSegmentVersions(input: GetSegmentVersionsInput) async throws -> GetSegmentVersionsOutput
    /// Performs the `GetSmsChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the SMS channel for an application.
    ///
    /// - Parameter GetSmsChannelInput : [no documentation found]
    ///
    /// - Returns: `GetSmsChannelOutput` : [no documentation found]
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
    func getSmsChannel(input: GetSmsChannelInput) async throws -> GetSmsChannelOutput
    /// Performs the `GetSmsTemplate` operation on the `Pinpoint` service.
    ///
    /// Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
    ///
    /// - Parameter GetSmsTemplateInput : [no documentation found]
    ///
    /// - Returns: `GetSmsTemplateOutput` : [no documentation found]
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
    func getSmsTemplate(input: GetSmsTemplateInput) async throws -> GetSmsTemplateOutput
    /// Performs the `GetUserEndpoints` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the endpoints that are associated with a specific user ID.
    ///
    /// - Parameter GetUserEndpointsInput : [no documentation found]
    ///
    /// - Returns: `GetUserEndpointsOutput` : [no documentation found]
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
    func getUserEndpoints(input: GetUserEndpointsInput) async throws -> GetUserEndpointsOutput
    /// Performs the `GetVoiceChannel` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status and settings of the voice channel for an application.
    ///
    /// - Parameter GetVoiceChannelInput : [no documentation found]
    ///
    /// - Returns: `GetVoiceChannelOutput` : [no documentation found]
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
    func getVoiceChannel(input: GetVoiceChannelInput) async throws -> GetVoiceChannelOutput
    /// Performs the `GetVoiceTemplate` operation on the `Pinpoint` service.
    ///
    /// Retrieves the content and settings of a message template for messages that are sent through the voice channel.
    ///
    /// - Parameter GetVoiceTemplateInput : [no documentation found]
    ///
    /// - Returns: `GetVoiceTemplateOutput` : [no documentation found]
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
    func getVoiceTemplate(input: GetVoiceTemplateInput) async throws -> GetVoiceTemplateOutput
    /// Performs the `ListJourneys` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
    ///
    /// - Parameter ListJourneysInput : [no documentation found]
    ///
    /// - Returns: `ListJourneysOutput` : [no documentation found]
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
    func listJourneys(input: ListJourneysInput) async throws -> ListJourneysOutput
    /// Performs the `ListTagsForResource` operation on the `Pinpoint` service.
    ///
    /// Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
    ///
    /// - Parameter ListTagsForResourceInput : [no documentation found]
    ///
    /// - Returns: `ListTagsForResourceOutput` : [no documentation found]
    func listTagsForResource(input: ListTagsForResourceInput) async throws -> ListTagsForResourceOutput
    /// Performs the `ListTemplates` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
    ///
    /// - Parameter ListTemplatesInput : [no documentation found]
    ///
    /// - Returns: `ListTemplatesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func listTemplates(input: ListTemplatesInput) async throws -> ListTemplatesOutput
    /// Performs the `ListTemplateVersions` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about all the versions of a specific message template.
    ///
    /// - Parameter ListTemplateVersionsInput : [no documentation found]
    ///
    /// - Returns: `ListTemplateVersionsOutput` : [no documentation found]
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
    func listTemplateVersions(input: ListTemplateVersionsInput) async throws -> ListTemplateVersionsOutput
    /// Performs the `PhoneNumberValidate` operation on the `Pinpoint` service.
    ///
    /// Retrieves information about a phone number.
    ///
    /// - Parameter PhoneNumberValidateInput : [no documentation found]
    ///
    /// - Returns: `PhoneNumberValidateOutput` : [no documentation found]
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
    func phoneNumberValidate(input: PhoneNumberValidateInput) async throws -> PhoneNumberValidateOutput
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
    /// Performs the `PutEventStream` operation on the `Pinpoint` service.
    ///
    /// Creates a new event stream for an application or updates the settings of an existing event stream for an application.
    ///
    /// - Parameter PutEventStreamInput : [no documentation found]
    ///
    /// - Returns: `PutEventStreamOutput` : [no documentation found]
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
    func putEventStream(input: PutEventStreamInput) async throws -> PutEventStreamOutput
    /// Performs the `RemoveAttributes` operation on the `Pinpoint` service.
    ///
    /// Removes one or more custom attributes, of the same attribute type, from the application. Existing endpoints still have the attributes but Amazon Pinpoint will stop capturing new or changed values for these attributes.
    ///
    /// - Parameter RemoveAttributesInput : [no documentation found]
    ///
    /// - Returns: `RemoveAttributesOutput` : [no documentation found]
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
    func removeAttributes(input: RemoveAttributesInput) async throws -> RemoveAttributesOutput
    /// Performs the `SendMessages` operation on the `Pinpoint` service.
    ///
    /// Creates and sends a direct message.
    ///
    /// - Parameter SendMessagesInput : [no documentation found]
    ///
    /// - Returns: `SendMessagesOutput` : [no documentation found]
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
    func sendMessages(input: SendMessagesInput) async throws -> SendMessagesOutput
    /// Performs the `SendOTPMessage` operation on the `Pinpoint` service.
    ///
    /// Send an OTP message
    ///
    /// - Parameter SendOTPMessageInput : [no documentation found]
    ///
    /// - Returns: `SendOTPMessageOutput` : [no documentation found]
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
    func sendOTPMessage(input: SendOTPMessageInput) async throws -> SendOTPMessageOutput
    /// Performs the `SendUsersMessages` operation on the `Pinpoint` service.
    ///
    /// Creates and sends a message to a list of users.
    ///
    /// - Parameter SendUsersMessagesInput : [no documentation found]
    ///
    /// - Returns: `SendUsersMessagesOutput` : [no documentation found]
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
    func sendUsersMessages(input: SendUsersMessagesInput) async throws -> SendUsersMessagesOutput
    /// Performs the `TagResource` operation on the `Pinpoint` service.
    ///
    /// Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
    ///
    /// - Parameter TagResourceInput : [no documentation found]
    ///
    /// - Returns: `TagResourceOutput` : [no documentation found]
    func tagResource(input: TagResourceInput) async throws -> TagResourceOutput
    /// Performs the `UntagResource` operation on the `Pinpoint` service.
    ///
    /// Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
    ///
    /// - Parameter UntagResourceInput : [no documentation found]
    ///
    /// - Returns: `UntagResourceOutput` : [no documentation found]
    func untagResource(input: UntagResourceInput) async throws -> UntagResourceOutput
    /// Performs the `UpdateAdmChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
    ///
    /// - Parameter UpdateAdmChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateAdmChannelOutput` : [no documentation found]
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
    func updateAdmChannel(input: UpdateAdmChannelInput) async throws -> UpdateAdmChannelOutput
    /// Performs the `UpdateApnsChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
    ///
    /// - Parameter UpdateApnsChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateApnsChannelOutput` : [no documentation found]
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
    func updateApnsChannel(input: UpdateApnsChannelInput) async throws -> UpdateApnsChannelOutput
    /// Performs the `UpdateApnsSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
    ///
    /// - Parameter UpdateApnsSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateApnsSandboxChannelOutput` : [no documentation found]
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
    func updateApnsSandboxChannel(input: UpdateApnsSandboxChannelInput) async throws -> UpdateApnsSandboxChannelOutput
    /// Performs the `UpdateApnsVoipChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
    ///
    /// - Parameter UpdateApnsVoipChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateApnsVoipChannelOutput` : [no documentation found]
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
    func updateApnsVoipChannel(input: UpdateApnsVoipChannelInput) async throws -> UpdateApnsVoipChannelOutput
    /// Performs the `UpdateApnsVoipSandboxChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
    ///
    /// - Parameter UpdateApnsVoipSandboxChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateApnsVoipSandboxChannelOutput` : [no documentation found]
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
    func updateApnsVoipSandboxChannel(input: UpdateApnsVoipSandboxChannelInput) async throws -> UpdateApnsVoipSandboxChannelOutput
    /// Performs the `UpdateApplicationSettings` operation on the `Pinpoint` service.
    ///
    /// Updates the settings for an application.
    ///
    /// - Parameter UpdateApplicationSettingsInput : [no documentation found]
    ///
    /// - Returns: `UpdateApplicationSettingsOutput` : [no documentation found]
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
    func updateApplicationSettings(input: UpdateApplicationSettingsInput) async throws -> UpdateApplicationSettingsOutput
    /// Performs the `UpdateBaiduChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
    ///
    /// - Parameter UpdateBaiduChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateBaiduChannelOutput` : [no documentation found]
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
    func updateBaiduChannel(input: UpdateBaiduChannelInput) async throws -> UpdateBaiduChannelOutput
    /// Performs the `UpdateCampaign` operation on the `Pinpoint` service.
    ///
    /// Updates the configuration and other settings for a campaign.
    ///
    /// - Parameter UpdateCampaignInput : [no documentation found]
    ///
    /// - Returns: `UpdateCampaignOutput` : [no documentation found]
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
    func updateCampaign(input: UpdateCampaignInput) async throws -> UpdateCampaignOutput
    /// Performs the `UpdateEmailChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the email channel for an application or updates the status and settings of the email channel for an application.
    ///
    /// - Parameter UpdateEmailChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateEmailChannelOutput` : [no documentation found]
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
    func updateEmailChannel(input: UpdateEmailChannelInput) async throws -> UpdateEmailChannelOutput
    /// Performs the `UpdateEmailTemplate` operation on the `Pinpoint` service.
    ///
    /// Updates an existing message template for messages that are sent through the email channel.
    ///
    /// - Parameter UpdateEmailTemplateInput : [no documentation found]
    ///
    /// - Returns: `UpdateEmailTemplateOutput` : [no documentation found]
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
    func updateEmailTemplate(input: UpdateEmailTemplateInput) async throws -> UpdateEmailTemplateOutput
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
    /// Performs the `UpdateEndpointsBatch` operation on the `Pinpoint` service.
    ///
    /// Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes for a batch of endpoints. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
    ///
    /// - Parameter UpdateEndpointsBatchInput : [no documentation found]
    ///
    /// - Returns: `UpdateEndpointsBatchOutput` : [no documentation found]
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
    func updateEndpointsBatch(input: UpdateEndpointsBatchInput) async throws -> UpdateEndpointsBatchOutput
    /// Performs the `UpdateGcmChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
    ///
    /// - Parameter UpdateGcmChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateGcmChannelOutput` : [no documentation found]
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
    func updateGcmChannel(input: UpdateGcmChannelInput) async throws -> UpdateGcmChannelOutput
    /// Performs the `UpdateInAppTemplate` operation on the `Pinpoint` service.
    ///
    /// Updates an existing message template for messages sent through the in-app message channel.
    ///
    /// - Parameter UpdateInAppTemplateInput : [no documentation found]
    ///
    /// - Returns: `UpdateInAppTemplateOutput` : [no documentation found]
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
    func updateInAppTemplate(input: UpdateInAppTemplateInput) async throws -> UpdateInAppTemplateOutput
    /// Performs the `UpdateJourney` operation on the `Pinpoint` service.
    ///
    /// Updates the configuration and other settings for a journey.
    ///
    /// - Parameter UpdateJourneyInput : [no documentation found]
    ///
    /// - Returns: `UpdateJourneyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BadRequestException` : Provides information about an API request or response.
    /// - `ConflictException` : Provides information about an API request or response.
    /// - `ForbiddenException` : Provides information about an API request or response.
    /// - `InternalServerErrorException` : Provides information about an API request or response.
    /// - `MethodNotAllowedException` : Provides information about an API request or response.
    /// - `NotFoundException` : Provides information about an API request or response.
    /// - `PayloadTooLargeException` : Provides information about an API request or response.
    /// - `TooManyRequestsException` : Provides information about an API request or response.
    func updateJourney(input: UpdateJourneyInput) async throws -> UpdateJourneyOutput
    /// Performs the `UpdateJourneyState` operation on the `Pinpoint` service.
    ///
    /// Cancels (stops) an active journey.
    ///
    /// - Parameter UpdateJourneyStateInput : [no documentation found]
    ///
    /// - Returns: `UpdateJourneyStateOutput` : [no documentation found]
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
    func updateJourneyState(input: UpdateJourneyStateInput) async throws -> UpdateJourneyStateOutput
    /// Performs the `UpdatePushTemplate` operation on the `Pinpoint` service.
    ///
    /// Updates an existing message template for messages that are sent through a push notification channel.
    ///
    /// - Parameter UpdatePushTemplateInput : [no documentation found]
    ///
    /// - Returns: `UpdatePushTemplateOutput` : [no documentation found]
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
    func updatePushTemplate(input: UpdatePushTemplateInput) async throws -> UpdatePushTemplateOutput
    /// Performs the `UpdateRecommenderConfiguration` operation on the `Pinpoint` service.
    ///
    /// Updates an Amazon Pinpoint configuration for a recommender model.
    ///
    /// - Parameter UpdateRecommenderConfigurationInput : [no documentation found]
    ///
    /// - Returns: `UpdateRecommenderConfigurationOutput` : [no documentation found]
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
    func updateRecommenderConfiguration(input: UpdateRecommenderConfigurationInput) async throws -> UpdateRecommenderConfigurationOutput
    /// Performs the `UpdateSegment` operation on the `Pinpoint` service.
    ///
    /// Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
    ///
    /// - Parameter UpdateSegmentInput : [no documentation found]
    ///
    /// - Returns: `UpdateSegmentOutput` : [no documentation found]
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
    func updateSegment(input: UpdateSegmentInput) async throws -> UpdateSegmentOutput
    /// Performs the `UpdateSmsChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
    ///
    /// - Parameter UpdateSmsChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateSmsChannelOutput` : [no documentation found]
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
    func updateSmsChannel(input: UpdateSmsChannelInput) async throws -> UpdateSmsChannelOutput
    /// Performs the `UpdateSmsTemplate` operation on the `Pinpoint` service.
    ///
    /// Updates an existing message template for messages that are sent through the SMS channel.
    ///
    /// - Parameter UpdateSmsTemplateInput : [no documentation found]
    ///
    /// - Returns: `UpdateSmsTemplateOutput` : [no documentation found]
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
    func updateSmsTemplate(input: UpdateSmsTemplateInput) async throws -> UpdateSmsTemplateOutput
    /// Performs the `UpdateTemplateActiveVersion` operation on the `Pinpoint` service.
    ///
    /// Changes the status of a specific version of a message template to active.
    ///
    /// - Parameter UpdateTemplateActiveVersionInput : [no documentation found]
    ///
    /// - Returns: `UpdateTemplateActiveVersionOutput` : [no documentation found]
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
    func updateTemplateActiveVersion(input: UpdateTemplateActiveVersionInput) async throws -> UpdateTemplateActiveVersionOutput
    /// Performs the `UpdateVoiceChannel` operation on the `Pinpoint` service.
    ///
    /// Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
    ///
    /// - Parameter UpdateVoiceChannelInput : [no documentation found]
    ///
    /// - Returns: `UpdateVoiceChannelOutput` : [no documentation found]
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
    func updateVoiceChannel(input: UpdateVoiceChannelInput) async throws -> UpdateVoiceChannelOutput
    /// Performs the `UpdateVoiceTemplate` operation on the `Pinpoint` service.
    ///
    /// Updates an existing message template for messages that are sent through the voice channel.
    ///
    /// - Parameter UpdateVoiceTemplateInput : [no documentation found]
    ///
    /// - Returns: `UpdateVoiceTemplateOutput` : [no documentation found]
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
    func updateVoiceTemplate(input: UpdateVoiceTemplateInput) async throws -> UpdateVoiceTemplateOutput
    /// Performs the `VerifyOTPMessage` operation on the `Pinpoint` service.
    ///
    /// Verify an OTP
    ///
    /// - Parameter VerifyOTPMessageInput : [no documentation found]
    ///
    /// - Returns: `VerifyOTPMessageOutput` : [no documentation found]
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
    func verifyOTPMessage(input: VerifyOTPMessageInput) async throws -> VerifyOTPMessageOutput
}

extension PinpointClient: PinpointClientProtocol { }

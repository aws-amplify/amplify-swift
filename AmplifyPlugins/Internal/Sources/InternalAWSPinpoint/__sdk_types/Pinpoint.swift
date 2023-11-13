//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AWSPinpoint {}
extension AWSPinpoint {
    public struct BadRequestException: Error {}
    public struct ForbiddenException: Error {}
    public struct InternalServerErrorException: Error {}
    public struct MethodNotAllowedException: Error {}
    public struct NotFoundException: Error {}
    public struct PayloadTooLargeException: Error {}
    public struct TooManyRequestsException: Error {}
}

public struct UpdateEndpointInput: Equatable, Encodable {
    /// This member is required.
    public var applicationId: String
    /// This member is required.
    public var endpointId: String
    /// This member is required.
    public var endpointRequest: PinpointClientTypes.EndpointRequest

    enum CodingKeys: String, CodingKey {
        case endpointRequest = "EndpointRequest"
    }
}

public struct UpdateEndpointOutputResponse: Equatable, Decodable {
    /// This member is required.
    public var messageBody: PinpointClientTypes.MessageBody

    enum CodingKeys: String, CodingKey {
        case messageBody = "MessageBody"
    }
}


public struct PutEventsOutputResponse: Equatable, Decodable {
    /// This member is required.
    public var eventsResponse: PinpointClientTypes.EventsResponse

    enum CodingKeys: String, CodingKey {
        case eventsResponse = "EventsResponse"
    }
}
public struct PutEventsInput: Equatable, Encodable {
    /// This member is required.
    public var applicationId: String
    /// This member is required.
    public var eventsRequest: PinpointClientTypes.EventsRequest

    enum CodingKeys: String, CodingKey {
        case eventsRequest = "EventsRequest"
    }
}

public struct DeleteUserEndpointsInput: Equatable, Encodable {
    /// This member is required.
    public var applicationId: String
    /// This member is required.
    public var userId: String

    //         return "/v1/apps/\(applicationId.urlPercentEncoding())/users/\(userId.urlPercentEncoding())"
}

public struct DeleteUserEndpointsOutputResponse: Equatable, Decodable {
    /// This member is required.
    public var endpointsResponse: PinpointClientTypes.EndpointsResponse

    enum CodingKeys: String, CodingKey {
        case endpointsResponse = "EndpointsResponse"
    }
}

public enum PinpointClientTypes {}

extension PinpointClientTypes {
    public struct EndpointsResponse: Equatable, Decodable {
        /// This member is required.
        public var item: [PinpointClientTypes.EndpointResponse]

        enum CodingKeys: String, CodingKey {
            case item = "Item"
        }
    }
}

extension PinpointClientTypes {
    public struct EndpointResponse: Equatable, Decodable {
        public var address: String?
        public var applicationId: String?
        public var attributes: [String:[String]]?
        public var channelType: PinpointClientTypes.ChannelType?
        public var cohortId: String?
        public var creationDate: String?
        public var demographic: PinpointClientTypes.EndpointDemographic?
        public var effectiveDate: String?
        public var endpointStatus: String?
        public var id: String?
        public var location: PinpointClientTypes.EndpointLocation?
        public var metrics: [String:Double]?
        public var optOut: String?
        public var requestId: String?
        public var user: PinpointClientTypes.EndpointUser?

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case applicationId = "ApplicationId"
            case attributes = "Attributes"
            case channelType = "ChannelType"
            case cohortId = "CohortId"
            case creationDate = "CreationDate"
            case demographic = "Demographic"
            case effectiveDate = "EffectiveDate"
            case endpointStatus = "EndpointStatus"
            case id = "Id"
            case location = "Location"
            case metrics = "Metrics"
            case optOut = "OptOut"
            case requestId = "RequestId"
            case user = "User"
        }
    }
}

extension PinpointClientTypes {
    public struct ItemResponse: Equatable, Decodable {
        public var endpointItemResponse: PinpointClientTypes.EndpointItemResponse?
        public var eventsItemResponse: [String:PinpointClientTypes.EventItemResponse]?

        enum CodingKeys: String, CodingKey {
            case endpointItemResponse = "EndpointItemResponse"
            case eventsItemResponse = "EventsItemResponse"
        }
    }
}

extension PinpointClientTypes {
    public struct EventItemResponse: Equatable, Decodable {
        public var message: String?
        public var statusCode: Int?

        enum CodingKeys: String, CodingKey {
            case message = "Message"
            case statusCode = "StatusCode"
        }
    }
}

extension PinpointClientTypes {
    public struct EndpointItemResponse: Equatable, Decodable {
        public var message: String?
        public var statusCode: Int?

        enum CodingKeys: String, CodingKey {
            case message = "Message"
            case statusCode = "StatusCode"
        }
    }
}

extension PinpointClientTypes {
    public struct EventsResponse: Equatable, Decodable {
        public var results: [String:PinpointClientTypes.ItemResponse]?

        enum CodingKeys: String, CodingKey {
            case results = "Results"
        }
    }
}

extension PinpointClientTypes {
    public struct EventStream: Equatable {
        /// This member is required.
        public var applicationId: String
        /// This member is required.
        public var destinationStreamArn: String
        public var externalId: String?
        public var lastModifiedDate: String?
        public var lastUpdatedBy: String?
        /// This member is required.
        public var roleArn: String

        enum CodingKeys: String, CodingKey {
            case applicationId = "ApplicationId"
            case destinationStreamArn = "DestinationStreamArn"
            case externalId = "ExternalId"
            case lastModifiedDate = "LastModifiedDate"
            case lastUpdatedBy = "LastUpdatedBy"
            case roleArn = "RoleArn"
        }
    }
}

extension PinpointClientTypes {
    public struct EventsRequest: Equatable, Encodable {
        /// This member is required.
        public var batchItem: [String:PinpointClientTypes.EventsBatch]
        
        enum CodingKeys: String, CodingKey {
            case batchItem = "BatchItem"
        }
    }
}

extension PinpointClientTypes {
    public struct Event: Equatable, Encodable {
        public var appPackageName: String?
        public var appTitle: String?
        public var appVersionCode: String?
        public var attributes: [String:String]?
        public var clientSdkVersion: String?
        /// This member is required.
        public var eventType: String
        public var metrics: [String:Double]?
        public var sdkName: String?
        public var session: PinpointClientTypes.Session?
        /// This member is required.
        public var timestamp: String

        enum CodingKeys: String, CodingKey {
            case appPackageName = "AppPackageName"
            case appTitle = "AppTitle"
            case appVersionCode = "AppVersionCode"
            case attributes = "Attributes"
            case clientSdkVersion = "ClientSdkVersion"
            case eventType = "EventType"
            case metrics = "Metrics"
            case sdkName = "SdkName"
            case session = "Session"
            case timestamp = "Timestamp"
        }
    }
}

extension PinpointClientTypes {
    /// Specifies a batch of endpoints and events to process.
    public struct EventsBatch: Equatable, Encodable {
        /// A set of properties and attributes that are associated with the endpoint.
        /// This member is required.
        public var endpoint: PinpointClientTypes.PublicEndpoint?
        /// A set of properties that are associated with the event.
        /// This member is required.
        public var events: [String:PinpointClientTypes.Event]?

        enum CodingKeys: String, CodingKey {
            case endpoint = "Endpoint"
            case events = "Events"
        }
    }
}

extension PinpointClientTypes {
    /// Provides information about an API request or response.
    public struct MessageBody: Equatable, Decodable {
        /// The message that's returned from the API.
        public var message: String?
        /// The unique identifier for the request or response.
        public var requestID: String?

        enum CodingKeys: String, CodingKey {
            case message = "Message"
            case requestID = "RequestID"
        }
    }
}

extension PinpointClientTypes {
    /// Provides information about a session.
    public struct Session: Equatable, Encodable {
        /// The duration of the session, in milliseconds.
        public var duration: Int?
        /// The unique identifier for the session.
        /// This member is required.
        public var id: String?
        /// The date and time when the session began.
        /// This member is required.
        public var startTimestamp: String?
        /// The date and time when the session ended.
        public var stopTimestamp: String?

        enum CodingKeys: String, CodingKey {
            case duration = "Duration"
            case id = "Id"
            case startTimestamp = "StartTimestamp"
            case stopTimestamp = "StopTimestamp"
        }
    }
}


extension PinpointClientTypes {
    public struct EndpointRequest: Equatable, Encodable {
        public var address: String?
        public var attributes: [String:[String]]?
        public var channelType: PinpointClientTypes.ChannelType?
        public var demographic: PinpointClientTypes.EndpointDemographic?
        public var effectiveDate: String?
        public var endpointStatus: String?
        public var location: PinpointClientTypes.EndpointLocation?
        public var metrics: [String:Double]?
        public var optOut: String?
        public var requestId: String?
        public var user: PinpointClientTypes.EndpointUser?

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case attributes = "Attributes"
            case channelType = "ChannelType"
            case demographic = "Demographic"
            case effectiveDate = "EffectiveDate"
            case endpointStatus = "EndpointStatus"
            case location = "Location"
            case metrics = "Metrics"
            case optOut = "OptOut"
            case requestId = "RequestId"
            case user = "User"
        }
    }
}


extension PinpointClientTypes {
    public struct PublicEndpoint: Equatable, Encodable {
        public var address: String?
        public var attributes: [String:[String]]?
        public var channelType: PinpointClientTypes.ChannelType?
        public var demographic: PinpointClientTypes.EndpointDemographic?
        public var effectiveDate: String?
        public var endpointStatus: String?
        public var location: PinpointClientTypes.EndpointLocation?
        public var metrics: [String:Double]?
        public var optOut: String?
        public var requestId: String?
        public var user: PinpointClientTypes.EndpointUser?

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case attributes = "Attributes"
            case channelType = "ChannelType"
            case demographic = "Demographic"
            case effectiveDate = "EffectiveDate"
            case endpointStatus = "EndpointStatus"
            case location = "Location"
            case metrics = "Metrics"
            case optOut = "OptOut"
            case requestId = "RequestId"
            case user = "User"
        }
    }
}

extension PinpointClientTypes {
    public struct EndpointLocation: Equatable, Codable {
        public var city: String?
        public var country: String?
        public var latitude: Double?
        public var longitude: Double?
        public var postalCode: String?
        public var region: String?

        enum CodingKeys: String, CodingKey {
            case city = "City"
            case country = "Country"
            case latitude = "Latitude"
            case longitude = "Longitude"
            case postalCode = "PostalCode"
            case region = "Region"
        }
    }
}

extension PinpointClientTypes {
    public struct EndpointDemographic: Equatable, Codable {
        public var appVersion: String?
        public var locale: String?
        public var make: String?
        public var model: String?
        public var modelVersion: String?
        public var platform: String?
        public var platformVersion: String?
        public var timezone: String?

        enum CodingKeys: String, CodingKey {
            case appVersion = "AppVersion"
            case locale = "Locale"
            case make = "Make"
            case model = "Model"
            case modelVersion = "ModelVersion"
            case platform = "Platform"
            case platformVersion = "PlatformVersion"
            case timezone = "Timezone"
        }
    }
}

extension PinpointClientTypes {
    public struct EndpointUser: Equatable, Codable {
        public var userAttributes: [String: [String]]?
        public var userId: String?

        enum CodingKeys: String, CodingKey {
            case userAttributes = "UserAttributes"
            case userId = "UserId"
        }
    }
}


extension PinpointClientTypes {
    public enum ChannelType: Equatable, RawRepresentable, CaseIterable, Codable, Hashable {
        case adm
        case apns
        case apnsSandbox
        case apnsVoip
        case apnsVoipSandbox
        case baidu
        case custom
        case email
        case gcm
        case inApp
        case push
        case sms
        case voice
        case sdkUnknown(String)

        public static var allCases: [ChannelType] {
            return [
                .adm,
                .apns,
                .apnsSandbox,
                .apnsVoip,
                .apnsVoipSandbox,
                .baidu,
                .custom,
                .email,
                .gcm,
                .inApp,
                .push,
                .sms,
                .voice,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: String {
            switch self {
            case .adm: return "ADM"
            case .apns: return "APNS"
            case .apnsSandbox: return "APNS_SANDBOX"
            case .apnsVoip: return "APNS_VOIP"
            case .apnsVoipSandbox: return "APNS_VOIP_SANDBOX"
            case .baidu: return "BAIDU"
            case .custom: return "CUSTOM"
            case .email: return "EMAIL"
            case .gcm: return "GCM"
            case .inApp: return "IN_APP"
            case .push: return "PUSH"
            case .sms: return "SMS"
            case .voice: return "VOICE"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = ChannelType(rawValue: rawValue) ?? ChannelType.sdkUnknown(rawValue)
        }
    }
}

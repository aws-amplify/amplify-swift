//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSSDKHTTPAuth
import XCTest
import AWSEventBridge
import ClientRuntime
import AWSClientRuntime
import AWSRoute53

/// Tests SigV4a signing flow using EventBridge's global endpoint.
class EventBridgeSigV4ATests: XCTestCase {
    // The custom event bridge client with only sigv4a auth scheme configured (w/o SigV4)
    private var sigv4aEventBridgeClient: EventBridgeClient!
    // The primary event bridge client used to create an event bus in primary region
    private var primaryRegionEventBridgeClient: EventBridgeClient!
    // The secondary event bridge client used to create an event bus in secondary region
    private var secondaryRegionEventBridgeClient: EventBridgeClient!
    // The Route 53 client used to create a healthcheck, a parameter to EventBridge::createEndpoint
    private var route53Client: Route53Client!

    private var eventBridgeConfig: EventBridgeClient.EventBridgeClientConfiguration!
    private let primaryRegion = "us-west-2"
    private let secondaryRegion = "us-east-1"

    // Name for the EventBridge global endpoint
    private let endpointName = "sigv4a-test-global-endpoint-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
    private let eventBusName = "sigv4a-integ-test-eventbus-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
    private var endpointId: String!

    private var healthCheckId: String!
    private let route53HealthCheckArnPrefix = "arn:aws:route53:::healthcheck/"

    private let NSEC_PER_SEC = 1_000_000_000

    override func setUp() async throws {
        // Create the clients
        primaryRegionEventBridgeClient = try EventBridgeClient(region: primaryRegion)
        secondaryRegionEventBridgeClient = try EventBridgeClient(region: secondaryRegion)

        eventBridgeConfig = try await EventBridgeClient.EventBridgeClientConfiguration(region: primaryRegion)
        eventBridgeConfig.authSchemes = [SigV4AAuthScheme()]
        sigv4aEventBridgeClient = EventBridgeClient(config: eventBridgeConfig)

        route53Client = try Route53Client(region: secondaryRegion)

        // Create two event buses with identical names but in two different regions for the global endpoint
        let eventBusArn1 = try await primaryRegionEventBridgeClient.createEventBus(input: CreateEventBusInput(name: eventBusName)).eventBusArn
        let eventBusArn2 = try await secondaryRegionEventBridgeClient.createEventBus(input: CreateEventBusInput(name: eventBusName)).eventBusArn

        // Create Route 53 Healthcheck
        let healthCheckConfig = Route53ClientTypes.HealthCheckConfig(
            fullyQualifiedDomainName: "www.amazon.com",
            type: .https
        )
        let createHealthCheckInput = CreateHealthCheckInput(
            callerReference: UUID().uuidString.split(separator: "-").first!.lowercased(),
            healthCheckConfig: healthCheckConfig
        )
        let healthCheck = try await route53Client.createHealthCheck(input: createHealthCheckInput)
        healthCheckId = (healthCheck.healthCheck?.id)!
        let healthCheckArn = route53HealthCheckArnPrefix + healthCheckId

        // Construct routingConfig object to use for global endpoint creation
        let primary = EventBridgeClientTypes.Primary(healthCheck: healthCheckArn)
        let secondary = EventBridgeClientTypes.Secondary(route: secondaryRegion)
        let failoverConfig = EventBridgeClientTypes.FailoverConfig(primary: primary, secondary: secondary)
        let routingConfig = EventBridgeClientTypes.RoutingConfig(failoverConfig: failoverConfig)

        // Construct replicationConfig object to use for global endpoint creation
        let replicationState = EventBridgeClientTypes.ReplicationState.disabled
        let replicationConfig = EventBridgeClientTypes.ReplicationConfig(state: replicationState)

        // Create the global endpoint with the two endpoint event buses and the routing config (healthcheck).
        let endpointEventBus1 = EventBridgeClientTypes.EndpointEventBus(eventBusArn: eventBusArn1)
        let endpointEventBus2 = EventBridgeClientTypes.EndpointEventBus(eventBusArn: eventBusArn2)
        _ = try await primaryRegionEventBridgeClient.createEndpoint(input: CreateEndpointInput(
            eventBuses: [endpointEventBus1, endpointEventBus2],
            name: endpointName,
            replicationConfig: replicationConfig,
            routingConfig: routingConfig
        ))

        // Pause program execution briefly.
        // This is needed bc it takes some time for newly created global endpoint to configure itself
        let seconds = 20.0
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))

        endpointId = try await primaryRegionEventBridgeClient.describeEndpoint(input: DescribeEndpointInput(name: endpointName)).endpointId
    }

    override func tearDown() async throws {
        // Delete the endpoint
        _ = try await primaryRegionEventBridgeClient.deleteEndpoint(input: DeleteEndpointInput(name: endpointName))
        // Delete the event buses
        _ = try await primaryRegionEventBridgeClient.deleteEventBus(input: DeleteEventBusInput(name: eventBusName))
        _ = try await secondaryRegionEventBridgeClient.deleteEventBus(input: DeleteEventBusInput(name: eventBusName))
        // Delete the Route 53 Healthcheck
        _ = try await route53Client.deleteHealthCheck(input: DeleteHealthCheckInput(healthCheckId: healthCheckId))
    }

    func testEventBridgeSigV4A() async throws {
        // Call putEvents with EventBridge client that only has SigV4a auth scheme configured
        let event = EventBridgeClientTypes.PutEventsRequestEntry(
            detail: "{}",
            detailType: "test",
            eventBusName: eventBusName,
            source: "test"
        )
        let response = try await sigv4aEventBridgeClient.putEvents(input: PutEventsInput(
            endpointId: endpointId,
            entries: [event]
        ))
        // Confirm that returned response has 0 failed entries
        let count = response.failedEntryCount
        XCTAssertEqual(count, 0)
    }
}

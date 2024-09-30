//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSRoute53

class AWSRoute53Tests: XCTestCase {
    var client: Route53Client!
    var hostedZoneID: String?

    override func setUp() async throws {
        try await super.setUp()
        client = try Route53Client(region: "us-east-1")
    }

    override func tearDown() async throws {

        // Delete the hosted zone that was created in the test.
        // Note that the member with the hosted zone ID is just named 'id'
        // here while it is 'hostedZoneId' below; the customization has
        // been adapted to handle any member name.
        let input = DeleteHostedZoneInput(id: hostedZoneID)
        _ = try await client.deleteHostedZone(input: input)
        client = nil
        hostedZoneID = nil
    }

    // Tests the 'TrimHostedZone' customization by performing operations on
    // AWS Route 53 that will fail if the zone ID is not correctly trimmed.
    func test_route53_createsAndDeletesZoneAndRecords() async throws {

        // Create reference string that is used for idempotency, and
        // also use it to create a bogus web domain that is used in the test.
        let ref = UUID().uuidString
        let hostedZoneName = "\(ref).com."

        // Create a hosted zone for the zone name created above.
        // Store the hosted zone ID for future reference.
        // The ID will be in the form '/hostedzone/<alphanumeric ID>'.
        // The '/hostedzone/' portion of the ID at the beginning is what must be
        // trimmed by the customization, and only the alphanumeric portion
        // of the ID is used in the operation's request URL.
        let input0 = CreateHostedZoneInput(callerReference: ref, name: hostedZoneName)
        let output0 = try await client.createHostedZone(input: input0)
        hostedZoneID = output0.hostedZone?.id

        // Create an A record on the zone that was just made.
        // ChangeResourceRecordSetsInput includes the hosted zone ID in a URL
        // component.
        let createBatch = Route53ClientTypes.ChangeBatch(changes:
            [
                Route53ClientTypes.Change(
                    action: .create,
                    resourceRecordSet: Route53ClientTypes.ResourceRecordSet(
                        name: "abc.\(hostedZoneName)", resourceRecords: [Route53ClientTypes.ResourceRecord(value: "1.1.1.1")], ttl: 3600, type: .a
                    )
                ),
            ]
        )
        let input1 = ChangeResourceRecordSetsInput(changeBatch: createBatch, hostedZoneId: hostedZoneID)
        _ = try await client.changeResourceRecordSets(input: input1)

        // Send a malformed request that deletes the A record that was just created more than once
        // to test for InvalidBatchError handling.
        let deleteBatch1 = Route53ClientTypes.ChangeBatch(changes:
            [
                Route53ClientTypes.Change(
                    action: .delete,
                    resourceRecordSet: Route53ClientTypes.ResourceRecordSet(
                        name: "abc.\(hostedZoneName)", resourceRecords: [Route53ClientTypes.ResourceRecord(value: "1.1.1.1")], ttl: 3600, type: .a
                    )
                ),
                Route53ClientTypes.Change(
                    action: .delete,
                    resourceRecordSet: Route53ClientTypes.ResourceRecordSet(
                        name: "abc.\(hostedZoneName)", resourceRecords: [Route53ClientTypes.ResourceRecord(value: "1.1.1.1")], ttl: 3600, type: .a
                    )
                ),
            ]
        )
        let input2 = ChangeResourceRecordSetsInput(changeBatch: deleteBatch1, hostedZoneId: hostedZoneID)
        do {
            _ = try await client.changeResourceRecordSets(input: input2)
            XCTFail("Expected InvalidChangeBatch error, but no error thrown.")
        } catch is InvalidChangeBatch {
            // no-op
        } catch {
            XCTFail("Expected InvalidChangeBatch error, but [\(error.localizedDescription)] was thrown instead.")
        }

        // Now delete the A record that was just created; this is necessary for the
        // hosted zone to be deleted in test teardown.
        let deleteBatch2 = Route53ClientTypes.ChangeBatch(changes:
            [
                Route53ClientTypes.Change(
                    action: .delete,
                    resourceRecordSet: Route53ClientTypes.ResourceRecordSet(
                        name: "abc.\(hostedZoneName)", resourceRecords: [Route53ClientTypes.ResourceRecord(value: "1.1.1.1")], ttl: 3600, type: .a
                    )
                ),
            ]
        )
        let input3 = ChangeResourceRecordSetsInput(changeBatch: deleteBatch2, hostedZoneId: hostedZoneID)
        _ = try await client.changeResourceRecordSets(input: input3)
    }
}

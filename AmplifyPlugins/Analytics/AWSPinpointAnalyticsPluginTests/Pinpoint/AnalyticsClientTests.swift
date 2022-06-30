//
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import StoreKit
import XCTest

class AnalyticsClientTests: XCTestCase {
    private var analyticsClient: AnalyticsClient!
    private var eventRecorder: MockEventRecorder!
    private var session: PinpointSession!

    override func setUp() {
        eventRecorder = MockEventRecorder()
        session = PinpointSession(appId: "appId", uniqueId: "uniqueId")
        analyticsClient = AnalyticsClient(
            eventRecorder: eventRecorder,
            sessionProvider: {
                return self.session
            }
        )
    }

    override func tearDown() async throws {
        analyticsClient = nil
        session = nil
        eventRecorder = nil
    }

    func testCreateAppleMonetizationEvent() {
        let transaction = MockTransaction(transactionId: "transactionId", quantity: 5)
        let product = MockProduct(productId: "producId", price: 2.5)
        let event = analyticsClient.createAppleMonetizationEvent(with: transaction,
                                                                 with: product)

        XCTAssertEqual(event.eventType, "_monetization.purchase")
        XCTAssertEqual(event.attributes["_store"], "Apple")
        XCTAssertEqual(event.attributes["_product_id"], product.productIdentifier)
        XCTAssertEqual(event.attributes["_currency"], product.priceLocale.currencyCode)
        XCTAssertEqual(event.metrics["_item_price"], product.price.doubleValue)
        XCTAssertEqual(event.metrics["_quantity"], Double(transaction.payment.quantity))
        XCTAssertEqual(event.attributes["_transaction_id"], transaction.transactionIdentifier)
    }

    func testCreateVirtualMonetizationEvent() {
        let productId = "productIt"
        let itemPrice: Double = 5.25
        let quantity = 2
        let currency = "USD"

        let event = analyticsClient.createVirtualMonetizationEvent(withProductId: productId,
                                                                   withItemPrice: itemPrice,
                                                                   withQuantity: quantity,
                                                                   withCurrency: currency)

        XCTAssertEqual(event.eventType, "_monetization.purchase")
        XCTAssertEqual(event.attributes["_store"], "Virtual")
        XCTAssertEqual(event.attributes["_product_id"], productId)
        XCTAssertEqual(event.attributes["_currency"], currency)
        XCTAssertEqual(event.metrics["_item_price"], itemPrice)
        XCTAssertEqual(event.metrics["_quantity"], Double(quantity))
        XCTAssertNil(event.attributes["_transaction_id"])
    }

    func testCreateEvent() {
        let eventType = "mockEvent"
        let event = analyticsClient.createEvent(withEventType: eventType)
        XCTAssertEqual(event.eventType, eventType)
        XCTAssertEqual(event.session, session)
    }

    func testRecord_shouldAddGlobalAttributesAndMetrics() async {
        let event = analyticsClient.createEvent(withEventType: "mockEvent")
        XCTAssertTrue(event.attributes.isEmpty)
        XCTAssertTrue(event.metrics.isEmpty)

        await analyticsClient.addGlobalAttribute("test_0", forKey: "attribute_0")
        await analyticsClient.addGlobalMetric(0, forKey: "metric_0")
        await analyticsClient.addGlobalMetric(1, forKey: "metric_1")

        do {
            try await analyticsClient.record(event)
            XCTAssertEqual(eventRecorder.saveCount, 1)
            guard let savedEvent = eventRecorder.lastSavedEvent else {
                XCTFail("Expected saved event")
                return
            }

            XCTAssertEqual(savedEvent.attributes.count, 1)
            XCTAssertEqual(savedEvent.attributes["attribute_0"], "test_0")
            XCTAssertEqual(savedEvent.metrics.count, 2)
            XCTAssertEqual(savedEvent.metrics["metric_0"], 0)
            XCTAssertEqual(savedEvent.metrics["metric_1"], 1)

        } catch {
            XCTFail("Unexpected exception while attempting to record event")
        }
    }

    func testRecord_shouldAddGlobalAttributesAndMetrics_forProperEventType() async {
        let eventType = "mockEvent"
        let event = analyticsClient.createEvent(withEventType: eventType)
        XCTAssertTrue(event.attributes.isEmpty)
        XCTAssertTrue(event.metrics.isEmpty)

        await analyticsClient.addGlobalAttribute("test_0", forKey: "attribute_0")
        await analyticsClient.addGlobalAttribute("test_1", forKey: "attribute_1", forEventType: eventType)
        await analyticsClient.addGlobalAttribute("test_2", forKey: "attribute_2", forEventType: "anotherEvent")
        await analyticsClient.addGlobalMetric(0, forKey: "metric_0")
        await analyticsClient.addGlobalMetric(1, forKey: "metric_1", forEventType: eventType)
        await analyticsClient.addGlobalMetric(2, forKey: "metric_2", forEventType: "anotherEvent")
        await analyticsClient.addGlobalMetric(3, forKey: "metric_3", forEventType: eventType)

        do {
            try await analyticsClient.record(event)
            XCTAssertEqual(eventRecorder.saveCount, 1)
            guard let savedEvent = eventRecorder.lastSavedEvent else {
                XCTFail("Expected saved event")
                return
            }

            XCTAssertEqual(savedEvent.attributes.count, 2) // 1 shared, 1 specific
            XCTAssertEqual(savedEvent.attributes["attribute_0"], "test_0")
            XCTAssertEqual(savedEvent.attributes["attribute_1"], "test_1")
            XCTAssertNil(savedEvent.attributes["attribute_2"])
            XCTAssertEqual(savedEvent.metrics.count, 3) // 1 shared, 2 specific
            XCTAssertEqual(savedEvent.metrics["metric_0"], 0)
            XCTAssertEqual(savedEvent.metrics["metric_1"], 1)
            XCTAssertNil(savedEvent.metrics["metric_2"])
            XCTAssertEqual(savedEvent.metrics["metric_3"], 3)

        } catch {
            XCTFail("Unexpected exception while attempting to record event")
        }
    }

    func testSubmit() async {
        do {
            try await analyticsClient.submitEvents()
            XCTAssertEqual(eventRecorder.submitCount, 1)
        } catch {
            XCTFail("Unexpected exception while attempting to submit events")
        }
    }
}

private class MockTransaction: SKPaymentTransaction {
    private let _transactionId: String
    private let _payment: SKPayment
    private class MockPayment: SKPayment {
        private let _quantity: Int

        init(quantity: Int) {
            _quantity = quantity
        }

        override var quantity: Int {
            return _quantity
        }

    }

    init(transactionId: String,
         quantity: Int) {
        _transactionId = transactionId
        _payment = MockPayment(quantity: quantity)
    }

    override var transactionIdentifier: String? {
        return _transactionId
    }

    override var payment: SKPayment {
        return _payment
    }
}

private class MockProduct: SKProduct {
    private let _productId: String
    private let _price: Double

    init(productId: String,
         price: Double) {
        _productId = productId
        _price = price
    }

    override var productIdentifier: String {
        return _productId
    }

    override var price: NSDecimalNumber {
        return NSDecimalNumber(value: _price)
    }

    override var priceLocale: Locale {
        return Locale.current
    }
}

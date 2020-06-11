//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class DataStoreCombineSupportChainTests: XCTestCase {

    var plugin: MockDataStoreCategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let config = AmplifyConfiguration(dataStore: dataStoreConfig)
        plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(config)
    }

    func testChainedOperationsSucceed() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        let responder: SaveResponder = { model, _ in .success(model) }
        plugin.responders.save = responder

        let sink = Publishers.Zip(
            Amplify.DataStore.save(Person(name: "Peter Parker (Caller)")),
            Amplify.DataStore.save(Person(name: "Mary Jane (Callee)"))
        ).flatMap { caller, callee in
            Amplify.DataStore.save(PhoneCall(caller: caller, callee: callee))
        }.flatMap { phoneCall in
            Publishers.Zip(
                Amplify.DataStore.save(
                    Transcript(text: "call transcript in english",
                               language: "en",
                               phoneCall: phoneCall)
                ),
                Amplify.DataStore.save(
                    Transcript(text: "transcripción de la llamada en español",
                               language: "es",
                               phoneCall: phoneCall)
                )
            )
        }.sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in receivedValue.fulfill() })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedOperationsFail() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        // Craft the responder so it fails in the middle of the chain
        let responder: SaveResponder = { model, _ in
            switch model {
            case is PhoneCall:
                return .failure(DataStoreError.invalidModelName("Blah blah"))
            default:
                return .success(model)
            }
        }

        plugin.responders.save = responder

        let sink = Publishers.Zip(
            Amplify.DataStore.save(Person(name: "Peter Parker (Caller)")),
            Amplify.DataStore.save(Person(name: "Mary Jane (Callee)"))
        ).flatMap { caller, callee in
            Amplify.DataStore.save(PhoneCall(caller: caller, callee: callee))
        }.flatMap { phoneCall in
            Publishers.Zip(
                Amplify.DataStore.save(
                    Transcript(text: "call transcript in english",
                               language: "en",
                               phoneCall: phoneCall)
                ),
                Amplify.DataStore.save(
                    Transcript(text: "transcripción de la llamada en español",
                               language: "es",
                               phoneCall: phoneCall)
                )
            )
        }.sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in receivedValue.fulfill() })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

}

struct Transcript: Model {
    let id: String
    var text: String
    var language: String?
    var phoneCall: PhoneCall

    init(id: String = UUID().uuidString,
         text: String,
         language: String? = nil,
         phoneCall: PhoneCall) {
        self.id = id
        self.text = text
        self.language = language
        self.phoneCall = phoneCall
    }

    enum CodingKeys: String, ModelKey {
        case id
        case text
        case language
        case phoneCall
    }

    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let transcript = Transcript.keys

        model.pluralName = "Transcripts"

        model.fields(
            .id(),
            .field(transcript.text, is: .required, ofType: .string),
            .field(transcript.language, is: .optional, ofType: .string),
            .belongsTo(transcript.phoneCall, is: .required, ofType: PhoneCall.self, targetName: "phoneCallID")
        )
    }

}

struct PhoneCall: Model {
    let id: String
    var caller: Person
    var callee: Person
    var transcripts: List<Transcript>?

    init(id: String = UUID().uuidString,
         caller: Person,
         callee: Person,
         transcripts: List<Transcript>? = []) {
        self.id = id
        self.caller = caller
        self.callee = callee
        self.transcripts = transcripts
    }
    enum CodingKeys: String, ModelKey {
        case id
        case caller
        case callee
        case transcripts
    }

    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let phoneCall = PhoneCall.keys

        model.pluralName = "PhoneCalls"

        model.fields(
            .id(),
            .belongsTo(phoneCall.caller, is: .required, ofType: Person.self, targetName: "callerID"),
            .belongsTo(phoneCall.callee, is: .required, ofType: Person.self, targetName: "calleeID"),
            .hasMany(phoneCall.transcripts,
                     is: .optional,
                     ofType: Transcript.self,
                     associatedWith: Transcript.keys.phoneCall)
        )
    }

}

struct Person: Model {
    let id: String
    var name: String
    var callerOf: List<PhoneCall>?
    var calleeOf: List<PhoneCall>?

    init(id: String = UUID().uuidString,
         name: String,
         callerOf: List<PhoneCall>? = [],
         calleeOf: List<PhoneCall>? = []) {
        self.id = id
        self.name = name
        self.callerOf = callerOf
        self.calleeOf = calleeOf
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case name
        case callerOf
        case calleeOf
    }

    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let person = Person.keys

        model.pluralName = "People"

        model.fields(
            .id(),
            .field(person.name, is: .required, ofType: .string),
            .hasMany(person.callerOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.caller),
            .hasMany(person.calleeOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.callee)
        )
    }
}

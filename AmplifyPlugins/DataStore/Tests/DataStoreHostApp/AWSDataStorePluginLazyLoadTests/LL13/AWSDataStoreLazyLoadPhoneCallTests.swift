//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

class AWSDataStoreLazyLoadPhoneCallTests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: PhoneCallModels())
        try await startAndWaitForReady()
        printDBPath()
    }
    
    /// Saving a person should be successfully
    ///
    /// - Given: A model instance of a Person
    /// - When:
    ///    - Save the person model
    /// - Then:
    ///    - The model should be saved and reconciled successfully
    func testSavePerson() async throws {
        await setup(withModels: PhoneCallModels())
        let person = Person(name: "name")
        try await saveAndWaitForSync(person)
    }
    
    /// Saving a PhoneCall, requires a caller and a callee, should be successful.
    ///
    /// - Given: Two saved persons
    /// - When:
    ///    - Save a PhoneCall with the two persons as `caller` and `callee`
    /// - Then:
    ///    - The PhoneCall should be saved successfully
    ///    - The queried PhoneCall should allow lazy loading of the caller and calee
    ///    - The queried Person should allow lazy loading of its callerOf or calleeOf
    func testSavePhoneCall() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)

        let phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        let queriedPhoneCall = try await query(for: savedPhoneCall)
        assertLazyReference(queriedPhoneCall._caller,
                            state: .notLoaded(identifiers: [.init(name: "id", value: caller.id)]))
        assertLazyReference(queriedPhoneCall._callee,
                            state: .notLoaded(identifiers: [.init(name: "id", value: callee.id)]))
        let loadedCaller = try await queriedPhoneCall.caller
        let loadedCallee = try await queriedPhoneCall.callee
        assertLazyReference(queriedPhoneCall._caller, state: .loaded(model: savedCaller))
        assertLazyReference(queriedPhoneCall._callee, state: .loaded(model: savedCallee))
        
        let queriedCaller = try await query(for: caller)
        try await queriedCaller.callerOf?.fetch()
        XCTAssertEqual(queriedCaller.callerOf!.count, 1)
        
        let queriedCallee = try await query(for: callee)
        try await queriedCallee.calleeOf?.fetch()
        XCTAssertEqual(queriedCallee.calleeOf!.count, 1)
    }
    
    /// Saving a Transcript with a PhoneCall and a PhoneCall with a Transcript, should be successful
    ///
    /// - Given:  A Transcript with a PhoneCall. A PhoneCall with a Transcript
    /// - When:
    ///    - Save the PhoneCall and Transcript
    /// - Then:
    ///    - The Transcript is saved successfully and has an eager loaded Phonecall
    ///    - The queried Transcript can lazy load the PhoneCall
    ///    - The loaded PhoneCall can lazy load the caller and callee
    ///    - The caller and callee can lazy load its phone calls (callerOf and calleeOf)
    ///
    func testSavePhoneCallAndTranscriptBiDirectional() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        var phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let transcript = Transcript(text: "text", phoneCall: phoneCall)
        
        // When the explicit FK and the connected model exists on the model, setting the connected model
        // has no effect, we have to set the explicit field `phoneCallTranscriptId`.
        // phoneCall.setTranscript(transcript)
        phoneCall.phoneCallTranscriptId = transcript.id
        
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        XCTAssertEqual(savedPhoneCall.phoneCallTranscriptId, transcript.id)
        let savedTranscript = try await saveAndWaitForSync(transcript)
        assertLazyReference(savedTranscript._phoneCall,
                            state: .notLoaded(identifiers: [
                                .init(name: PhoneCall.keys.id.stringValue, value: savedPhoneCall.id)
                            ]))
        
        let queriedTranscript = try await query(for: savedTranscript)
        assertLazyReference(queriedTranscript._phoneCall,
                            state: .notLoaded(identifiers: [
                                .init(name: PhoneCall.keys.id.stringValue, value: savedPhoneCall.id)
                            ]))
        let loadedPhoneCall = try await queriedTranscript.phoneCall!
        assertLazyReference(queriedTranscript._phoneCall,
                            state: .loaded(model: savedPhoneCall))
        let loadedCaller = try await loadedPhoneCall.caller
        let loadedCallee = try await loadedPhoneCall.callee
        
        try await loadedCaller.callerOf?.fetch()
        XCTAssertEqual(loadedCaller.callerOf!.count, 1)
        
        try await loadedCaller.calleeOf?.fetch()
        XCTAssertEqual(loadedCaller.calleeOf!.count, 0)
        
        try await loadedCallee.callerOf?.fetch()
        XCTAssertEqual(loadedCallee.callerOf!.count, 0)
        
        try await loadedCallee.calleeOf?.fetch()
        XCTAssertEqual(loadedCallee.calleeOf!.count, 1)
    }
    
    func testUpdatePhoneCallToTranscript() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        let phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        XCTAssertNil(savedPhoneCall.phoneCallTranscriptId)
        let transcript = Transcript(text: "text", phoneCall: phoneCall)
        let savedTranscript = try await saveAndWaitForSync(transcript)
        
        
        var queriedPhoneCall = try await query(for: savedPhoneCall)
        queriedPhoneCall.phoneCallTranscriptId = transcript.id
        let updatedPhoneCall = try await updateAndWaitForSync(queriedPhoneCall)
        XCTAssertEqual(updatedPhoneCall.phoneCallTranscriptId, transcript.id)
    }
    
    func testDeletePerson() async throws {
        await setup(withModels: PhoneCallModels())
        let person = Person(name: "name")
        let savedPerson = try await saveAndWaitForSync(person)
        
        try await deleteAndWaitForSync(savedPerson)
        try await assertModelDoesNotExist(savedPerson)
    }
    
    /// Deleting a PhoneCall is successful
    ///
    /// - Given: PhoneCall, belongs to two Persons
    /// - When:
    ///    - Delete the PhoneCall
    /// - Then:
    ///    - The PhoneCall is deleted, and the caller/callee is not deleted.
    ///
    func testDeletePhoneCall() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        let phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        
        try await deleteAndWaitForSync(savedPhoneCall)
        try await assertModelExists(caller)
        try await assertModelExists(callee)
    }
    
    /// Delete a Person with PhoneCall will delete the PhoneCall as well, cascade delete the Person's hasMany
    ///
    /// - Given: PhoneCall which belongs to two different Persons (caller and callee)
    /// - When:
    ///    - Delete the Caller
    /// - Then:
    ///    - The Caller is deleted, along with the PhoneCall.
    ///    - The Calle is not deleted
    ///
    func testDeletePersonWithPhoneCall() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        let phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
     
        try await deleteAndWaitForSync(savedCaller)
        try await assertModelDoesNotExist(savedCaller)
        try await assertModelDoesNotExist(savedPhoneCall)
        try await assertModelExists(savedCallee)
    }
    
    /// Delete Transcript does not delete its belongs-to PhoneCall
    ///
    /// - Given: Transcript belongs to a PhoneCall
    /// - When:
    ///    - Delete Transcript
    /// - Then:
    ///    - Transcript is deleted successfully
    ///    - The Transcript's PhoneCall still exists
    ///
    func testDeleteTranscript() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        var phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let transcript = Transcript(text: "text", phoneCall: phoneCall)
        phoneCall.phoneCallTranscriptId = transcript.id
        
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        let savedTranscript = try await saveAndWaitForSync(transcript)
        
        try await deleteAndWaitForSync(transcript)
        try await assertModelDoesNotExist(transcript)
        try await assertModelExists(phoneCall)
    }
    
    /// Deleting a PhoneCall cascades to the hasOne Transcript
    ///
    /// - Given: PhoneCall with Transcript
    /// - When:
    ///    - Delete PhoneCall
    /// - Then:
    ///    - PhoneCall and Transcript is deleted
    ///
    func testDeletePhoneCallWithTranscript() async throws {
        await setup(withModels: PhoneCallModels())
        let caller = Person(name: "caller")
        let savedCaller = try await saveAndWaitForSync(caller)
        let callee = Person(name: "callee")
        let savedCallee = try await saveAndWaitForSync(callee)
        var phoneCall = PhoneCall(caller: savedCaller, callee: savedCallee)
        let transcript = Transcript(text: "text", phoneCall: phoneCall)
        phoneCall.phoneCallTranscriptId = transcript.id
        
        let savedPhoneCall = try await saveAndWaitForSync(phoneCall)
        let savedTranscript = try await saveAndWaitForSync(transcript)
        
        try await deleteAndWaitForSync(savedPhoneCall)
        try await assertModelDoesNotExist(savedPhoneCall)
        try await assertModelDoesNotExist(savedTranscript)
    }
}

extension AWSDataStoreLazyLoadPhoneCallTests {
    
    struct PhoneCallModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PhoneCall.self)
            ModelRegistry.register(modelType: Person.self)
            ModelRegistry.register(modelType: Transcript.self)
        }
    }
}

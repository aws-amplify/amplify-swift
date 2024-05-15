//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

final class GraphQLTeamMember3Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#create-a-has-many-relationship-between-records
    func testCreate() async throws {
        await setup(withModels: TeamMember3Models())

        // Code Snippet Begins
        do {
            let team = Team(mantra: "Go Frontend!")
            let createdTeam = try await Amplify.API.mutate(request: .create(team)).get()

            let member = Member(
                name: "Tim",
                team: createdTeam) // Directly pass in the team instance
            let createdMember = try await Amplify.API.mutate(request: .create(member))
        } catch {
            print("Create team or member failed", error)

            // Code Snippet Ends
            XCTFail("Failed to create team or member, error: \(error)")
            // Code Snippet Begins
        }

    }
    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#update-a-has-many-relationship-between-records
    func testUpdate() async throws {
        await setup(withModels: TeamMember3Models())

        let oldTeam = Team(mantra: "Go Frontend!")
        let oldTeamCreated = try await Amplify.API.mutate(request: .create(oldTeam)).get()
        let member = Member(
            name: "Tim",
            team: oldTeamCreated) // Directly pass in the post instance
        var existingMember = try await Amplify.API.mutate(request: .create(member)).get()

        // Code Snippet Begins
        do {
            let newTeam = Team(mantra: "Go Fullstack!")
            let createdNewTeam = try await Amplify.API.mutate(request: .create(newTeam)).get()

            existingMember.setTeam(createdNewTeam)
            let updatedMember = try await Amplify.API.mutate(request: .update(existingMember)).get()

            // Code Snippet Ends
            guard let loadedTeam = try await updatedMember.team else {
                XCTFail("Could not get team from member")
                return
            }
            XCTAssertEqual(loadedTeam.id, newTeam.id)
            // Code Snippet Begins
        } catch {
            print("Create team or update member failed", error)

            // Code Snippet Ends
            XCTFail("Failed to create team or update member to new team, error: \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#delete-a-has-many-relationship-between-records
    func testDelete() async throws {
        await setup(withModels: TeamMember3Models())
        let team = Team(mantra: "Go Frontend!")
        let teamCreated = try await Amplify.API.mutate(request: .create(team)).get()
        let member = Member(
            name: "Tim",
            team: teamCreated) // Directly pass in the post instance
        var existingMember = try await Amplify.API.mutate(request: .create(member)).get()

        // Code Snippet Begins
        do {
            existingMember.setTeam(nil)
            _ = try await Amplify.API.mutate(request: .update(existingMember)).get()
        } catch {
            print("Failed to remove team from member", error)
            // Code Snippet Ends
            XCTFail("Failed to remove team from member \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#lazy-load-a-has-many-relationship
    func testLazyLoadHasMany() async throws {
        await setup(withModels: TeamMember3Models())
        let team = Team(mantra: "Go Frontend!")
        let teamCreated = try await Amplify.API.mutate(request: .create(team)).get()
        let member = Member(
            name: "Tim",
            team: teamCreated) // Directly pass in the post instance
        _ = try await Amplify.API.mutate(request: .create(member)).get()

        // Code Snippet Begins
        do {
            let queriedTeam = try await Amplify.API.query(
                request: .get(
                    Team.self,
                    byIdentifier: team.identifier)).get()

            guard let queriedTeam, let members = queriedTeam.members else {
                print("Missing team or members")
                // Code Snippet Ends
                XCTFail("Missing team or its members")
                // Code Snippet Begins
                return
            }
            try await members.fetch()
            print("Number of members: \(members.count)")
            // Code Snippet Ends
            XCTAssertTrue(members.count > 0)
            // Code Snippet Begins
        } catch {
            print("Failed to fetch team or members", error)
            // Code Snippet Ends
            XCTFail("Failed to fetch team or members \(error)")
            // Code Snippet Begins
        }
    }

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#eagerly-load-a-has-many-relationship
    func testEagerLoadHasMany() async throws {
        await setup(withModels: TeamMember3Models())
        let team = Team(mantra: "Go Frontend!")
        let teamCreated = try await Amplify.API.mutate(request: .create(team)).get()
        let member = Member(
            name: "Tim",
            team: teamCreated) // Directly pass in the post instance
        _ = try await Amplify.API.mutate(request: .create(member)).get()

        // Code Snippet Begins
        do {
            let queriedTeamWithMembers = try await Amplify.API.query(
                request: .get(
                    Team.self,
                    byIdentifier: team.identifier,
                    includes: { team in [team.members]}))
                .get()
            guard let queriedTeamWithMembers, let members = queriedTeamWithMembers.members else {
                print("Missing team or members")
                // Code Snippet Ends
                XCTFail("Missing team or its members")
                // Code Snippet Begins
                return
            }
            print("Number of members: \(members.count)")
            // Code Snippet Ends
            XCTAssertTrue(members.count > 0)
            // Code Snippet Begins
        } catch {
            print("Failed to fetch team with members", error)
            // Code Snippet Ends
            XCTFail("Failed to fetch team with members \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLTeamMember3Tests: DefaultLogger { }

extension GraphQLTeamMember3Tests {
    typealias Team = Team3
    typealias Member = Member3

    struct TeamMember3Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Team3.self)
            ModelRegistry.register(modelType: Member3.self)
        }
    }
}

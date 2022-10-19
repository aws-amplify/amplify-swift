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

class AWSDataStoreLazyLoadProjectTeam1Tests: AWSDataStoreLazyLoadBaseTest {
    
    func testSaveTeam() async throws {
        await setup(withModels: ProjectTeam1Models(), eagerLoad: false)
        let team = Team1(teamId: UUID().uuidString, name: "name")
        let savedTeam = try await saveAndWaitForSync(team)
        
        let project = Project1(projectId: UUID().uuidString,
                               name: "name",
                               team: team,
                               project1TeamTeamId: team.teamId,
                               project1TeamName: team.name)
        let savedProject = try await saveAndWaitForSync(project)
    }
}

extension AWSDataStoreLazyLoadProjectTeam1Tests {
    struct ProjectTeam1Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Project1.self)
            ModelRegistry.register(modelType: Team1.self)
        }
    }
}

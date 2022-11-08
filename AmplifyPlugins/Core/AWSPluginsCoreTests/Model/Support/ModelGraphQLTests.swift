//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class ModelGraphQLTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Team1.self)
        ModelRegistry.register(modelType: Project1.self)
        ModelRegistry.register(modelType: Team2.self)
        ModelRegistry.register(modelType: Project2.self)
        ModelRegistry.register(modelType: ModelExplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelExplicitCustomPk.self)
        ModelRegistry.register(modelType: ModelImplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelCompositePk.self)
        ModelRegistry.register(modelType: ModelCompositePkWithAssociation.self)
        ModelRegistry.register(modelType: ModelCompositePkBelongsTo.self)
        ModelRegistry.register(modelType: PostWithCompositeKey.self)
        ModelRegistry.register(modelType: CommentWithCompositeKey.self)
    }

    /// - Given: a `Model` type
    /// - When:
    ///    - the model is of type `Post`
    ///    - the model is initialized with value except `updatedAt` is set to nil
    /// - Then:
    ///    - check if the generated GraphQLInput is valid input:
    ///      - fields other than `updatedAt` has the correct value in them
    ///      - `updatedAt` is nil
    func testPostModelToGraphQLInputSuccess() throws {
        let date: Temporal.DateTime = .now()
        let status = PostStatus.published
        let post = Post(id: "id",
                        title: "title",
                        content: "content",
                        createdAt: date,
                        draft: true,
                        rating: 5.0,
                        status: status)

        let graphQLInput = post.graphQLInputForMutation(Post.schema, mutationType: .create)

        XCTAssertEqual(graphQLInput["title"] as? String, post.title)
        XCTAssertEqual(graphQLInput["content"] as? String, post.content)
        XCTAssertEqual(graphQLInput["createdAt"] as? String, post.createdAt.iso8601String)
        XCTAssertEqual(graphQLInput["draft"] as? Bool, post.draft)
        XCTAssertEqual(graphQLInput["rating"] as? Double, post.rating)
        XCTAssertEqual(graphQLInput["status"] as? String, status.rawValue)

        XCTAssertTrue(graphQLInput.keys.contains("updatedAt"))
        XCTAssertNil(graphQLInput["updatedAt"]!)
    }

    func testTodoModelToGraphQLInputSuccess() {
        let color = Color(name: "red", red: 255, green: 0, blue: 0)
        let category = Category(name: "green", color: color)
        let todo = Todo(name: "name",
                        description: "description",
                        categories: [category],
                        stickies: ["stickie1"])

        let graphQLInput = todo.graphQLInputForMutation(Todo.schema, mutationType: .create)

        XCTAssertEqual(graphQLInput["id"] as? String, todo.id)
        XCTAssertEqual(graphQLInput["name"] as? String, todo.name)
        XCTAssertEqual(graphQLInput["description"] as? String, todo.description)
        guard let categories = graphQLInput["categories"] as? [[String: Any]] else {
            XCTFail("Couldn't get array of categories")
            return
        }
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0]["name"] as? String, category.name)
        guard let expectedColor = categories[0]["color"] as? [String: Any] else {
            XCTFail("Couldn't get color in category")
            return
        }
        XCTAssertEqual(expectedColor["name"] as? String, color.name)
        XCTAssertEqual(expectedColor["red"] as? Int, color.red)
        XCTAssertEqual(expectedColor["green"] as? Int, color.green)
        XCTAssertEqual(expectedColor["blue"] as? Int, color.blue)
    }

    func testRecordModelWithReadOnlyFields() {
        let record = Record(id: "id", name: "name", description: "description")
        let graphQLInput = record.graphQLInputForMutation(Record.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, record.id)
        XCTAssertEqual(graphQLInput["name"] as? String, record.name)
        XCTAssertEqual(graphQLInput["description"] as? String, record.description)
        XCTAssertNil(graphQLInput["createdAt"] as? Temporal.DateTime)
        XCTAssertNil(graphQLInput["updatedAt"] as? Temporal.DateTime)
    }

    // MARK: - `Project1` and `Team1`

    func testProjectBelongsToTeam() {
        let team1 = Team1(name: "team")
        let project1 = Project1(team: team1)

        let graphQLInput = project1.graphQLInputForMutation(Project1.schema, mutationType: .create)

        XCTAssertEqual(graphQLInput["id"] as? String, project1.id)
        XCTAssertTrue(graphQLInput.keys.contains("name"))
        XCTAssertNil(graphQLInput["name"]!)
        XCTAssertEqual(graphQLInput["project1TeamId"] as? String, team1.id)
        XCTAssertFalse(graphQLInput.keys.contains("team"))
    }

    // MARK: - HasOne `Project2` and `Team2`

    func testProjectHasOneTeamSuccess() {
        let team2 = Team2(name: "team")
        let project2 = Project2(teamID: team2.id, team: team2)
        let graphQLInput = project2.graphQLInputForMutation(Project2.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, project2.id)
        XCTAssertTrue(graphQLInput.keys.contains("name"))
        XCTAssertNil(graphQLInput["name"]!)
        XCTAssertEqual(graphQLInput["teamID"] as? String, team2.id)
        XCTAssertFalse(graphQLInput.keys.contains("team"))
    }

    /// The GraphQL input should always take the object over the explicit `teamID` field
    func testProjectHasOneTeamRandomTeamIDSuccess() {
        let team2 = Team2(name: "team")
        let project2 = Project2(teamID: "randomTeamId", team: team2)
        let graphQLInput = project2.graphQLInputForMutation(Project2.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, project2.id)
        XCTAssertTrue(graphQLInput.keys.contains("name"))
        XCTAssertNil(graphQLInput["name"]!)
        XCTAssertEqual(graphQLInput["teamID"] as? String, team2.id)
        XCTAssertFalse(graphQLInput.keys.contains("team"))
    }

    /// The GraphQL input should contain the `teamID` provided if the team object is not passed in.
    func testProjectHasOneTeamMissingTeamObjectSuccess() {
        let team2 = Team2(name: "team")
        let project2 = Project2(teamID: team2.id)
        let graphQLInput = project2.graphQLInputForMutation(Project2.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, project2.id)
        XCTAssertTrue(graphQLInput.keys.contains("name"))
        XCTAssertNil(graphQLInput["name"]!)
        XCTAssertEqual(graphQLInput["teamID"] as? String, team2.id)
        XCTAssertFalse(graphQLInput.keys.contains("team"))
    }

    // MARK: - Custom Primary Key
    func testModelWithExplicitDefaultPrimaryKey() {
        let model = ModelExplicitDefaultPk(id: "an-id", name: "name")
        let graphQLInput = model.graphQLInputForMutation(model.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, model.id)
        XCTAssertEqual(graphQLInput["name"] as? String, model.name)
    }

    func testModelWithExplicitCustomPrimaryKey() {
        let model = ModelExplicitCustomPk(userId: "userId", name: "name")
        let graphQLInput = model.graphQLInputForMutation(model.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["userId"] as? String, model.userId)
        XCTAssertEqual(graphQLInput["name"] as? String, model.name)
    }

    func testModelWithExplicitCompositePrimaryKey() {
        let model = ModelCompositePk(id: "id", dob: Temporal.DateTime.now(), name: "name")
        let graphQLInput = model.graphQLInputForMutation(model.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, model.id)
        XCTAssertEqual(graphQLInput["dob"] as? String, model.dob.iso8601String)
        XCTAssertEqual(graphQLInput["name"] as? String, model.name)
    }

    func testModelWithAssociationAndCompositePrimaryKey() {
        let owner = ModelCompositePkWithAssociation(id: "id2",
                                                     dob: Temporal.DateTime.now(),
                                                     name: "name")
        let childModel = ModelCompositePkBelongsTo(id: "id1",
                                               dob: Temporal.DateTime.now(),
                                               name: "name",
                                               owner: owner)

        let graphQLInput = childModel.graphQLInputForMutation(childModel.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, childModel.id)
        XCTAssertEqual(graphQLInput["dob"] as? String, childModel.dob.iso8601String)
        XCTAssertEqual(graphQLInput["name"] as? String, childModel.name)
        XCTAssertEqual(graphQLInput["modelCompositePkWithAssociationOtherModelsId"] as? String,
                       owner.id)
        XCTAssertEqual(graphQLInput["modelCompositePkWithAssociationOtherModelsDob"] as? Temporal.DateTime,
                       owner.dob)
    }

    func testModelWithHasManyAssociationAndCompositePrimaryKey() {
        let parent = PostWithCompositeKey(title: "title")
        let childModel = CommentWithCompositeKey(content: "comment", post: parent)

        let graphQLInput = childModel.graphQLInputForMutation(childModel.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, childModel.id)
        XCTAssertEqual(graphQLInput["content"] as? String, childModel.content)
        XCTAssertEqual(graphQLInput["postWithCompositeKeyCommentsId"] as? String, parent.id)
        XCTAssertEqual(graphQLInput["postWithCompositeKeyCommentsTitle"] as? String, parent.title)
    }

    func testModelWithHasManyUnidirectionalAssociationAndCompositePrimaryKey() {
        let parent = PostWithCompositeKeyUnidirectional(title: "title")
        let childModel = CommentWithCompositeKeyUnidirectional(content: "comment",
                                                               postWithCompositeKeyUnidirectionalCommentsId: parent.id,
                                                               postWithCompositeKeyUnidirectionalCommentsTitle: parent.title)

        let graphQLInput = childModel.graphQLInputForMutation(childModel.schema, mutationType: .create)
        XCTAssertEqual(graphQLInput["id"] as? String, childModel.id)
        XCTAssertEqual(graphQLInput["content"] as? String, childModel.content)
        XCTAssertEqual(graphQLInput["postWithCompositeKeyUnidirectionalCommentsId"] as? String, parent.id)
        XCTAssertEqual(graphQLInput["postWithCompositeKeyUnidirectionalCommentsTitle"] as? String, parent.title)
    }
}

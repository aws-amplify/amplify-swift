//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class IntegrationTestConfiguration {


    // TODO: `taskPrivateNoteGraphQLWithUserPool` tests not are completed. this is just a placeholder.
    /*
     These are the instructions to set up the `taskPrivateNoteGraphQLWithUserPool`. It contains the project with
     'Objects with fine-grained access control' and UserPool authentication

     TODO: Amplify CLI flow: add authorization type `User Pool` to the graphql API and use the task/private note schema
     for the fine grain access control, ie. cognito groups, etc.
     */
    static let taskPrivateNoteGraphQLWithUserPool = "taskPrivateNoteGraphQLWithUserPool"


    // TODO: Move this to a test credentials file before final merge
    static let apiConfig = APICategoryConfiguration(plugins: [
        "awsAPIPlugin": [
            IntegrationTestConfiguration.taskPrivateNoteGraphQLWithUserPool: [
                "endpoint": "https://qaobhulmjzg2fjpxh45rpef5i4.appsync-api.us-east-1.amazonaws.com/graphql",
                "region": "us-east-1",
                "authorizationType": "AMAZON_COGNITO_USER_POOLS"
            ]
        ]
    ])
}

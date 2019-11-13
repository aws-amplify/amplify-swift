//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class IntegrationTestConfiguration {

    /*
     These are the instructions to set up the `todoGraphQLWithAPIKey` api. If for whatever reason, test resources are
     deleted from test credentails then these are the steps to recreate the resource:
     1. Run `amplify init` and choose `ios` for the type of app you're building

     2. Add api `amplify add api`
        * Please select from one of the below mentioned services `GraphQL`
        * Provide API name: `amplifyapigraphqlsam`
        * Choose the default authorization type for the API `API key`
        * Enter a description for the API key: `keyy`
        * After how many days from now the API key should expire (1-365): `180`
        * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        * Do you have an annotated GraphQL schema? `No`
        * Do you want a guided schema creation? `Yes`
        * What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
        * Do you want to edit the schema now? `No`

     3. `amplify push`
        * Do you want to generate code for your newly created GraphQL API `Yes`
        * Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
        * Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
        * Enter the file name for the generated code `API.swift`
         * GraphQL endpoint: `https://szc4yxxxxxxxxxxqaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql`
         * GraphQL API KEY: `da2-kjsuxxxxxxxxxx4pujny`
     */
    static let todoGraphQLWithAPIKey = "todoGraphQLWithAPIKey"

    /*
     These are the instructions to set up the `blogPostCommonGraphQLWithAPIKey`. Same as `todoGraphQLWithAPIKey`
     except with the Blog Post and Comment graphQL schema

     2. Add api `amplify add api`
         * What best describes your project: `One-to-many relationship (e.g., “Blogs” with “Posts” and “Comments”)`

     3. `amplify push`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `3`

     */
    static let blogPostGraphQLWithAPIKey = "blogPostCommentGraphQLWithAPIKey"

    /*
     Using the same values as `blogPostCommonGraphQLWithAPIKey` except the API key is replaced with an invalid one.
     */
    static let blogPostGraphQLWithInvalidAPIKey = "blogPostCommentGraphQLWithInvalidAPIKey"

    /*
     These instructions for `todoGraphQLWithIAM` is to set up the GraphQL appsync endpoint with
     - Default authorization mode to be "AWS Identity and Access Management (IAM)"
     - Cognito identity pool with no guess access
     === WARNING: this is not working without setting IAM policy to allow GraphQL operations ===

     1. Run `amplify init` and choose `ios` for the type of app you're building

     2. Add api `amplify add api`
         * Please select from one of the below mentioned services `GraphQL`
         * Provide API name: `temp123`
         * Choose the default authorization type for the API `IAM`
         * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
         * Do you have an annotated GraphQL schema? `No`
         * Do you want a guided schema creation? `Yes`
         * What best describes your project: `Objects with fine-grained access control (e.g., a project management app
            with owner-based authorization)`
         * Do you want to edit the schema now? `No`

     3. Add Auth `amplify add auth`
     Using service: Cognito, provided by: awscloudformation

      The current configured provider is Amazon Cognito.

      Do you want to use the default authentication and security configuration? `Default configuration`
      Warning: you will not be able to edit these selections.
      How do you want users to be able to sign in? Username
      Do you want to configure advanced settings? `No, I am done.`
     Successfully added resource appsyncsample6b51ebcc locally

     4. `amplify push`
        * Do you want to generate code for your newly created GraphQL API `Yes`
        * Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
        * Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
        * Enter the file name for the generated code `API.swift`
        * GraphQL endpoint: `https://szc4yxxxxxxxxxxqaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql`

     5. Update the IAMPolicy to allow operations on the GraphQL service
      TODO: Fix these instructions
     */
    static let todoGraphQLWithIAM = "todoGraphQLWithIAM"

    /* Instructions for `todoGraphQLWithUserPools`
     `amplify add api`
        * Please select from one of the below mentioned services GraphQL
        * Provide API name: api4
        * Choose the default authorization type for the API Amazon Cognito User Pool
     Using service: Cognito, provided by: awscloudformation

      The current configured provider is Amazon Cognito.

      Do you want to use the default authentication and security configuration? Default configuration
      Warning: you will not be able to edit these selections.
      How do you want users to be able to sign in? Email
      Do you want to configure advanced settings? No, I am done.
     Successfully added auth resource
        * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        * Do you have an annotated GraphQL schema? `No`
        * Do you want a guided schema creation? `Yes`
        * What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
        * Do you want to edit the schema now? `No`
     */
    static let todoGraphQLWithUserPools = "todoGraphQLWithUserPools"

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
        "AWSAPICategoryPlugin": [
            "none": [
                "Endpoint": "https://0idx6yjn11.execute-api.us-east-1.amazonaws.com/beta",
                "Region": "us-east-1",
                "AuthorizationType": "NONE"
            ],
            "apiKey": [
                "Endpoint": "https://rqdxvfh3ue.execute-api.us-east-1.amazonaws.com/Prod",
                "Region": "us-east-1",
                "AuthorizationType": "API_KEY",
                "ApiKey": "KjbPeqbh9F7hc2n2UVkpfD8WKF1kkYX3ydrkyHq6"
            ],
            IntegrationTestConfiguration.todoGraphQLWithAPIKey: [
                "Endpoint": "https://akeljq43xfcvpj4hh55fafcrm4.appsync-api.us-west-2.amazonaws.com/graphql",
                "Region": "us-west-2",
                "AuthorizationType": "API_KEY",
                "ApiKey": "da2-6m3mowpbavh55kscoikywhqova"
            ],
            IntegrationTestConfiguration.blogPostGraphQLWithAPIKey: [
                "Endpoint": "https://dtoaraxmjjdbjfmoqwowubiyua.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "API_KEY",
                "ApiKey": "da2-4th2pofe7ne4xdm3va23hvovfa"
            ],
            IntegrationTestConfiguration.blogPostGraphQLWithInvalidAPIKey: [
                "Endpoint": "https://dtoaraxmjjdbjfmoqwowubiyua.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "API_KEY",
                "ApiKey": "da2-invalidAPIKey"
            ],
            IntegrationTestConfiguration.todoGraphQLWithIAM: [
                "Endpoint": "https://fsdfgjw5ojdanhivobrnmw54s4.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "AWS_IAM"
            ],
            IntegrationTestConfiguration.todoGraphQLWithUserPools: [
                "Endpoint": "https://ggp44fsi3fg5hhg5vq6r65a5wu.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "AMAZON_COGNITO_USER_POOLS"
            ],
            IntegrationTestConfiguration.taskPrivateNoteGraphQLWithUserPool: [
                "Endpoint": "https://qaobhulmjzg2fjpxh45rpef5i4.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "AMAZON_COGNITO_USER_POOLS"
            ]
        ]
    ])
}

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
     These are the instructions to set up the `blogPostCommonGraphQLWithAPIKey`
     1. Run `amplify init` and choose `ios` for the type of app you're building

     2. Add api `amplify add api`
         * Please select from one of the below mentioned services `GraphQL`
         * Provide API name: `temp123`
         * Choose the default authorization type for the API `API key`
         * Enter a description for the API key: `keyy`
         * After how many days from now the API key should expire (1-365): `180`
         * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
         * Do you have an annotated GraphQL schema? `No`
         * Do you want a guided schema creation? `Yes`
         * What best describes your project: `One-to-many relationship (e.g., “Blogs” with “Posts” and “Comments”)`
         * Do you want to edit the schema now? `No`

     3. `amplify push`
        * Do you want to generate code for your newly created GraphQL API `Yes`
        * Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
        * Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `3`
        * Enter the file name for the generated code `API.swift`
        * GraphQL endpoint: `https://szc4yxxxxxxxxxxqaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql`
        * GraphQL API KEY: `da2-kjsuxxxxxxxxxx4pujny`

     note: for depth we have specified 3
     */
    static let blogPostGraphQLWithAPIKey = "blogPostCommentGraphQLWithAPIKey"
    static let blogPostGraphQLWithInvalidAPIKey = "blogPostCommentGraphQLWithInvalidAPIKey"

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
                "Endpoint": "https://szc4y7y4mze43foty6qaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql",
                "Region": "us-east-1",
                "AuthorizationType": "API_KEY",
                "ApiKey": "da2-kjsu57qbwvbmzh4bphn7mpujny"
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
            ]
        ]
    ])
}

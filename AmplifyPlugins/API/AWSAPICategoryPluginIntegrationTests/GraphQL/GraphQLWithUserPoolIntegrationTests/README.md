## GraphQL with UserPool Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be Cognito UserPools. This set up is used to run the tests in `GraphQLWithUserPoolIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: GraphQL
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `Amazon Cognito User Pool`
? Do you want to use the default authentication and security configuration? `Default configuration`
? How do you want users to be able to sign in? `Email`
? Do you want to configure advanced settings? `No, I am done.`
? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
? Do you have an annotated GraphQL schema? `No`
? Do you want a guided schema creation? `Yes`
? What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
? Do you want to edit the schema now? `No`
```

The guided schema provided should look like this: 
```json
type Todo @model {
  id: ID!
  name: String!
  description: String
}
```

3. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

4. Enable `testSetUpOnce()` and run it to sign up a new user.

5. `amplify console auth`
```perl
? Which console `User Pool`
```

Click on `Users and groups`, select the user that was created, and click on Confirm User.

6. Disable `testSetUpOnce()` test and run the rest of the tests.

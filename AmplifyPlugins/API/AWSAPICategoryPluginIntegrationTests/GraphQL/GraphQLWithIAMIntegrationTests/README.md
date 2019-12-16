## GraphQL with IAM Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be IAM. This set up is used to run the tests in `GraphQLWithIAMIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`

```perl
* Please select from one of the below mentioned services `GraphQL`
* Provide API name: `temp123`
* Choose the default authorization type for the API `IAM`
* Do you want to configure advanced settings for the GraphQL API `No, I am done.`
* Do you have an annotated GraphQL schema? `No`
* Do you want a guided schema creation? `Yes`
* What best describes your project: `Objects with fine-grained access control (e.g., a project management app
    with owner-based authorization)`
* Do you want to edit the schema now? `No`
```

3. `amplify add auth`
```perl
Do you want to use the default authentication and security configuration? `Default configuration`
How do you want users to be able to sign in? `Email`
Do you want to configure advanced settings? `No, I am done.`
```

4. `amplify push`

5. Update the IAMPolicy to allow operations on the GraphQL service

TODO: Figure out how to use Amplify CLI to  `amplify add api` and select `IAM` auth. Currently it does not set up correct IAM policies. 

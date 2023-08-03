## GraphQL with UserPool Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be Cognito UserPools. This set up is used to run the tests in `GraphQLWithUserPoolIntegrationTests.swift`.

### Set-up

Latest tested with amplify CLI version 9.1.0 `amplify -v`

* Note that these integration tests are only compatible with the V1 Transformer. * 

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: GraphQL
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `Amazon Cognito User Pool`
? Do you want to use the default authentication and security configuration? 
    Manual configuration
Select the authentication/authorization services that you want to use: 
    User Sign-Up, Sign-In, connected with AWS IAM controls (Enables ...)
Please provide a friendly name for your resource that will be used to label this category in the project: 
    <amplifyintegtest>
Please enter a name for your identity pool. 
    <amplifyintegtestCIDP>
Allow unauthenticated logins? (Provides scoped down permissions that you can control via AWS IAM) 
    No
Do you want to enable 3rd party authentication providers in your identity pool? 
    No
Please provide a name for your user pool: 
    <amplifyintegCUP>

How do you want users to be able to sign in? 
    Username
Do you want to add User Pool Groups? 
    No
Do you want to add an admin queries API? 
    Yes
Do you want to restrict access to the admin queries API to a specific Group 
    No
Multifactor authentication (MFA) user login options: 
    OFF
 
Email based user registration/forgot password: 
    Enabled (Requires per-user email entry at registration)
Please specify an email verification subject: 
    Your verification code
Please specify an email verification message: 
    Your verification code is {####}
Do you want to override the default password policy for this User Pool? 
    No
 
What attributes are required for signing up? 
   (Press Space to deselect Email, if selected, then press Enter with none selected)
 Specify the app's refresh token expiration period (in days): 
    30
Do you want to specify the user attributes this app can read and write? 
    No
Do you want to enable any of the following capabilities?
    (press Enter with none selected)
Do you want to use an OAuth flow? 
    No
Do you want to configure Lambda Triggers for Cognito? 
    Yes
Which triggers do you want to enable for Cognito
    Pre Sign-up
    [Choose as many that you would like to manually verify later]
What functionality do you want to use for Pre Sign-up 
    Create your own module
Succesfully added the Lambda function locally
Do you want to edit your custom function now? Yes
Please edit the file in your editor: 
```

For Pre Sign-up lambda

```
exports.handler = async (event, context) => {
  event.response.autoConfirmUser = true;
  return event
};
```

Continue in the terminal;

```
? Press enter to continue
Successfully added resource amplifyintegtest locally


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

3. If you are using the latest CLI, update cli.json to include `"useExperimentalPipelinedTransformer": false` to ensure that it will use the v1 transformer.

4. `amplify push`

```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` as `GraphQLWithUserPoolIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/GraphQLWithUserPoolIntegrationTests-amplifyconfiguration.json
```

6. Run the rest of the tests.


### API.Swift

API.Swift is a file generated from `amplify codegen types`. This file has been checked in and won't need to be regenerated unless there is a change to the schema or codegen process. If you do need to regenerate the file, run the following command:

`amplify codegen add`
```
? Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
? Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
? Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
? Enter the file name for the generated code `API.swift`
? Do you want to generate code for your newly created GraphQL API `Yes`
✔ Generated GraphQL operations successfully and saved at graphql
✔ Code generated successfully and saved in file API.swift
```

The output file was modified to avoid type collision with existing types by namespacing the types generated 
under a **APISwift** struct at line 556 to 2132. As such, the corresponding tests use the types by prefixing it with "APISwift"
such as "APISwift.CreateTodoMutation", however the actual developer experience will just be "CreateTodoMutation".

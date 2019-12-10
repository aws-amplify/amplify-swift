
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

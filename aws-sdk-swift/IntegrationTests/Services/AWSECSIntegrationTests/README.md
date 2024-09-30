#  AWSECSIntegrationTests Description

- ECSAWSCredentialIdentityResolverTests will launch all configuration needed to run a dockerized Swift package as a task inside of a Fargate ARM64 ECS cluster.
- The test will poll the task every X seconds (30) to see if it is completed.
- Upon task completion, the latest log stream will be scanned to look for keyword 'Success!' which the Swift program running inside of the cluster will emit if successful.
- ECS resources are cleaned up but cloudwatch logs and IAM roles remain so that the test can be re-run.
- Test should take ~3-5 minutes to run.
- See README.md inside of ECSIntegTestApp for further details.

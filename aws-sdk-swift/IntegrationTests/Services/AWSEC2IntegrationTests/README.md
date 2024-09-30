## IMDS AWS credential identity resolver integration testing

The package under `Resources/IMDSIntegTestApp` will be used to test the IMDS AWS credential identity resolver against a live EC2 instance. The below steps will need to be excuted prior to running the integration test.

The bash script `./deploy-docker-to-ecr` needs to be executed at least once per AWS account. The script builds the docker image that contains the test application (ECSIntegTestApp) then pushes it to a private repository in AWS Elastic Container Registry (ECR). Then when you run the integration test, the EC2 instance pulls that image from ECR at launch and runs it. The results are then logged to CloudWatch Logs, which is what determines test pass / failure. 
The script also needs to be executed if underlying package dependencies for the test package need to be updated.

`./deploy-docker-to-ecr` script manual:
- Make sure you have permissions configured using aws configure
- Make sure you have docker daemon running
- Make script executable with `chmod +x deploy-docker-to-ecr.sh`
- Only required command argument is the first one, which is the account ID. It's used for either constructing the ECR repo URL. Two optional commands following it are region and ECR repo name to use. Example commands: `./deploy-docker-to-ecr.sh 123456789012` or `./deploy-docker-to-ecr.sh 123456789012 us-west-2` or `./deploy-docker-to-ecr.sh 123456789012 us-west-2 my-repo-name`
- When login prompt pops up, use your aws username/password. This signs your docker daemon to AWS ECR Repo so you can push image up to it.


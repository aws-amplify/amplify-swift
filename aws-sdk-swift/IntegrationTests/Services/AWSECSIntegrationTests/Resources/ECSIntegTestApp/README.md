## ECS Integration Testing

This package will be used to test aws-sdk-swift and AWS ECS. The below steps will need to be excuted prior to running the integration test. The contents of this package are executed inside of an ECS cluster.

Note: `./deploy-docker-to-ecr` only needs to be executed once per AWS account and if updates are needed to the underlying package versions or test run inside ECS container

How to use `./deploy-docker-to-ecr`:
- Make sure you have permissions configured using aws configure and docker daemon running
- `chmod +x deploy-docker-to-ecr.sh`
- `./deploy-docker-to-ecr.sh 123456789012` or `./deploy-docker-to-ecr.sh 123456789012 us-west-2` or `./deploy-docker-to-ecr.sh 123456789012 us-west-2 my-repo-name`
- if login window pops up, login using either your aws username/password or temporary access credentials and write `exit` upon successful login (bug)


#!/bin/sh

# FROM https://github.com/sebsto/amplify-ios-getting-started/tree/main/code

# ./scripts/create-ec2-snapshot.sh -i 10.100.255.60 -d "some description"
while getopts i:d: flag
do
    case "${flag}" in
        i) ip=${OPTARG};;
        d) description=${OPTARG};;
    esac
done

REGION=us-west-2

QUERY='Reservations[].Instances[?PublicIpAddress==`' 
QUERY+=$ip 
QUERY+='`].BlockDeviceMappings[][].Ebs.VolumeId'

# REPLACE THE IP ADDRESS IN THE COMMAND BELOW
# Use the EC2 Instance Public IP
EBS_VOLUME_ID=$(aws ec2 --region $REGION describe-instances --query $QUERY --output text)

# REPLACE THE DESCRIPTION IN THE COMMAND BELOW
aws ec2 create-snapshot --region $REGION --volume-id $EBS_VOLUME_ID --description "$description"
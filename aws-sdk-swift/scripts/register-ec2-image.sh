#!/bin/sh

# FROM https://github.com/sebsto/amplify-ios-getting-started/tree/main/code

#./scripts/register-ec2-image.sh -s snap-0000000 -n "temp_name" -d "temp description" -a arm64_mac
while getopts s:n:d:a: flag
do
    case "${flag}" in
        s) snapshot=${OPTARG};;
        n) name=${OPTARG};;
        d) description=${OPTARG};;
        a) architecture=${OPTARG};; # either x86_64_mac or arm64_mac
    esac
done

REGION=us-west-2
SNAPSHOT_ID=$snapshot
aws ec2 register-image --region=$REGION --name "$name" --description "$description" --architecture $architecture --virtualization-type hvm --block-device-mappings DeviceName="/dev/sda1",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"

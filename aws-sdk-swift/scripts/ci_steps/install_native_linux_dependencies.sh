#!/bin/bash

# Installs native dependencies required to run CI tasks on either
# Ubuntu (with apt) or Amazon Linux 2 (with yum).


if [ -x "$(command -v apt)" ]; then
  apt-get update && apt-get install -y libssl-dev
else
  yum install -y openssl-devel which
fi

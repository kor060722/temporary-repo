#!/bin/bash
sudo yum install -y amazon-ssm-agent
sudo systemctl enable --now amazon-ssm-agent
sudo systemctl restart amazon-ssm-agent


# ECS CloudFormation with Fluent Bit Logging Solution

## Introduction

This document outlines the steps to deploy a containerized application on AWS ECS using CloudFormation, along with setting up Fluent Bit for log forwarding. Fluent Bit will parse and forward logs to Amazon OpenSearch Service and Amazon S3. Additionally, the setup includes a comprehensive VPC configuration for a 3-tier architecture.

## Problem Statement

Managing containerized applications involves monitoring and logging challenges. Traditional logging methods are insufficient for dynamic environments like ECS. There is a need for a robust solution to collect, parse, and forward logs to centralized systems for analysis and storage.

## Solution
This solution uses AWS CloudFormation to automate the deployment of an ECS service with Fluent Bit for log management. Fluent Bit is configured to parse logs using custom parsers and forward them to Amazon OpenSearch Service and S3. The deployment includes a custom VPC setup to ensure secure and isolated networking for the ECS service and OpenSearch instance.




## Steps

1. ## VPC Configuration
Create a VPC named ecs-fluentbit with the following structure:
NAT Gateway: ecs-fluentbit
Subnets:
Public:
ecs-fluentbit-public-subnet-1
ecs-fluentbit-public-subnet-2
ecs-fluentbit-public-subnet-3
Private:
ecs-fluentbit-private-subnet-1
ecs-fluentbit-private-subnet-2
ecs-fluentbit-private-subnet-3
Database:
ecs-fluentbit-private-subnet-4
ecs-fluentbit-private-subnet-5
ecs-fluentbit-private-subnet-6

## Route Tables:

Public Route Table: ecs-fluentbit-public-routetable with an Internet Gateway (IGW)
Private Route Table: ecs-fluentbit-private-rt with a NAT Gateway


2. ## OpenSearch Service Configuration
Deploy Amazon OpenSearch Service in the same VPC within private subnets. Ensure it has a security group allowing traffic from the ECS tasks.


3. ## ECS Configuration
Use CloudFormation to deploy an ECS cluster with the necessary resources. Include the following files in the GitHub repository for the configuration:

# Parsers.conf


[PARSER]
    Name   nginx
    Format regex
    Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")? \"-\"$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z


# Imagedefinitions.json

[{"name":"sample-app","imageUri":"785975698029.dkr.ecr.ap-south-1.amazonaws.com/ecs-package-repository"}]

# fluent-bit.conf

[SERVICE]
    Parsers_File parsers.conf
    Log_Level    debug
    Daemon       off
    http_listen  0.0.0.0
    HTTP_Server  On
    HTTP_Listen  0.0.0.0
    HTTP_Port    80

[INPUT]
    Name         tail
    Path         /var/log/secure
    Path_Key     filename


    Refresh_Interval 5
    Tag          system_logs

[FILTER]
    Name parser
    Match **
    Parser nginx
    Key_Name log

[OUTPUT]
    Name  opensearch
    Match *
    Host  vpc-ecs-fluentbit-h6oh7moqra3nsi5yc4fhljh2bq.ap-south-1.es.amazonaws.com
    Port  443
    Index my_index
    AWS_Auth On
    AWS_Region ap-south-1
    tls     On
    Suppress_Type_Name On

[OUTPUT]
    Name                         s3
    Match                        *
    bucket                       aws-cloud-formation-test
    region                       ap-south-1
    total_file_size              250M
    s3_key_format                /$TAG[2]/$TAG[0]/%Y/%m/%d/%H/%M/%S/$UUID.gz
    s3_key_format_tag_delimiters .-


# Dockerfile:-


FROM amazon/aws-for-fluent-bit:latest

#Add your Fluent Bit configuration files
ADD fluent-bit.conf /fluent-bit/etc/
ADD parsers.conf /fluent-bit/etc/

#Expose ports (optional based on your application's requirements)
EXPOSE 2020
EXPOSE 80

#Define volumes for logs and other data
VOLUME /var/log

#Set the command to run when the container starts
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]


## buildspec.yml :-



version: 0.2
run-as: root

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin xxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com
      - REPOSITORY_URI=xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com/ecs-package-repository
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...          
      - docker build -t ecs-package-repository:latest -f dockerfile .
      - docker tag ecs-package-repository:latest xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com/ecs-package-repository:latest      
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image to ECR...
      - docker push 785975698029.dkr.ecr.ap-south-1.amazonaws.com/ecs-package-repository:latest
artifacts:
    files: 
      - imagedefinitions.json
      - appspec.yml


appspec.yml


version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "sample-app"
          ContainerPort: 2020


4. ## Deployment
Use AWS CodePipeline to automate the build and deployment process. The pipeline will:
Fetch the source code from GitHub
Build the Docker image using CodeBuild
Push the image to Amazon ECR
Update the ECS service with the new image

5. ## Logging
Fluent Bit will be configured to:
Parse logs from /var/log/secure using the nginx parser defined in parsers.conf
Forward logs to Amazon OpenSearch Service for real-time analysis
Backup logs to Amazon S3 for long-term storage

## Steps For Reference
https://docs.google.com/document/d/1xjxrPVFen4tlL1yWHJOVaIkuYBzSxTKqnM4KY-DqLoY/edit?usp=drive_link











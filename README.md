# AWS Hands-On Labs

Practical, beginner-friendly AWS projects. Every lab was **actually built and tested in a real AWS account**, with console screenshots, CLI commands, and Infrastructure-as-Code, followed by a verified cleanup.

> Region used: `ap-southeast-2` (Sydney). All resources are prefixed `lab-` and tagged `Project=aws-hands-on-labs`.

## How to use this repo

Each lab folder follows the same layout. Start at Track 0 and work down.

```
NN-lab-name/
├── README.md        # step-by-step guide (console + CLI)
├── architecture.md  # diagram
├── screenshots/     # numbered console screenshots
├── iac/             # Terraform / CloudFormation
├── src/             # code, if any
└── cleanup.md       # delete everything, avoid charges
```

Start from [`_template/`](_template/README.md) to add a lab.

## Labs

| # | Track | Lab | Services | Level | Status |
|---|---|---|---|---|---|
| 01 | Foundations | Secure a new account (MFA, budget alarm) | IAM, Budgets | Beginner | Planned |
| 02 | Foundations | IAM users, groups, roles, least-privilege | IAM | Beginner | Planned |
| 03 | Foundations | AWS CLI setup | CLI, STS | Beginner | Planned |
| 04 | Storage | [S3 static website](04-s3-static-website/README.md) | S3 | Beginner | Done |
| 05 | Storage | [S3 versioning and lifecycle rules](05-s3-versioning-lifecycle/README.md) | S3 | Beginner | Done |
| 06 | Storage | CloudFront in front of S3 | CloudFront, S3 | Beginner | Planned |
| 07 | Compute | EC2 web server | EC2 | Beginner | Planned |
| 08 | Compute | ALB + Auto Scaling | ELB, ASG | Intermediate | Planned |
| 09 | Compute | [Lambda function](09-lambda-function/README.md) | Lambda, IAM | Beginner | Done |
| 10 | Compute | [Lambda + API Gateway REST API](10-lambda-api-gateway/README.md) | Lambda, API Gateway | Beginner | Done |
| 11 | Compute | Container on ECS Fargate | ECS, ECR | Intermediate | Planned |
| 12 | Networking | Custom VPC | VPC | Intermediate | Planned |
| 13 | Networking | Security groups vs NACLs | VPC | Intermediate | Planned |
| 14 | Networking | Route 53 custom domain | Route 53 | Intermediate | Planned |
| 15 | Databases | RDS in a private subnet | RDS | Intermediate | Planned |
| 16 | Databases | [DynamoDB CRUD with Python](16-dynamodb-crud/README.md) | DynamoDB | Beginner | Done |
| 17 | Serverless | S3 upload → Lambda → DynamoDB | S3, Lambda, DynamoDB | Intermediate | Planned |
| 18 | Serverless | SQS + SNS fan-out | SQS, SNS | Beginner | Planned |
| 19 | Serverless | Scheduled job | EventBridge, Lambda | Beginner | Planned |
| 20 | Serverless | Step Functions workflow | Step Functions | Intermediate | Planned |
| 21 | Security | KMS encryption | KMS | Intermediate | Planned |
| 22 | Security | Secrets Manager with Lambda | Secrets Manager | Intermediate | Planned |
| 23 | Security | WAF | WAF | Intermediate | Planned |
| 24 | Security | GuardDuty + CloudTrail | GuardDuty, CloudTrail | Intermediate | Planned |
| 25 | Monitoring | CloudWatch dashboards and alarms | CloudWatch | Beginner | Planned |
| 26 | Monitoring | Logs Insights queries | CloudWatch Logs | Intermediate | Planned |
| 27 | IaC / CI-CD | CloudFormation stack | CloudFormation | Intermediate | Planned |
| 28 | IaC / CI-CD | Terraform VPC + EC2 | Terraform | Intermediate | Planned |
| 29 | IaC / CI-CD | GitHub Actions → AWS via OIDC | IAM, GitHub Actions | Intermediate | Planned |
| 30 | IaC / CI-CD | CodePipeline | CodePipeline | Intermediate | Planned |
| 31 | AI | Bedrock chatbot | Bedrock | Intermediate | Planned |
| 32 | Capstone | Three-tier app | Many | Advanced | Planned |

## Ground rules

- No secrets, keys, or account IDs committed. Screenshots are redacted.
- Every lab ends with a cleanup that was run and verified.
- Cost for each lab is stated at the top of its README.

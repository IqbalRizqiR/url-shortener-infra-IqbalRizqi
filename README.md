[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/QHozoMSj)
# LKS URL Shortener - Infra

Terraform IaC for the LKS URL Shortener. Provisions all AWS infrastructure — VPC, ECS Fargate services, RDS, DynamoDB, SQS, ALB, ECR, SSM parameters, and CloudWatch log groups — in a single `terraform apply`.

---

## Tech Stack

lks-url-infra uses a number of technologies to work properly:

- [Terraform](https://www.terraform.io) - infrastructure as code tool for cloud provisioning
- [AWS Provider for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest) - HashiCorp AWS provider (~> 5.0)
- [Amazon ECS Fargate](https://aws.amazon.com/ecs/) - serverless container execution for all three services
- [Amazon RDS (PostgreSQL 17)](https://aws.amazon.com/rds/) - managed relational database
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) - managed NoSQL cache layer
- [Amazon SQS](https://aws.amazon.com/sqs/) - managed message queue for async click event processing
- [Amazon ALB](https://aws.amazon.com/elasticloadbalancing/) - application load balancer with priority-based path routing
- [Amazon ECR](https://aws.amazon.com/ecr/) - container image registry for all three service images
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/parameter-store/) - secure runtime configuration injected into ECS task definitions

---

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with a valid session
- Active AWS Academy lab session (credentials expire — re-export before each apply)
- S3 bucket `lks-url-tfstate-<city-yourname>` (e.g. `lks-url-tfstate-bandung-fajri`) must exist in `us-east-1` before running `terraform init`

### Setup

```bash
# Copy the example tfvars and fill in required values
cp terraform.tfvars.example terraform.tfvars

# Initialize Terraform (downloads providers, configures S3 backend)
terraform init

# Preview changes
terraform plan

# Provision infrastructure
terraform apply
```

> [!IMPORTANT]
> After the first `terraform apply`, you must update the `/lks-url/base-url` SSM parameter
> with the ALB DNS name. Until this is done, `POST /api/shorten` will return incorrect
> `short_url` values.

---

## Variables

| Variable         | Required | Default        | Description                                              |
| ---------------- | -------- | -------------- | -------------------------------------------------------- |
| `aws_account_id` | Yes      | —              | AWS account ID                                           |
| `db_password`    | Yes      | —              | RDS master password (sensitive)                          |
| `aws_region`     | No       | `us-east-1`    | AWS region to deploy into                                |
| `db_username`    | No       | `urlshortener` | RDS master username                                      |

---

## Outputs

| Output              | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| `alb_dns`           | ALB DNS name — needed for the post-deploy base-url SSM update |
| `ecr_api_url`       | ECR repository URL for shortener-api                          |
| `ecr_analytics_url` | ECR repository URL for analytics-svc                          |
| `ecr_frontend_url`  | ECR repository URL for frontend                               |
| `sqs_url`           | SQS click events queue URL                                    |
| `rds_endpoint`      | RDS PostgreSQL endpoint (sensitive — redacted in plan output) |

---

## Post-Deploy Steps

After the first `terraform apply`, retrieve the ALB DNS output and write it to the SSM parameter used by shortener-api. Then force a redeployment of `lks-url-api-svc` so it picks up the new value.

---

## References

- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon ECS — task definition reference](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
- [Amazon RDS — PostgreSQL guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Amazon DynamoDB — developer guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- [Amazon SQS — developer guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/)
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [GitHub Actions — `hashicorp/setup-terraform`](https://github.com/hashicorp/setup-terraform)
- [Amazon ECS — update-service CLI reference](https://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html)

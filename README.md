# Highly Available AWS 3-Tier Application with Terraform, Ansible & Jenkins

## Project Overview

This project demonstrates the design, provisioning, configuration, deployment, monitoring, and automatic scaling of a **3-tier web application on AWS** using Infrastructure as Code and DevOps automation.

The goal was not only to deploy an application, but to build an environment that reflects real DevOps responsibilities:

- Provision AWS infrastructure with Terraform.
- Configure Linux servers with Ansible.
- Deploy frontend and backend services.
- Use Jenkins for initial configuration and scale-out automation.
- Automatically configure new EC2 instances created by Auto Scaling Groups.
- Use EventBridge and Lambda to trigger Jenkins pipelines from AWS lifecycle events.
- Monitor infrastructure with CloudWatch and send alerts through SNS.
- Keep frontend, backend, and database tiers separated using public/private networking and security groups.
- Validate application availability and health after configuration.

---

## Architecture

```text
Users
  |
Route 53
  |
ACM Certificate
  |
Public Application Load Balancer
HTTPS :443
  |
Frontend Auto Scaling Group
Nginx :80
  |
  | /api/*
  v
Internal Application Load Balancer
HTTP :80
  |
Backend Auto Scaling Group
Node.js :3000
  |
Amazon RDS PostgreSQL :5432
```

Administration and automation path:

```text
Engineer
  |
  +--> Bastion Host --> Private Frontend / Backend EC2
  |
  +--> Jenkins EC2
          |
          +--> SSH directly to private EC2 instances
          +--> Run Ansible
          +--> Use AWS CLI through EC2 IAM Role
```

Scale-out automation:

```text
High CPU
  |
CloudWatch / Target Tracking
  |
Auto Scaling Group launches EC2
  |
Lifecycle Hook
  |
Pending:Wait
  |
EventBridge
  |
Lambda
  |
Jenkins Pipeline
  |
Ansible configures only the new instance
  |
Health validation
  |
CompleteLifecycleAction CONTINUE
  |
InService
```

---

## AWS Infrastructure

The environment is deployed in `eu-north-1`.

### VPC

```text
VPC CIDR: 10.0.0.0/16
```

Two Availability Zones are used.

### Public Subnets

```text
10.0.1.0/24
10.0.2.0/24
```

Used for:

- Internet-facing ALB
- NAT Gateway
- Bastion host
- Jenkins server

### Private Application Subnets

```text
10.0.11.0/24
10.0.12.0/24
```

Used for:

- Frontend Auto Scaling Group
- Backend Auto Scaling Group
- Internal backend ALB

### Private Database Subnets

```text
10.0.21.0/24
10.0.22.0/24
```

Used for:

- Amazon RDS PostgreSQL

The database is not publicly accessible.

---

## Main AWS Services

- Amazon EC2
- Auto Scaling Groups
- Application Load Balancer
- Amazon RDS PostgreSQL
- Amazon VPC
- NAT Gateway
- Internet Gateway
- Route 53
- AWS Certificate Manager
- IAM
- CloudWatch
- SNS
- EventBridge
- Lambda

---

## Security Design

Traffic is restricted using Security Group references where possible.

```text
Internet
  |
  | 80 / 443
  v
Public ALB SG
  |
  | 80
  v
Frontend SG
  |
  | 80
  v
Internal ALB SG
  |
  | 3000
  v
Backend SG
  |
  | 5432
  v
Database SG
```

Administrative SSH access:

```text
Administrator IP
  |
  | 22
  v
Bastion
  |
  | 22
  +--> Frontend
  +--> Backend
```

Jenkins connects directly to private instances over the VPC:

```text
Jenkins SG
  |
  | 22
  +--> Frontend
  +--> Backend
```

Lambda reaches Jenkins internally:

```text
Lifecycle Lambda SG
  |
  | 8080
  v
Jenkins SG
```

---

## Terraform

Terraform is used to provision the AWS infrastructure.

Repository structure:

```text
terraform/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── locals.tf
│       └── terraform.tfvars
└── modules/
    ├── networking/
    ├── security/
    ├── compute/
    ├── alb/
    ├── backend-alb/
    ├── autoscaling/
    ├── monitoring/
    ├── database/
    ├── jenkins/
    ├── backend-automation/
    └── frontend-automation/
```

The project uses reusable Terraform modules to separate responsibilities and make the code easier to maintain.

Examples of Terraform-managed resources:

- VPC
- Subnets
- Route tables
- Internet Gateway
- NAT Gateway
- Security Groups
- EC2 instances
- Launch Templates
- Auto Scaling Groups
- Target Tracking Policies
- Public and internal ALBs
- RDS
- Route 53
- ACM
- IAM roles and instance profiles
- CloudWatch alarms
- SNS
- EventBridge
- Lambda
- Auto Scaling lifecycle hooks

---

## Ansible

Ansible is used for server configuration and application deployment.

Structure:

```text
ansible/
├── ansible.cfg
├── site.yml
├── inventory/
│   └── aws_ec2.yml
├── group_vars/
│   ├── all.yml
│   ├── role_frontend/
│   ├── role_backend/
│   └── role_jenkins/
└── roles/
    ├── frontend/
    ├── backend/
    └── jenkins/
```

### Dynamic AWS Inventory

The `amazon.aws.aws_ec2` inventory plugin discovers EC2 instances dynamically using AWS tags.

Example groups:

```text
role_frontend
role_backend
role_jenkins
```

This avoids maintaining static IP addresses in inventory files.

### Backend Role

The backend Ansible role:

- Waits for cloud-init.
- Waits for APT/dpkg locks.
- Updates APT cache.
- Installs Node.js and npm.
- Deploys the Node.js Todo API.
- Installs npm dependencies.
- Creates a systemd service.
- Configures database connection variables.
- Starts and enables the service.
- Waits for port `3000`.
- Validates `/health`.

### Frontend Role

The frontend Ansible role:

- Waits for cloud-init.
- Waits for APT/dpkg locks.
- Installs Nginx.
- Deploys frontend files.
- Configures Nginx.
- Configures `/api/` reverse proxy to the internal backend ALB.
- Starts and enables Nginx.

### Why Wait for cloud-init and APT Locks?

Fresh Ubuntu EC2 instances may still be initializing when Jenkins starts Ansible.

`cloud-init` may be running package operations during first boot.

To prevent errors such as:

```text
Could not get lock /var/lib/dpkg/lock-frontend
```

the Ansible roles wait for initialization to finish before installing packages.

Example:

```yaml
- name: Wait for cloud-init to finish
  ansible.builtin.command: cloud-init status --wait
  changed_when: false
  become: true
```

APT lock check:

```yaml
- name: Wait for apt lock
  ansible.builtin.shell: |
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
      sleep 5
    done
  changed_when: false
  become: true
```

This makes the automation more reliable during rapid Auto Scaling events.

---

## Jenkins Automation

Pipeline definitions are stored in Git.

```text
jenkins/
├── Jenkinsfile.initial
├── Jenkinsfile.backend-asg
└── Jenkinsfile.frontend-asg
```

Jenkins jobs use:

```text
Pipeline script from SCM
```

This keeps the pipeline code version-controlled instead of storing it only in the Jenkins UI.

### Pipeline 1 — Initial Infrastructure Configuration

Job:

```text
initial-infra-config
```

Purpose:

- Configure all backend EC2 instances.
- Configure all frontend EC2 instances.
- Retrieve the current backend internal ALB DNS dynamically.
- Pass runtime values into Ansible.
- Validate backend health.
- Validate frontend Nginx.
- Validate reverse proxy communication.
- Validate the public application.

### Pipeline 2 — Backend ASG Configuration

Job:

```text
backend-asg-configure
```

Triggered automatically when the backend ASG launches a new instance.

Flow:

```text
Lifecycle Event
  |
EventBridge
  |
Lambda
  |
Jenkins receives INSTANCE_ID
  |
Resolve private IP
  |
Run backend Ansible role
  |
Verify systemd service
  |
Verify /health
  |
CompleteLifecycleAction CONTINUE
```

### Pipeline 3 — Frontend ASG Configuration

Job:

```text
frontend-asg-configure
```

Triggered automatically when the frontend ASG launches a new instance.

The pipeline:

- Receives the exact EC2 `INSTANCE_ID`.
- Resolves its private IP.
- Retrieves the current internal backend ALB DNS using AWS CLI.
- Configures only the new frontend instance.
- Validates Nginx.
- Completes the lifecycle action.

---

## Auto Scaling Automation

Both frontend and backend Auto Scaling Groups use CPU target tracking.

A lifecycle hook pauses newly created EC2 instances:

```text
Pending:Wait
```

This gives Jenkins and Ansible time to configure the server before it receives production traffic.

After successful validation Jenkins runs:

```bash
aws autoscaling complete-lifecycle-action \
  --lifecycle-action-result CONTINUE
```

The instance then continues toward:

```text
InService
```

### Health Check Grace Period

The ASGs use a health check grace period so newly initialized instances are not prematurely terminated while services are starting.

The lifecycle hook and health check grace period solve different problems:

```text
Lifecycle Hook
= pause the launch process while configuration runs

Health Check Grace Period
= prevent ASG from reacting too early to temporary health check failures
```

---

## Monitoring and Alerting

CloudWatch alarms monitor:

- Frontend CPU
- Backend CPU
- ALB unhealthy targets
- ALB 5xx errors
- Backend response time
- RDS CPU
- RDS free memory
- RDS free storage
- RDS connections
- RDS read latency
- RDS write latency

Alerts are sent using:

```text
CloudWatch
   |
SNS
   |
Email
```

Auto Scaling uses target tracking independently from the custom notification alarms.

---

## Application

The backend exposes:

```text
GET    /health
GET    /api/todos
POST   /api/todos
PUT    /api/todos/:id
DELETE /api/todos/:id
```

Example validation:

Create:

```bash
curl -X POST https://app.devopstest.click/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"DevOps project test"}'
```

Read:

```bash
curl https://app.devopstest.click/api/todos
```

Delete:

```bash
curl -X DELETE https://app.devopstest.click/api/todos/<ID>
```

This validates the complete path:

```text
Client
→ Route 53
→ Public ALB
→ Nginx
→ Internal ALB
→ Node.js
→ PostgreSQL
```

---

# Prerequisites

## Local Machine

Recommended environment:

- Linux / Ubuntu
- Git
- Terraform
- AWS CLI
- Ansible
- Python 3
- SSH client

Verify:

```bash
terraform version
aws --version
ansible --version
python3 --version
git --version
```

## Terraform Provider Authentication

The current local development setup expects an AWS CLI profile named:

```text
terraform
```

Configure it:

```bash
aws configure --profile terraform
```

Verify:

```bash
aws sts get-caller-identity --profile terraform
```

Do not commit AWS credentials.

## Terraform Variables

Create:

```text
terraform/environments/dev/terraform.tfvars
```

with the required project-specific values.

This file is intentionally excluded from Git.

Do not commit:

```text
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
private SSH keys
Jenkins API tokens
Ansible Vault passwords
```

## SSH Key

An SSH key pair must exist for EC2 administration.

Example:

```bash
ssh-keygen -t ed25519
```

The public key is used by Terraform for the EC2 key pair.

The private key must remain local and secret.

## Ansible AWS Dependencies

Install:

```bash
pip install boto3 botocore
```

Install the AWS collection:

```bash
ansible-galaxy collection install amazon.aws
```

If the backend role uses the npm module:

```bash
ansible-galaxy collection install community.general
```

## Jenkins Credentials

After Jenkins is created, configure these credentials:

### EC2 SSH Key

```text
ID: backend-ssh-key
Type: SSH Username with private key
Username: ubuntu
```

Used for both frontend and backend instances.

### Ansible Vault Password

```text
ID: ansible-vault-password
Type: Secret text
```

### Jenkins API Token

Generate an API token for the Jenkins user.

The token is used by lifecycle Lambda functions to trigger Jenkins jobs.

Do not commit the token.

---

# Deployment Workflow

## 1. Provision Infrastructure

```bash
cd terraform/environments/dev

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## 2. Configure Jenkins

The Jenkins EC2 is configured using the Jenkins Ansible role.

Required tools include:

- Java
- Jenkins
- Git
- AWS CLI
- Terraform
- Ansible
- boto3 / botocore
- SSH client
- required Ansible collections

## 3. Create Jenkins Jobs

Create these exact job names:

```text
initial-infra-config
backend-asg-configure
frontend-asg-configure
```

The backend/frontend names are important because Lambda calls them by name.

Configure:

```text
Definition: Pipeline script from SCM
SCM: Git
Branch: */main
```

Script paths:

```text
initial-infra-config
→ jenkins/Jenkinsfile.initial

backend-asg-configure
→ jenkins/Jenkinsfile.backend-asg

frontend-asg-configure
→ jenkins/Jenkinsfile.frontend-asg
```

Run the parameterized ASG jobs once after creating them so Jenkins registers the `INSTANCE_ID` pipeline parameter.

## 4. Run Initial Configuration

Run:

```text
initial-infra-config
```

The pipeline configures all current frontend/backend instances.

## 5. Validate Application

```bash
curl https://app.devopstest.click/
curl https://app.devopstest.click/api/todos
```

## 6. Test Auto Scaling

Generate CPU load on both instances of the tier being tested.

Example:

```bash
sudo apt install -y stress-ng

stress-ng \
  --cpu 0 \
  --cpu-load 100 \
  --timeout 10m
```

Expected flow:

```text
CPU rises
→ target tracking triggers scale-out
→ EC2 launches
→ Pending:Wait
→ EventBridge
→ Lambda
→ Jenkins
→ Ansible
→ health validation
→ CONTINUE
→ InService
```

---

# Repository Safety

Recommended `.gitignore` entries:

```gitignore
terraform/environments/dev/.terraform/
terraform/environments/dev/*.tfstate
terraform/environments/dev/*.tfstate.*
terraform/environments/dev/terraform.tfvars
terraform/environments/dev/*.auto.tfvars
terraform/environments/dev/*.tfplan
terraform/environments/dev/tfplan

terraform/modules/backend-automation/lambda/*.zip
terraform/modules/frontend-automation/lambda/*.zip

*.pem
*.key

.env
.env.*

.vscode/
.idea/
```

Keep `.terraform.lock.hcl` tracked.

---

# Challenges Solved During the Project

This project included troubleshooting and solving several real operational issues:

- Terraform module dependency and output wiring.
- Security Group rule ownership and Terraform state imports.
- Jenkins plugin vs installed-tool behavior.
- Jenkins SSH Agent credential handling.
- Dynamic Ansible AWS inventory.
- Bastion `ProxyJump` differences between laptop and Jenkins execution.
- Jenkins direct VPC SSH access.
- Ansible Vault handling in pipelines.
- APT/dpkg lock race conditions on newly launched Ubuntu instances.
- cloud-init synchronization.
- RDS PostgreSQL SSL requirements.
- RDS authentication troubleshooting.
- Internal ALB DNS changes after recreation.
- Auto Scaling lifecycle hooks.
- EventBridge event filtering.
- Lambda-to-Jenkins authentication.
- Jenkins parameter registration after SCM job recreation.
- CloudWatch target tracking behavior.
- ALB/ASG health-check timing.
- Rolling backend configuration with `serial: 1`.

---

# Skills Demonstrated

This project demonstrates hands-on experience with:

### AWS

- VPC design
- Public/private subnetting
- Routing
- NAT Gateway / Internet Gateway
- Security Groups
- EC2
- IAM
- Auto Scaling
- ALB
- RDS
- Route 53
- ACM
- CloudWatch
- SNS
- EventBridge
- Lambda

### Terraform

- Modular infrastructure
- Variables and outputs
- Resource dependencies
- State management
- Importing existing resources
- Provider configuration
- Lifecycle automation
- IAM provisioning
- Infrastructure validation

### Ansible

- Roles
- Dynamic inventory
- `group_vars`
- Ansible Vault
- Handlers
- Templates
- systemd
- package management
- runtime variable overrides
- SSH ProxyJump
- idempotent configuration
- health validation

### Jenkins

- Declarative Pipelines
- Pipeline-as-Code
- Pipeline script from SCM
- Jenkins credentials
- SSH Agent plugin
- environment variables
- build parameters
- post actions
- AWS CLI integration
- Ansible integration
- automated infrastructure events

### Linux

- SSH
- systemd
- package management
- cloud-init
- APT/dpkg locking
- networking
- process/service validation
- Nginx

### Operational / DevOps Concepts

- Infrastructure as Code
- Configuration Management
- High Availability
- Auto Scaling
- Health Checks
- Rolling Configuration
- Separation of initial deployment and scale-out configuration
- Monitoring and alerting
- Least-privilege network access
- CI/CD and event-driven automation
- Troubleshooting across infrastructure, networking, OS, application, and automation layers

---

# What I Learned

Building this project gave me practical experience beyond simply creating AWS resources.

I worked through the full lifecycle of an environment:

```text
Design
→ Provision
→ Configure
→ Deploy
→ Validate
→ Monitor
→ Scale
→ Troubleshoot
→ Automate
```

A key part of the project was understanding how multiple DevOps tools work together rather than treating them as isolated technologies:

```text
Terraform
creates infrastructure

Ansible
configures operating systems and applications

Jenkins
orchestrates configuration and deployment workflows

EventBridge + Lambda
connect AWS infrastructure events to Jenkins

CloudWatch + SNS
provide visibility and alerting

Auto Scaling
adjusts infrastructure capacity
```

The project also required troubleshooting real integration problems between AWS, Terraform, Jenkins, Ansible, Linux, Nginx, Node.js, and PostgreSQL.

---

## Future Improvements

Possible next improvements:

- Re-enable Terraform remote state with S3 locking.
- Store Jenkins API tokens in AWS Secrets Manager.
- Use Jenkins Configuration as Code for automatic Jenkins bootstrap.
- Automatically create Jenkins jobs after Jenkins recreation.
- Add Multi-AZ RDS for production HA.
- Add NAT Gateway per AZ for production resilience.
- Add automated testing stages.
- Add centralized logs.
- Add stronger secret rotation.
- Add blue/green or canary deployment strategies.
- Add containerization and Kubernetes as a future evolution of the project.

---

## Author

**Ibrahim Gamal Ibrahim**

Applications Operations Engineer with hands-on DevOps experience in Linux, AWS, Terraform, Ansible, Jenkins, Docker, Kubernetes, Git, Helm, automation, and production operations.

# EscolaTech Project — AWS Cloud Architecture

Hands-on AWS cloud architecture project developed as part of the AWS re/Start program in partnership with Escola da Nuvem.

This project presents a cloud-based solution for **Escola Tech**, a fictional online education platform that needed to improve availability, scalability, security, performance, monitoring, and cost efficiency.

The solution was designed by the **Hórus Tech** team to replace a traditional on-premises environment with a modern AWS architecture capable of supporting daily traffic and high-demand periods such as enrollment campaigns, exams, and grade releases.

---

## Project Overview

Escola Tech was facing issues with an on-premises infrastructure, including:

- Limited scalability during traffic peaks;
- Lack of elasticity;
- Risk of downtime during critical academic periods;
- No automated infrastructure provisioning;
- Limited monitoring and operational visibility;
- High maintenance costs related to physical infrastructure.

To solve these challenges, our team designed and implemented an AWS-based architecture using infrastructure as code, load balancing, auto scaling, monitoring, and security best practices.

---

## Business Challenge

The main business challenge was to keep the platform available and responsive during high-traffic periods.

In a traditional on-premises model, the platform could become unavailable when user demand increased suddenly. This could affect students, teachers, and administrative staff during important moments such as course enrollment, exams, and grade publication.

The proposed cloud architecture was designed to improve reliability, scalability, performance, and cost efficiency.

---

## Proposed Solution

The solution uses AWS services to provide a scalable, resilient, secure, and cost-optimized environment.

The core architecture includes:

- A custom Amazon VPC;
- Public subnets across multiple Availability Zones;
- Amazon EC2 instances running the web application;
- Application Load Balancer to distribute traffic;
- Auto Scaling Group to automatically adjust capacity based on demand;
- Security Groups to control network access;
- Amazon CloudWatch for monitoring;
- Terraform for infrastructure provisioning.

---

## Architecture Highlights

### High Availability

The architecture was designed across multiple Availability Zones to reduce the risk of downtime. If one Availability Zone becomes unavailable, the application can continue running through resources deployed in another zone.

### Scalability and Elasticity

The Auto Scaling Group automatically increases or decreases the number of EC2 instances based on demand. This allows the platform to handle traffic peaks while avoiding unnecessary costs during periods of low usage.

### Load Balancing

The Application Load Balancer distributes incoming traffic across healthy EC2 instances, improving availability and user experience.

### Security

Security Groups were used to control inbound and outbound traffic. The architecture follows the principle of allowing only the required access to each resource.

### Monitoring

Amazon CloudWatch was used to monitor infrastructure behavior, including CPU utilization and scaling activity. This helped validate the elasticity of the environment during stress testing.

### Cost Optimization

The solution supports a pay-as-you-go model and uses Auto Scaling to optimize resource usage. Instead of maintaining fixed infrastructure capacity, the environment can scale according to real demand.

---

## My Role

I worked as a **Developer** on the Hórus Tech team, contributing to the implementation, testing, validation, documentation, and presentation of the proposed AWS solution.

---

## My Contributions

My main contributions included:

- Supporting the implementation of AWS infrastructure using Terraform;
- Contributing to the deployment and validation of the web application on Amazon EC2;
- Helping configure and test the Application Load Balancer;
- Supporting the validation of the EC2 Auto Scaling Group;
- Simulating traffic to demonstrate elasticity and automatic scaling behavior;
- Monitoring infrastructure behavior with Amazon CloudWatch;
- Supporting the technical documentation of the architecture;
- Contributing to the final project presentation;
- Explaining the technical and business benefits of the proposed solution;
- Collaborating with the team to align the architecture with AWS Well-Architected Framework principles.

This project helped me strengthen my hands-on experience with AWS, infrastructure as code, high availability, scalability, monitoring, and FinOps.

---

## Technologies and AWS Services Used

| Category | Tools and Services |
|---|---|
| Cloud Provider | AWS |
| Infrastructure as Code | Terraform |
| Compute | Amazon EC2 |
| Load Balancing | Application Load Balancer |
| Scalability | Auto Scaling Group |
| Networking | Amazon VPC, Subnets, Route Tables, Internet Gateway |
| Security | Security Groups |
| Monitoring | Amazon CloudWatch |
| Operating System | Amazon Linux |
| Web Server | Apache HTTP Server |
| Scripting | Shell Script |
| Version Control | Git and GitHub |

---

## Stress Test
[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/_FkLPHZ-SAw/0.jpg)](https://www.youtube.com/watch?v=_FkLPHZ-SAw)

---

## Repository Structure

```bash
.
├── README.md
├── main.tf
├── userdata.sh
└── .gitignore


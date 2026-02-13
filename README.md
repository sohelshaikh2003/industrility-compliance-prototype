# SOC 2 Automated Compliance Prototype

This repository demonstrates a lightweight, automated compliance engine designed to monitor AWS infrastructure against **SOC 2 Trust Services Criteria** (specifically CC6.1 - Access Choice and Control). 

Instead of manual audits, this prototype leverages **Compliance-as-Code** to detect, surface, and archive evidence of security configurations automatically.

## 🏗 Architecture Overview
- **Infrastructure:** Provisioned via **Terraform** in the `ap-south-1` (Mumbai) region.
- **Automation:** **GitHub Actions** handles both infrastructure deployment and scheduled compliance scanning.
- **Evidence Collection:** A custom **Python/Boto3** script "interrogates" the AWS API to verify security states and generates audit-ready JSON artifacts.


## 🛡 SOC 2 Controls Implemented
| Control ID | Trust Service Criteria | Implementation |
| :--- | :--- | :--- |
| **CC6.1** | Access Choice/Control | Automated check for S3 Public Access Block configurations and IAM MFA status. |
| **CC6.7** | Data Protection | Managed via Terraform to ensure traceable infrastructure changes and S3 encryption. |
| **CC7.2** | Monitoring & Logging | Integration with CloudTrail to ensure audit logs are active and validated. |

## 🚀 How it Works
1. **Provisioning:** Terraform deploys the environment (including S3 buckets and IAM policies).
2. **The Audit:** The `compliance-audit.yml` workflow triggers the Python collector script.
3. **The Evidence:** The script queries the AWS API (using **STS** for identity verification), validates the state against SOC 2 requirements, and generates a `soc2_evidence.json` file.
4. **Archiving:** Issues are surfaced in GitHub Actions logs, and the JSON report is saved as a permanent audit record.

## 🛠 Tech Stack
* **IaC:** Terraform
* **Cloud:** AWS (S3, IAM, CloudTrail, STS)
* **CI/CD:** GitHub Actions
* **Language:** Python 3.x (Boto3 SDK)

## 💡 Engineering Trade-offs & Future Roadmap
* **Orchestration:** Used GitHub Actions for high visibility and portability. **Next step:** Integrate AWS Config for real-time, event-driven remediation.
* **Storage:** Evidence is currently stored as GitHub Action Artifacts. **Next step:** Move to a versioned, WORM (Write Once Read Many) S3 bucket with Object Lock for tamper-proof storage.
* **Identity:** MFA checking is currently limited to standard IAM users. **Next step:** Implement an organization-level audit for Root and Federated identities.

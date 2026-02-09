# SOC 2 Automated Compliance Prototype

This repository demonstrates a lightweight, automated compliance engine designed to monitor AWS infrastructure against SOC 2 Trust Services Criteria (specifically CC6.1 - Access Choice and Control). 

Instead of manual audits, this prototype uses **Compliance-as-Code** to detect, surface, and archive evidence of security configurations.

## 🏗 Architecture Overview
- **Infrastructure:** Provisioned via Terraform in the `ap-south-1` (Mumbai) region.
- **Automation:** GitHub Actions handles both infrastructure deployment and scheduled compliance scanning.
- **Evidence Collection:** A custom Python/Boto3 script "interrogates" the AWS API to verify bucket security states and generates audit-ready JSON artifacts.

## 🛡 SOC 2 Controls Implemented
| Control ID | Description | Implementation |
| :--- | :--- | :--- |
| **CC6.1** | Access Choice/Control | Automated check for S3 Public Access Block configurations. |
| **CC6.7** | Lifecycle Management | Managed via Terraform to ensure traceable infrastructure changes. |

## 🚀 How it Works
1. **The "Bait":** The Terraform code deliberately creates one compliant bucket and one non-compliant (public) bucket.
2. **The Audit:** The `compliance-audit.yml` workflow triggers the Python collector.
3. **The Result:** Issues are surfaced in the GitHub Actions logs, and a `compliance_report.json` is generated as a permanent audit record.

## 🛠 Tech Stack
* **IaC:** Terraform
* **Cloud:** AWS (S3, IAM)
* **CI/CD:** GitHub Actions
* **Language:** Python (Boto3)

## 💡 Engineering Trade-offs
* **GitHub Actions vs. AWS Config:** For this prototype, I used GitHub Actions for better visibility and portability. In a production environment, I would integrate AWS Config Rules for real-time, event-driven remediation.
* **Storage:** Evidence is currently stored as GitHub Action Artifacts. For a full SOC 2 audit, these would be moved to a versioned, WORM (Write Once Read Many) S3 bucket.

---
*Created by Sohel Shaikh as part of the Technical Assessment.*

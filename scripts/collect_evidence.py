import json
import boto3
from datetime import datetime

# AWS clients
ec2 = boto3.client("ec2")
cloudtrail = boto3.client("cloudtrail")

# Evidence object (audit artifact)
evidence = {
    "timestamp": datetime.utcnow().isoformat(),
    "controls": {}
}

# ==============================
# SOC 2 CONTROL: Logging Enabled
# ==============================

trails_response = cloudtrail.describe_trails()
trails = trails_response.get("trailList", [])

# Store evidence
evidence["controls"]["cloudtrail_enabled"] = len(trails) > 0

# 🚨 CONTROL ENFORCEMENT (THIS IS THE IMPORTANT PART)
# If CloudTrail is missing → FAIL THE COMPLIANCE CHECK
if len(trails) == 0:
    raise Exception("SOC2 FAIL: CloudTrail logging not enabled")

# ==============================
# SOC 2 CONTROL: Region Visibility
# ==============================

regions = ec2.describe_regions()["Regions"]
evidence["controls"]["region_count"] = len(regions)

# ==============================
# Save Evidence File
# ==============================

with open("evidence/soc2_evidence.json", "w") as f:
    json.dump(evidence, f, indent=2)

print("✅ SOC 2 evidence collected successfully")

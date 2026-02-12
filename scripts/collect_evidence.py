import json
import boto3
import os
from datetime import datetime

# AWS clients
ec2 = boto3.client("ec2")
cloudtrail = boto3.client("cloudtrail")
s3 = boto3.client("s3")

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

evidence["controls"]["cloudtrail_enabled"] = len(trails) > 0

if len(trails) == 0:
    raise Exception("SOC2 FAIL: CloudTrail logging not enabled")

# ==========================================
# NEW: SOC 2 CONTROL: S3 Bucket Security
# ==========================================
# Pehle trail se bucket ka naam apne aap nikaalein
target_bucket = trails[0].get("S3BucketName")
evidence["controls"]["target_bucket"] = target_bucket

try:
    # Check if encryption is on
    s3.get_bucket_encryption(Bucket=target_bucket)
    evidence["controls"]["s3_encryption_enabled"] = True
except:
    evidence["controls"]["s3_encryption_enabled"] = False

# ==============================
# SOC 2 CONTROL: Region Visibility
# ==============================
regions = ec2.describe_regions()["Regions"]
evidence["controls"]["region_count"] = len(regions)

# ==============================
# Save Evidence File
# ==============================
os.makedirs("evidence", exist_ok=True) 
with open("evidence/soc2_evidence.json", "w") as f:
    json.dump(evidence, f, indent=2)

print(f"✅ SOC 2 evidence collected successfully for bucket: {target_bucket}")
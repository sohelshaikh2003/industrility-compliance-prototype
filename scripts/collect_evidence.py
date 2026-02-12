import boto3
import json
import os
from datetime import datetime

def collect_evidence():
    s3 = boto3.client('s3')
    trail_client = boto3.client('cloudtrail')
    
    # Bucket name dynamically fetch karne ke liye (ya hardcode karein jo aapke paas hai)
    # Aapka bucket: soc2-evidence-87238948
    bucket_name = "soc2-evidence-87238948" 
    
    evidence = {
        "timestamp": datetime.now().isoformat(),
        "account_info": boto3.client('sts').get_caller_identity()['Account'],
        "controls": {}
    }

    # 1. CloudTrail Check
    trails = trail_client.describe_trails(trailNameList=['soc2-audit-trail'])
    if trails['trailList']:
        trail = trails['trailList'][0]
        evidence["controls"]["cloudtrail"] = {
            "status": "ACTIVE",
            "multi_region": trail.get('IsMultiRegionTrail', False),
            "log_file_validation": trail.get('LogFileValidationEnabled', False),
            "kms_encrypted": "KmsKeyId" in trail
        }

    # 2. S3 Bucket Security (SOC 2 Production Standards)
    try:
        # Encryption Check
        enc = s3.get_bucket_encryption(Bucket=bucket_name)
        encryption = enc['ServerSideEncryptionConfiguration']['Rules'][0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
    except:
        encryption = "NOT_ENABLED"

    try:
        # Public Access Block Check
        pab = s3.get_public_access_block(Bucket=bucket_name)
        is_private = pab['PublicAccessBlockConfiguration']['BlockPublicAcls']
    except:
        is_private = False

    evidence["controls"]["s3_storage"] = {
        "bucket_name": bucket_name,
        "encryption_algorithm": encryption,
        "public_access_blocked": is_private,
        "versioning_status": s3.get_bucket_versioning(Bucket=bucket_name).get('Status', 'Disabled')
    }

    # JSON File Save karein
    os.makedirs('evidence', exist_ok=True)
    with open('evidence/soc2_evidence.json', 'w') as f:
        json.dump(evidence, f, indent=4)
    print("Production evidence captured successfully!")

if __name__ == "__main__":
    collect_evidence()
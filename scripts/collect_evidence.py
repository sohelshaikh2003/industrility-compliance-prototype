import boto3
import json
import os
from datetime import datetime

def run_s3_audit():
    print("--- Starting SOC 2 Audit ---")
    s3 = boto3.client('s3', region_name="ap-south-1")
    all_buckets = s3.list_buckets()['Buckets']
    audit_results = []
    
    for bucket in all_buckets:
        name = bucket['Name']
        if "industrility" in name:
            try:
                response = s3.get_public_access_block(Bucket=name)
                config = response['PublicAccessBlockConfiguration']
                is_secure = all([config['BlockPublicAcls'], config['BlockPublicPolicy']])
                status = "PASS" if is_secure else "FAIL"
            except:
                status = "FAIL"
            
            audit_results.append({
                "timestamp": datetime.now().isoformat(),
                "resource": name,
                "control": "SOC2-CC6.1",
                "result": status
            })

    os.makedirs('evidence', exist_ok=True)
    with open('evidence/compliance_report.json', 'w') as f:
        json.dump(audit_results, f, indent=4)
    print("Audit finished. Evidence saved.")

if __name__ == "__main__":
    run_s3_audit()
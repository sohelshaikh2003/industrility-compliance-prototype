import boto3
import json
import os
from datetime import datetime

# Configuration
REGION = "ap-south-1"
PROJECT_PREFIX = "industrility"

def run_s3_audit():
    print(f"--- Starting SOC 2 Audit for {PROJECT_PREFIX} resources ---")
    
    s3 = boto3.client('s3', region_name=REGION)
    all_buckets = s3.list_buckets()['Buckets']
    
    audit_results = []
    
    for bucket in all_buckets:
        name = bucket['Name']
        
        # We only care about buckets created for this project
        if PROJECT_PREFIX in name:
            print(f"Checking bucket: {name}")
            
            try:
                # SOC 2 Control: Access Choice (CC6.1)
                response = s3.get_public_access_block(Bucket=name)
                config = response['PublicAccessBlockConfiguration']
                
                # A PASS requires all blocks to be True
                is_secure = all([
                    config['BlockPublicAcls'],
                    config['BlockPublicPolicy'],
                    config['IgnorePublicAcls'],
                    config['RestrictPublicBuckets']
                ])
                status = "PASS" if is_secure else "FAIL"
                
            except Exception as e:
                # If no block exists, it's a security failure
                status = "FAIL"
            
            audit_results.append({
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "resource_id": name,
                "control": "SOC2-CC6.1",
                "result": status
            })

    # Ensure the evidence directory exists
    os.makedirs('evidence', exist_ok=True)
    
    # Save the 'evidence' as an audit-ready JSON file
    with open('evidence/compliance_report.json', 'w') as f:
        json.dump(audit_results, f, indent=4)
        
    print(f"Audit finished. Results saved to evidence/compliance_report.json")

if __name__ == "__main__":
    run_s3_audit()
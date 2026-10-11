import json
import sys

CRITICAL_RESOURCES = {
    "aws_db_instance",
    "aws_rds_cluster",
    "aws_s3_bucket"
}

RISK_PRIORITY = {
    "LOW": 0,
    "REVIEW": 1,
    "BLOCK": 2
}

with open(sys.argv[1]) as f:
    plan = json.load(f)

overall_risk = "LOW"
findings = []

for resource in plan.get("resource_changes", []):
    actions = resource["change"]["actions"]
    resource_type = resource["type"]
    address = resource["address"]

    if "delete" not in actions:
        continue

    if resource_type in CRITICAL_RESOURCES:
        risk = "BLOCK"
        reason = "Critical resource deletion or replacement"
    else:
        risk = "REVIEW"
        reason = "Resource deletion or replacement"

    findings.append({
        "resource": address,
        "risk": risk,
        "reason": reason
    })

    if RISK_PRIORITY[risk] > RISK_PRIORITY[overall_risk]:
        overall_risk = risk

report = {
    "overall_risk": overall_risk,
    "findings": findings
}

print(json.dumps(report, indent=2))
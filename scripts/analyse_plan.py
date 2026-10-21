import json
import sys

CRITICAL_RESOURCES = {
    "aws_db_instance",
    "aws_rds_cluster",
    "aws_s3_bucket"
}

STATEFUL_RESOURCES = {
    "aws_db_instance",
    "aws_rds_cluster",
    "aws_s3_bucket",
    "aws_dynamodb_table",
    "aws_efs_file_system",
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

    actions = resource.get("change", {}).get("actions", [])

    if (
            resource.get("type") in STATEFUL_RESOURCES
            and "delete" in actions
    ):
        findings.append({
            "resource": resource["address"],
            "risk": "BLOCK",
            "reason": (
                "Destructive change to a stateful "
                "production resource"
            ),
        })
    # Detect public SSH access
    if resource_type == "aws_vpc_security_group_ingress_rule":
        after = resource["change"].get("after") or {}

        if (
                "create" in actions or "update" in actions
        ) and (
                after.get("cidr_ipv4") == "0.0.0.0/0"
                and after.get("ip_protocol") == "tcp"
                and after.get("from_port", 0) <= 22 <= after.get("to_port", 0)
        ):
            findings.append({
                "resource": address,
                "risk": "BLOCK",
                "reason": "SSH exposed to the internet"
            })
            overall_risk = "BLOCK"

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
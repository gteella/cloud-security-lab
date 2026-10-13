package main

import rego.v1

public_internet(rule) if {
    rule.cidr_ipv4 == "0.0.0.0/0"
}

public_internet(rule) if {
    rule.cidr_ipv6 == "::/0"
}

deny contains msg if {
    some rc in input.resource_changes

    rc.type == "aws_vpc_security_group_ingress_rule"

    rule := rc.change.after

    rule.from_port <= 22
    rule.to_port >= 22

    public_internet(rule)

    msg := sprintf("Public SSH access prohibited: %s", [rc.address])
}

deny contains msg if {
    some rc in input.resource_changes

    rc.type == "aws_vpc_security_group_ingress_rule"

    rule := rc.change.after

    rule.ip_protocol == "tcp"
    rule.from_port <= 5432
    rule.to_port >= 5432

    public_internet(rule)

    msg := sprintf(
        "Public PostgreSQL access prohibited: %s",
        [rc.address]
    )
}



deny contains msg if {
    some rc in input.resource_changes

    rc.type == "aws_vpc_security_group_ingress_rule"

    rule := rc.change.after

    rule.ip_protocol == "-1"
    public_internet(rule)

    msg := sprintf(
        "All protocols publicly exposed: %s",
        [rc.address]
    )
}

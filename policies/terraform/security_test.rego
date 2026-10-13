package main

import rego.v1

test_public_ssh_is_denied if {
    violations := deny with input as {
        "resource_changes": [{
            "address": "aws_vpc_security_group_ingress_rule.ssh",
            "type": "aws_vpc_security_group_ingress_rule",
            "change": {
                "after": {
                    "ip_protocol": "tcp",
                    "from_port": 22,
                    "to_port": 22,
                    "cidr_ipv4": "0.0.0.0/0"
                }
            }
        }]
    }

    count(violations) == 1
}

test_private_ssh_is_allowed if {
    violations := deny with input as {
        "resource_changes": [{
            "address": "aws_vpc_security_group_ingress_rule.ssh",
            "type": "aws_vpc_security_group_ingress_rule",
            "change": {
                "after": {
                    "ip_protocol": "tcp",
                    "from_port": 22,
                    "to_port": 22,
                    "cidr_ipv4": "10.0.0.0/8"
                }
            }
        }]
    }

    count(violations) == 0
}

test_public_ipv6_ssh_is_denied if {
    violations := deny with input as {
        "resource_changes": [{
            "address": "aws_vpc_security_group_ingress_rule.ssh_ipv6",
            "type": "aws_vpc_security_group_ingress_rule",
            "change": {
                "after": {
                    "ip_protocol": "tcp",
                    "from_port": 22,
                    "to_port": 22,
                    "cidr_ipv6": "::/0"
                }
            }
        }]
    }

    count(violations) == 1
}

test_public_all_protocols_is_denied if {
    violations := deny with input as {
        "resource_changes": [{
            "address": "aws_vpc_security_group_ingress_rule.all",
            "type": "aws_vpc_security_group_ingress_rule",
            "change": {
                "after": {
                    "ip_protocol": "-1",
                    "cidr_ipv4": "0.0.0.0/0"
                }
            }
        }]
    }

    count(violations) == 1
}
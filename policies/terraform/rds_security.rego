
package terraform.rds

import rego.v1

deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_db_instance"

    after := rc.change.after
    before := rc.change.before

    before.backup_retention_period > 0
    after.backup_retention_period == 0

    msg := sprintf(
        "RDS automated backups disabled: %s",
        [rc.address]
    )
}

deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_db_instance"

    rc.change.before.deletion_protection == true
    rc.change.after.deletion_protection == false

    msg := sprintf(
        "RDS deletion protection disabled: %s",
        [rc.address]
    )
}

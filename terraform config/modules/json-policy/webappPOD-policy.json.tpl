{
    "Version": "2012-10-17",
    "Statement": [
        
        {
            "Sid": "AllowRDSDBConnectWithIAMDBAUTHENTICATION",
             "Effect": "Allow",
             "Action": "rds-db:connect",
             "Resource": [
               "arn:aws:rds-db:${region}:${account_id}:dbuser:${db_resource_id}/admin",
               "arn:aws:rds-db:${region}:${account_id}:dbuser:${db_resource_id}/app_user"
             ]
        },
        {
            "Sid": "secretsManagerAccess",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "${db_admin_secretARN}"
        }
    ]
}

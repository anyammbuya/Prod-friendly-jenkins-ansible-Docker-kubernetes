{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "sessionManagerServiceAccess",
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3BucketLevelAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3ObjectWriteAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                
                "arn:aws:s3:::zeus-ec2ssm-logsbu/ssmlogs/*"
            ]
        },
        {
            "Sid": "KmsDecryptAccess",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "arn:aws:kms:${region}:${account_id}:key/${kms_key_id}"
        },
        {
            "Sid": "KmsGenerateDataKeyAccess",
            "Effect": "Allow",
            "Action": [
                "kms:GenerateDataKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMListAndRead",
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "iam:ListPolicies",
                "iam:ListAttachedRolePolicies",
                "iam:GetOpenIDConnectProvider",
                "iam:CreateOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:GetRole",
                "iam:TagRole",
                "iam:PassRole",
                "iam:DetachRolePolicy",
                "iam:DeletePolicy",
                "iam:DeleteRole",
                "iam:CreatePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ServiceLinkedRoleCreationOnly",
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "eks.amazonaws.com",
                        "eks-fargate-pods.amazonaws.com",
                        "eks-nodegroup.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Sid": "EKSAllRequiredForEksctl",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        },
       
        {
          "Sid": "GetAWSAccountID",
           "Effect": "Allow",
           "Action": "sts:GetCallerIdentity",
           "Resource": "*"
        },
        {
          "Sid": "GetVpcAndSubnetIDs",
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets"
          ],
          "Resource": "*",
          "Condition": {
            "StringEquals": {
              "ec2:Region": "us-west-2"
            }
          }
       }
 
  ]
}

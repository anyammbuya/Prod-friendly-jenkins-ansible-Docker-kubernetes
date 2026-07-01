CREATE USER IF NOT EXISTS 'app_user' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';

GRANT SELECT, INSERT, UPDATE, DELETE ON zeus_project_db.users TO 'app_user';
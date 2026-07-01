package com.example.webapp;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {

    private static final String DB_ENDPOINT =
            "zeus-db.cxsee6smsxz1.us-west-2.rds.amazonaws.com";

    private static final String DB_PORT = "3306";

    private static final String AWS_REGION = "us-west-2";

    public static Connection getConnection(
            String dbUser,
            String dbName
    ) throws SQLException {

        try {

            Class.forName("software.amazon.jdbc.Driver");

            String url =
                    "jdbc:aws-wrapper:mysql://"
                    + DB_ENDPOINT
                    + ":"
                    + DB_PORT
                    + "/"
                    + dbName
                    + "?wrapperPlugins=iam"
                    + "&iamRegion="
                    + AWS_REGION;

            Connection connection =
                    DriverManager.getConnection(
                            url,
                            dbUser,
                            null
                    );

            System.out.println(
                    "IAM database authentication successful for user: "
                    + dbUser
            );

            return connection;

        } catch (ClassNotFoundException e) {

            throw new SQLException(
                    "AWS JDBC wrapper driver not found",
                    e
            );
        }
    }
}
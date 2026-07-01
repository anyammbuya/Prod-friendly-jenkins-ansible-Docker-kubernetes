package com.example.webapp;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;

import org.flywaydb.core.Flyway;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;

public class FlywayInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {

        try {
            String secretName = "db-admin-password"; // Ensure this matches your AWS Secret ID exactly
            String region = "us-west-2";

            System.out.println("Flyway initializing: Fetching DB credentials from Secrets Manager...");

            // -------- FETCH PASSWORD FROM SECRETS MANAGER -------
            // This utilizes DefaultCredentialsProvider, which natively looks for your webapp-service-account token
            SecretsManagerClient client = SecretsManagerClient.builder()
                    .credentialsProvider(DefaultCredentialsProvider.create())
                    .region(Region.of(region))
                    .build();

            String password = client.getSecretValue(
                    GetSecretValueRequest.builder()
                            .secretId(secretName)
                            .build()
            ).secretString();

            // -------- DB CONNECTION INFO -------------
            String username = "admin";
            String host = "zeus-db.cxsee6smsxz1.us-west-2.rds.amazonaws.com";
            String port = "3306";

            // CRITICAL CORRECTION: Use the 'jdbc:mysql:aws://' protocol to engage the AWS wrapper driver
            String url = "jdbc:mysql://" + host + ":" + port +
                    "/zeus_project_db?useSSL=true&requireSSL=true";

            System.out.println("Flyway executing migration against host: " + host);

            // -------- FLYWAY CONFIGURATION --------
            Flyway flyway = Flyway.configure()
                    .dataSource(url, username, password)
                    .locations("classpath:db/migration")
                    .load();

            flyway.migrate();

            System.out.println("Flyway migration completed successfully! Tables and app_user are ready.");

        } catch (Exception e) {

            System.err.println("CRITICAL ERROR: Flyway migration failed.");
        
            Throwable t = e;
            while (t != null) {
                System.err.println("CAUSE: " + t.getClass().getName());
                System.err.println("MESSAGE: " + t.getMessage());
                t = t.getCause();
            }
        
            e.printStackTrace();
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // Context cleanup logic if required
    }
}
package com.example.webapp;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

import org.mindrot.jbcrypt.BCrypt;

public class LoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");

        try (Connection con = DBUtil.getConnection("app_user", "zeus_project_db")) {

            String sql = "SELECT first_name, password FROM users WHERE username=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, username);

            ResultSet rs = ps.executeQuery();

            System.out.println("Attempting login for: " + username);
			
            if (rs.next()) {
				
				// Use System.out.println for debugging. Check the logs in /opt/tomcat/logs/catalina.out
				// on tomcat server. In production get rid of the logs

                String storedHash = rs.getString("password");
				
				System.out.println("Stored Hash: " + storedHash);
                System.out.println("Hash Length: " + storedHash.length());
				
				boolean isMatch = BCrypt.checkpw(password, storedHash);
                System.out.println("Password Match: " + isMatch);
				
				if (isMatch) {

                // 🔐 VERIFY PASSWORD
                if (BCrypt.checkpw(password, storedHash)) {

                    String firstName = rs.getString("first_name");

                    req.setAttribute("name", firstName);
                    req.getRequestDispatcher("welcome.jsp").forward(req, res);

                } 
				}else {
                    System.out.println("User not found in database.");
					res.sendRedirect("login.jsp?error=1");
                }

            } else {
                res.sendRedirect("login.jsp?error=1");
            }

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("login.jsp?error=1");
        }
    }
}
package com.example.webapp;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

import org.mindrot.jbcrypt.BCrypt;

public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String firstName = req.getParameter("firstname");
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        // 🔐 HASH PASSWORD
        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

        try (Connection con = DBUtil.getConnection("app_user", "zeus_project_db")) {

            String sql = "INSERT INTO users(first_name, username, password) VALUES (?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, firstName);
            ps.setString(2, username);
            ps.setString(3, hashedPassword);

            ps.executeUpdate();

            res.sendRedirect("login.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("register.jsp?error=1");
        }
    }
}
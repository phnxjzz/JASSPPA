package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Logger;

public class LoginServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(LoginServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("user_id") != null) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
        } else {
            request.setAttribute("selected_role", normalizeRole(request.getParameter("role")));
            if (request.getParameter("registered") != null) {
                request.setAttribute("success", "Akaun berjaya didaftarkan. Sila log masuk.");
            }
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String selectedRole = normalizeRole(request.getParameter("portal_role"));

        if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
            request.setAttribute("error", "Username dan kata laluan diperlukan.");
            request.setAttribute("selected_role", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        if (selectedRole == null) {
            request.setAttribute("error", "Sila pilih peranan portal sebelum log masuk.");
            request.setAttribute("selected_role", "");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            String sql = "SELECT id, username, role, status FROM users WHERE username = ? AND password_hash = SHA2(?, 256)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, username);
                stmt.setString(2, password);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        String status = rs.getString("status");
                        if (!"ACTIVE".equals(status)) {
                            request.setAttribute("error", "Akaun anda telah digantung atau tidak aktif.");
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        String userRole = rs.getString("role");
                        if (!selectedRole.equals(userRole)) {
                            request.setAttribute("error", "Akaun ini tidak sepadan dengan portal yang dipilih.");
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        HttpSession session = request.getSession();
                        session.setAttribute("user_id", rs.getInt("id"));
                        session.setAttribute("username", rs.getString("username"));
                        session.setAttribute("role", userRole);

                        LOGGER.info("User logged in: " + username);
                        if ("ADMIN".equals(userRole)) {
                            response.sendRedirect(request.getContextPath() + "/admin/application");
                        } else {
                            response.sendRedirect(request.getContextPath() + "/dashboard");
                        }
                    } else {
                        request.setAttribute("error", "Username atau kata laluan tidak sah.");
                        request.setAttribute("selected_role", selectedRole);
                        request.getRequestDispatcher("/login.jsp").forward(request, response);
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            request.setAttribute("error", "Ralat pangkalan data. Sila cuba lagi.");
            request.setAttribute("selected_role", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    private String normalizeRole(String value) {
        if (value == null) {
            return null;
        }
        String role = value.trim().toUpperCase();
        if ("ADMIN".equals(role) || "USER".equals(role)) {
            return role;
        }
        return null;
    }
}

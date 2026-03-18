package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Logger;

public class ForgotPasswordServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ForgotPasswordServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/forgot-password.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String username = trim(request.getParameter("username"));
        String email = trim(request.getParameter("email"));
        String newPassword = trim(request.getParameter("new_password"));
        String confirmPassword = trim(request.getParameter("confirm_password"));

        request.setAttribute("username", username);
        request.setAttribute("email", email);

        if (isBlank(username) || isBlank(email) || isBlank(newPassword) || isBlank(confirmPassword)) {
            request.setAttribute("error", "Sila lengkapkan semua medan.");
            request.getRequestDispatcher("/forgot-password.jsp").forward(request, response);
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "Pengesahan kata laluan tidak sepadan.");
            request.getRequestDispatcher("/forgot-password.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            if (!userExists(conn, username, email)) {
                request.setAttribute("error", "Maklumat akaun tidak padan. Sila semak nama pengguna dan email.");
                request.getRequestDispatcher("/forgot-password.jsp").forward(request, response);
                return;
            }

            updatePassword(conn, username, email, newPassword);
            response.sendRedirect(request.getContextPath() + "/login?reset=1");
        } catch (SQLException e) {
            LOGGER.severe("Failed to reset password: " + e.getMessage());
            request.setAttribute("error", "Ralat sistem semasa set semula kata laluan.");
            request.getRequestDispatcher("/forgot-password.jsp").forward(request, response);
        }
    }

    private boolean userExists(Connection conn, String username, String email) throws SQLException {
        String sql = "SELECT 1 FROM users WHERE username = ? AND email = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, username);
            stmt.setString(2, email);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void updatePassword(Connection conn, String username, String email, String newPassword) throws SQLException {
        String sql = "UPDATE users SET password_hash = SHA2(?, 256) WHERE username = ? AND email = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, newPassword);
            stmt.setString(2, username);
            stmt.setString(3, email);
            stmt.executeUpdate();
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }
}

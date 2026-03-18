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

public class ProfileServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ProfileServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            populateProfile(request, (Integer) session.getAttribute("user_id"), conn);
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load profile: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to load profile");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        int userId = (Integer) session.getAttribute("user_id");
        String fullName = trim(request.getParameter("full_name"));
        String username = trim(request.getParameter("username"));
        String email = trim(request.getParameter("email"));
        String avatarUrl = trim(request.getParameter("avatar_url"));
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");

        if (isBlank(fullName) || isBlank(username) || isBlank(email)) {
            request.setAttribute("error", "Nama penuh, nama pengguna dan email wajib diisi.");
            request.setAttribute("full_name", fullName);
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.setAttribute("avatar_url", avatarUrl);
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
            return;
        }

        if (!isBlank(password) && !password.equals(confirmPassword)) {
            request.setAttribute("error", "Pengesahan kata laluan tidak sepadan.");
            request.setAttribute("full_name", fullName);
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.setAttribute("avatar_url", avatarUrl);
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            if (existsDuplicateUser(conn, userId, username, email)) {
                request.setAttribute("error", "Nama pengguna atau email sudah digunakan.");
                request.setAttribute("full_name", fullName);
                request.setAttribute("username", username);
                request.setAttribute("email", email);
                request.setAttribute("avatar_url", avatarUrl);
                request.getRequestDispatcher("/profile.jsp").forward(request, response);
                return;
            }

            updateProfile(conn, userId, fullName, username, email, avatarUrl, password);
            session.setAttribute("username", username);
            response.sendRedirect(request.getContextPath() + "/profile?updated=1");
        } catch (SQLException e) {
            LOGGER.severe("Failed to update profile: " + e.getMessage());
            request.setAttribute("error", "Kemaskini profil gagal disimpan.");
            request.setAttribute("full_name", fullName);
            request.setAttribute("username", username);
            request.setAttribute("email", email);
            request.setAttribute("avatar_url", avatarUrl);
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
        }
    }

    private void populateProfile(HttpServletRequest request, int userId, Connection conn) throws SQLException {
        String sql = "SELECT full_name, username, email, avatar_url, status, created_at "
                + "FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    request.setAttribute("full_name", rs.getString("full_name"));
                    request.setAttribute("username", rs.getString("username"));
                    request.setAttribute("email", rs.getString("email"));
                    request.setAttribute("avatar_url", rs.getString("avatar_url"));
                    request.setAttribute("status", rs.getString("status"));
                    request.setAttribute("created_at", rs.getTimestamp("created_at"));
                }
            }
        }
    }

    private boolean existsDuplicateUser(Connection conn, int userId, String username, String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE (username = ? OR email = ?) AND id <> ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, username);
            stmt.setString(2, email);
            stmt.setInt(3, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private void updateProfile(Connection conn, int userId, String fullName, String username, String email,
                               String avatarUrl, String password) throws SQLException {
        boolean hasPassword = !isBlank(password);
        String sql = hasPassword
                ? "UPDATE users SET full_name = ?, username = ?, email = ?, avatar_url = ?, password_hash = SHA2(?, 256) WHERE id = ?"
                : "UPDATE users SET full_name = ?, username = ?, email = ?, avatar_url = ? WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, fullName);
            stmt.setString(2, username);
            stmt.setString(3, email);
            stmt.setString(4, isBlank(avatarUrl) ? null : avatarUrl);
            if (hasPassword) {
                stmt.setString(5, password);
                stmt.setInt(6, userId);
            } else {
                stmt.setInt(5, userId);
            }
            stmt.executeUpdate();
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import org.mindrot.jbcrypt.BCrypt;

public class AdminUserServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminUserServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) return;

        String search = request.getParameter("search");
        if (search != null) search = search.trim();

        List<Map<String, Object>> users = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection()) {
            String sql = "SELECT id, username, email, full_name, role, status, created_at " +
                         "FROM users " +
                         (search != null && !search.isEmpty()
                             ? "WHERE username LIKE ? OR email LIKE ? OR full_name LIKE ? "
                             : "") +
                         "ORDER BY created_at DESC";

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (search != null && !search.isEmpty()) {
                    String like = "%" + search + "%";
                    ps.setString(1, like);
                    ps.setString(2, like);
                    ps.setString(3, like);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new HashMap<>();
                        row.put("id", rs.getInt("id"));
                        row.put("username", rs.getString("username"));
                        row.put("email", rs.getString("email"));
                        row.put("full_name", rs.getString("full_name"));
                        row.put("role", rs.getString("role"));
                        row.put("status", rs.getString("status"));
                        row.put("created_at", rs.getTimestamp("created_at"));
                        users.add(row);
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to load users list: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan senarai pengguna");
            return;
        }

        request.setAttribute("users", users);
        request.setAttribute("search", search);
        request.getRequestDispatcher("/admin-users.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) return;

        String action = request.getParameter("action");
        String userIdParam = request.getParameter("userId");

        if (action == null || userIdParam == null || userIdParam.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Permintaan tidak sah");
            return;
        }

        int targetUserId;
        try {
            targetUserId = Integer.parseInt(userIdParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID pengguna tidak sah");
            return;
        }

        HttpSession session = request.getSession(false);
        Object sessionUserId = session != null ? session.getAttribute("userId") : null;
        int currentAdminId = sessionUserId != null ? Integer.parseInt(sessionUserId.toString()) : -1;

        switch (action) {
            case "delete":
                handleDelete(request, response, targetUserId, currentAdminId);
                break;
            case "toggle_status":
                handleToggleStatus(request, response, targetUserId, currentAdminId);
                break;
            case "reset_password":
                handleResetPassword(request, response, targetUserId, currentAdminId);
                break;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Tindakan tidak dikenali");
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        if (currentAdminId == targetUserId) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=cannot_delete_self");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            try (PreparedStatement checkAdmin = conn.prepareStatement(
                    "SELECT COUNT(*) FROM users WHERE role = 'ADMIN'");
                 ResultSet rs = checkAdmin.executeQuery()) {
                rs.next();
                int adminCount = rs.getInt(1);

                String targetRole = null;
                try (PreparedStatement getRole = conn.prepareStatement(
                        "SELECT role FROM users WHERE id = ?")) {
                    getRole.setInt(1, targetUserId);
                    try (ResultSet rsRole = getRole.executeQuery()) {
                        if (rsRole.next()) targetRole = rsRole.getString("role");
                    }
                }

                if ("ADMIN".equals(targetRole) && adminCount <= 1) {
                    response.sendRedirect(request.getContextPath() + "/admin/users?error=last_admin");
                    return;
                }
            }

            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM users WHERE id = ?")) {
                ps.setInt(1, targetUserId);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to delete user: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?deleted=1");
    }

    private void handleToggleStatus(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        if (currentAdminId == targetUserId) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=cannot_suspend_self");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            // Prevent suspending the last active ADMIN
            String currentStatus = null;
            String currentRole = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT status, role FROM users WHERE id = ?")) {
                ps.setInt(1, targetUserId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentStatus = rs.getString("status");
                        currentRole = rs.getString("role");
                    }
                }
            }

            if ("ADMIN".equals(currentRole) && "ACTIVE".equals(currentStatus)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM users WHERE role = 'ADMIN' AND status = 'ACTIVE'");
                     ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) <= 1) {
                        response.sendRedirect(request.getContextPath() + "/admin/users?error=last_active_admin");
                        return;
                    }
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE users SET status = CASE WHEN status = 'ACTIVE' THEN 'SUSPENDED' ELSE 'ACTIVE' END WHERE id = ?")) {
                ps.setInt(1, targetUserId);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to toggle user status: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?toggled=1");
    }

    private void handleResetPassword(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        String tempPassword = generateTempPassword();
        String hashed = BCrypt.hashpw(tempPassword, BCrypt.gensalt());

        try (Connection conn = DatabaseConfig.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE users SET password_hash = ? WHERE id = ?")) {
                ps.setString(1, hashed);
                ps.setInt(2, targetUserId);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to reset password: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?reset=1&tempPw=" +
                java.net.URLEncoder.encode(tempPassword, "UTF-8"));
    }

    private String generateTempPassword() {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#";
        SecureRandom rng = new SecureRandom();
        StringBuilder sb = new StringBuilder(10);
        for (int i = 0; i < 10; i++) {
            sb.append(chars.charAt(rng.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        return true;
    }
}

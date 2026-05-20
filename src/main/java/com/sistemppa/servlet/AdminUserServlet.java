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
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import org.mindrot.jbcrypt.BCrypt;
import com.sistemppa.util.ValidationUtil;

public class AdminUserServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminUserServlet.class.getName());
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{8,20}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) return;

        String search = request.getParameter("search");
        if (search != null) search = search.trim();

        List<Map<String, Object>> users = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);

            String sql = "SELECT id, username, email, phone_number, full_name, role, status, created_at " +
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
                        row.put("phone_number", rs.getString("phone_number"));
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
        // Use 'user_id' (consistent with LoginServlet and all other servlets)
        Object sessionUserId = session != null ? session.getAttribute("user_id") : null;
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
            case "update_role":
                handleUpdateRole(request, response, targetUserId, currentAdminId);
                break;
            case "update_phone_number":
                handleUpdatePhoneNumber(request, response, targetUserId, currentAdminId);
                break;
            case "update_email":
                handleUpdateEmail(request, response, targetUserId, currentAdminId);
                break;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Tindakan tidak dikenali");
        }
    }

    private void handleUpdateEmail(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        String email = request.getParameter("email");
        String normalized = email == null ? "" : email.trim();

        if (normalized.isBlank() || !ValidationUtil.isValidEmail(normalized)) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=invalid_email");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            try (PreparedStatement check = conn.prepareStatement("SELECT id FROM users WHERE id = ?")) {
                check.setInt(1, targetUserId);
                try (ResultSet rs = check.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/admin/users?error=user_not_found");
                        return;
                    }
                }
            }

            try (PreparedStatement dup = conn.prepareStatement(
                    "SELECT COUNT(*) FROM users WHERE email = ? AND id <> ?")) {
                dup.setString(1, normalized);
                dup.setInt(2, targetUserId);
                try (ResultSet rs = dup.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        response.sendRedirect(request.getContextPath() + "/admin/users?error=email_exists");
                        return;
                    }
                }
            }

            try (PreparedStatement update = conn.prepareStatement(
                    "UPDATE users SET email = ? WHERE id = ?")) {
                update.setString(1, normalized);
                update.setInt(2, targetUserId);
                update.executeUpdate();
            }

            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_EMAIL",
                    "Admin #" + currentAdminId + " kemaskini e-mel pengguna #" + targetUserId,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to update user email: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?email_updated=1");
    }

    private void handleUpdatePhoneNumber(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        String phoneNumber = request.getParameter("phone_number");
        String normalized = phoneNumber == null ? "" : phoneNumber.trim();

        if (normalized.isBlank() || !PHONE_PATTERN.matcher(normalized).matches()) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=invalid_phone_number");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);

            try (PreparedStatement check = conn.prepareStatement("SELECT id FROM users WHERE id = ?")) {
                check.setInt(1, targetUserId);
                try (ResultSet rs = check.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/admin/users?error=user_not_found");
                        return;
                    }
                }
            }

            try (PreparedStatement update = conn.prepareStatement(
                    "UPDATE users SET phone_number = ? WHERE id = ?")) {
                update.setString(1, normalized);
                update.setInt(2, targetUserId);
                update.executeUpdate();
            }

            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_PHONE",
                    "Admin #" + currentAdminId + " kemaskini nombor telefon pengguna #" + targetUserId,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to update user phone number: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?phone_updated=1");
    }

    private void handleUpdateRole(HttpServletRequest request, HttpServletResponse response,
            int targetUserId, int currentAdminId) throws IOException {
        String roleParam = request.getParameter("role");
        if (roleParam == null || roleParam.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=invalid_role");
            return;
        }

        String newRole = roleParam.trim().toUpperCase(Locale.ROOT);
        if (!"ADMIN".equals(newRole) && !"USER".equals(newRole)) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=invalid_role");
            return;
        }

        if (targetUserId == currentAdminId) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=cannot_change_own_role");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            String existingRole = null;
            try (PreparedStatement getRole = conn.prepareStatement("SELECT role FROM users WHERE id = ?")) {
                getRole.setInt(1, targetUserId);
                try (ResultSet rs = getRole.executeQuery()) {
                    if (rs.next()) {
                        existingRole = rs.getString("role");
                    }
                }
            }

            if (existingRole == null) {
                response.sendRedirect(request.getContextPath() + "/admin/users?error=user_not_found");
                return;
            }

            if (newRole.equals(existingRole)) {
                response.sendRedirect(request.getContextPath() + "/admin/users?role_updated=1");
                return;
            }

            if ("ADMIN".equals(existingRole) && "USER".equals(newRole)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM users WHERE role = 'ADMIN'")) {
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        if (rs.getInt(1) <= 1) {
                            response.sendRedirect(request.getContextPath() + "/admin/users?error=last_admin");
                            return;
                        }
                    }
                }
            }

            try (PreparedStatement update = conn.prepareStatement("UPDATE users SET role = ? WHERE id = ?")) {
                update.setString(1, newRole);
                update.setInt(2, targetUserId);
                update.executeUpdate();
            }

            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_ROLE",
                    "Admin #" + currentAdminId + " tukar peranan pengguna #" + targetUserId
                            + " daripada " + existingRole + " kepada " + newRole,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to update user role: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?role_updated=1");
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
            insertAdminAuditLog(conn, currentAdminId, "DELETE_USER",
                    "Admin #" + currentAdminId + " memadam pengguna #" + targetUserId,
                    request.getRemoteAddr());
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
            insertAdminAuditLog(conn, currentAdminId, "TOGGLE_USER_STATUS",
                    "Admin #" + currentAdminId + " tukar status pengguna #" + targetUserId,
                    request.getRemoteAddr());
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
            insertAdminAuditLog(conn, currentAdminId, "RESET_PASSWORD",
                    "Admin #" + currentAdminId + " reset kata laluan pengguna #" + targetUserId,
                    request.getRemoteAddr());
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

    private void insertAdminAuditLog(Connection conn, int adminId, String action,
            String details, String ip) {
        try {
            String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, adminId);
                ps.setString(2, action);
                ps.setString(3, details);
                ps.setString(4, ip);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to write audit log: " + e.getMessage());
        }
    }

    private void ensureUsersPhoneNumberColumn(Connection conn) throws SQLException {
        DatabaseMetaData meta = conn.getMetaData();
        try (ResultSet rs = meta.getColumns(null, null, "users", "phone_number")) {
            if (rs.next()) {
                return;
            }
        }
        try (PreparedStatement stmt = conn.prepareStatement("ALTER TABLE users ADD COLUMN phone_number VARCHAR(30)")) {
            stmt.executeUpdate();
        }
    }
}

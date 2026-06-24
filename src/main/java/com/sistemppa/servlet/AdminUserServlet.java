package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import org.mindrot.jbcrypt.BCrypt;
import com.sistemppa.util.ValidationUtil;
<<<<<<< HEAD
import com.sistemppa.util.UserDisplayIdUtil;
=======
>>>>>>> origin/SPPPA

public class AdminUserServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminUserServlet.class.getName());
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{8,20}$");
<<<<<<< HEAD
    private static final Path KPP_CSV_PATH = Paths.get("P:/ProjectLI/data/Senarai KPP.csv");
=======
>>>>>>> origin/SPPPA

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) return;

        String search = request.getParameter("search");
        if (search != null) search = search.trim();

        List<Map<String, Object>> users = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);
<<<<<<< HEAD
            ensureUsersRoleSupportsStaff(conn);
            syncKppContactsFromCsv(conn);

            String sql = "SELECT id, username, email, phone_number, full_name, role, role_seq, status, created_at " +
=======

            String sql = "SELECT id, username, email, phone_number, full_name, role, status, created_at " +
>>>>>>> origin/SPPPA
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
                        row.put("display_id", UserDisplayIdUtil.format(
                            rs.getInt("id"),
                            rs.getString("role"),
                            rs.getObject("role_seq", Integer.class)));
                        row.put("status", rs.getString("status"));
                        row.put("created_at", rs.getTimestamp("created_at"));
                        users.add(row);
                    }
                }
            }

            request.setAttribute("admin_audit_logs",
                    DashboardDataService.loadRecentAdminAuditLogs(conn, 20));
            request.setAttribute("kpp_contacts", DashboardDataService.loadKppContacts(conn));
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
        if (action == null || action.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Permintaan tidak sah");
            return;
        }

        HttpSession session = request.getSession(false);
        Object sessionUserId = session != null ? session.getAttribute("user_id") : null;
        int currentAdminId = sessionUserId != null ? Integer.parseInt(sessionUserId.toString()) : -1;

        if ("add_kpp_contact".equals(action)) {
            handleAddKppContact(request, response, currentAdminId);
            return;
        }

        if ("delete_kpp_contact".equals(action)) {
            handleDeleteKppContact(request, response, currentAdminId);
            return;
        }

        String userIdParam = request.getParameter("userId");
        if (userIdParam == null || userIdParam.isBlank()) {
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

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersRoleSupportsStaff(conn);
        } catch (SQLException e) {
            LOGGER.severe("Failed to ensure users.role supports STAFF: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        switch (action) {
            case "delete":
                handleDelete(request, response, targetUserId, currentAdminId);
                break;
            case "toggle_status":
                handleToggleStatus(request, response, targetUserId, currentAdminId);
                break;
            case "set_status":
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

<<<<<<< HEAD
    private void handleAddKppContact(HttpServletRequest request, HttpServletResponse response,
            int currentAdminId) throws IOException {
        String name = request.getParameter("kpp_name");
        String branch = request.getParameter("kpp_branch");
        String email = request.getParameter("kpp_email");

        String normalizedName = name == null ? "" : name.trim();
        String normalizedBranch = branch == null ? "" : branch.trim();
        String normalizedEmail = email == null ? "" : email.trim();

        if (normalizedName.isBlank() || normalizedBranch.isBlank() || normalizedEmail.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=kpp_invalid");
            return;
        }

        if (!ValidationUtil.isValidEmail(normalizedEmail)) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=kpp_invalid_email");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.addKppContact(conn, normalizedName, normalizedBranch, normalizedEmail);
            appendKppContactToCsv(normalizedName, normalizedBranch, normalizedEmail);
                insertAdminAuditLog(conn, currentAdminId, "ADD KPP CONTACT",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                            + " tambah rekod KPP: " + normalizedName + " (" + normalizedBranch + ") - " + normalizedEmail,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to add KPP contact: " + e.getMessage());
            if (e.getMessage() != null && e.getMessage().toLowerCase(Locale.ROOT).contains("duplicate")) {
                response.sendRedirect(request.getContextPath() + "/admin/users?error=kpp_email_exists");
                return;
            }
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?kpp_added=1");
    }

    private void handleDeleteKppContact(HttpServletRequest request, HttpServletResponse response,
            int currentAdminId) throws IOException {
        String kppIdParam = request.getParameter("kpp_id");
        long kppId;
        try {
            kppId = Long.parseLong(kppIdParam);
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin/users?error=kpp_invalid");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            List<Map<String, Object>> contacts = DashboardDataService.loadKppContacts(conn);
            String deletedEmail = null;
            for (Map<String, Object> c : contacts) {
                String idValue = String.valueOf(c.get("id"));
                if (idValue != null && idValue.equals(String.valueOf(kppId))) {
                    deletedEmail = c.get("email") == null ? null : String.valueOf(c.get("email")).trim();
                    break;
                }
            }

            int deleted = DashboardDataService.deleteKppContact(conn, kppId);
            if (deleted <= 0) {
                response.sendRedirect(request.getContextPath() + "/admin/users?error=kpp_not_found");
                return;
            }
            if (deletedEmail != null && !deletedEmail.isBlank()) {
                removeKppContactFromCsv(deletedEmail);
            }
                insertAdminAuditLog(conn, currentAdminId, "DELETE KPP CONTACT",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                            + " padam rekod KPP ID " + kppId,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to delete KPP contact: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/users?error=db_error");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/admin/users?kpp_deleted=1");
    }

=======
>>>>>>> origin/SPPPA
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

<<<<<<< HEAD
            insertAdminAuditLog(conn, currentAdminId, "UPDATE USER EMAIL",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " kemaskini e-mel pengguna " + resolveDisplayUserId(conn, targetUserId),
=======
            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_EMAIL",
                    "Admin #" + currentAdminId + " kemaskini e-mel pengguna #" + targetUserId,
>>>>>>> origin/SPPPA
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

<<<<<<< HEAD
            insertAdminAuditLog(conn, currentAdminId, "UPDATE USER PHONE",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " kemaskini nombor telefon pengguna " + resolveDisplayUserId(conn, targetUserId),
=======
            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_PHONE",
                    "Admin #" + currentAdminId + " kemaskini nombor telefon pengguna #" + targetUserId,
>>>>>>> origin/SPPPA
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
<<<<<<< HEAD
        if (!"ADMIN".equals(newRole) && !"USER".equals(newRole) && !"STAFF".equals(newRole)) {
=======
        if (!"ADMIN".equals(newRole) && !"USER".equals(newRole)) {
>>>>>>> origin/SPPPA
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

<<<<<<< HEAD
            if ("ADMIN".equals(existingRole) && !"ADMIN".equals(newRole)) {
=======
            if ("ADMIN".equals(existingRole) && "USER".equals(newRole)) {
>>>>>>> origin/SPPPA
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

<<<<<<< HEAD
            insertAdminAuditLog(conn, currentAdminId, "UPDATE USER ROLE",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " tukar peranan pengguna " + resolveDisplayUserId(conn, targetUserId)
=======
            insertAdminAuditLog(conn, currentAdminId, "UPDATE_USER_ROLE",
                    "Admin #" + currentAdminId + " tukar peranan pengguna #" + targetUserId
>>>>>>> origin/SPPPA
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
            insertAdminAuditLog(conn, currentAdminId, "DELETE USER",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " memadam pengguna " + resolveDisplayUserId(conn, targetUserId),
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

        String requestedStatus = request.getParameter("status");
        if (requestedStatus != null) {
            requestedStatus = requestedStatus.trim().toUpperCase(Locale.ROOT);
            if (!"ACTIVE".equals(requestedStatus) && !"SUSPENDED".equals(requestedStatus)) {
                response.sendRedirect(request.getContextPath() + "/admin/users?error=invalid_action");
                return;
            }
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

            String targetStatus = requestedStatus;
            if (targetStatus == null || targetStatus.isBlank()) {
                targetStatus = "ACTIVE".equals(currentStatus) ? "SUSPENDED" : "ACTIVE";
            }

            if (targetStatus.equals(currentStatus)) {
                response.sendRedirect(request.getContextPath() + "/admin/users?toggled=1");
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE users SET status = ? WHERE id = ?")) {
                ps.setString(1, targetStatus);
                ps.setInt(2, targetUserId);
                ps.executeUpdate();
            }
            insertAdminAuditLog(conn, currentAdminId, "TOGGLE USER STATUS",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " set status pengguna " + resolveDisplayUserId(conn, targetUserId)
                        + " kepada " + targetStatus,
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
            insertAdminAuditLog(conn, currentAdminId, "RESET PASSWORD",
                    "Admin " + resolveDisplayUserId(conn, currentAdminId)
                        + " reset kata laluan pengguna " + resolveDisplayUserId(conn, targetUserId),
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
            DashboardDataService.ensureAuditLogTable(conn);
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
<<<<<<< HEAD

    private void ensureUsersRoleSupportsStaff(Connection conn) throws SQLException {
        String sql = "SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS "
                + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'";
        String columnType = null;
        try (PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                columnType = rs.getString("COLUMN_TYPE");
            }
        }

        if (columnType == null) {
            return;
        }

        if (!columnType.toUpperCase(Locale.ROOT).contains("'STAFF'")) {
            try (PreparedStatement stmt = conn.prepareStatement(
                    "ALTER TABLE users MODIFY COLUMN role ENUM('ADMIN', 'USER', 'STAFF') NOT NULL DEFAULT 'USER'")) {
                stmt.executeUpdate();
            }
        }
    }

    private String resolveDisplayUserId(Connection conn, int userId) {
        String role = null;
        Integer roleSeq = null;
        try (PreparedStatement stmt = conn.prepareStatement("SELECT role, role_seq FROM users WHERE id = ?")) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    role = rs.getString("role");
                    roleSeq = rs.getObject("role_seq", Integer.class);
                }
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to resolve role for display user id: " + e.getMessage());
        }
        return UserDisplayIdUtil.format(userId, role, roleSeq);
    }

    private void syncKppContactsFromCsv(Connection conn) {
        try {
            if (!Files.exists(KPP_CSV_PATH)) {
                return;
            }

            List<Map<String, Object>> existingContacts = DashboardDataService.loadKppContacts(conn);
            Set<String> existingEmails = new HashSet<>();
            for (Map<String, Object> contact : existingContacts) {
                String email = contact.get("email") == null ? "" : String.valueOf(contact.get("email")).trim();
                if (!email.isBlank()) {
                    existingEmails.add(email.toLowerCase(Locale.ROOT));
                }
            }

            List<String> lines = Files.readAllLines(KPP_CSV_PATH, StandardCharsets.UTF_8);
            for (int i = 1; i < lines.size(); i++) {
                String line = lines.get(i);
                if (line == null || line.isBlank()) {
                    continue;
                }

                List<String> parts = parseCsvLine(line);
                if (parts.size() < 3) {
                    continue;
                }

                String name = parts.get(0).trim();
                String branch = parts.get(1).trim();
                String email = parts.get(2).trim();
                if (name.isBlank() || email.isBlank()) {
                    continue;
                }

                String emailKey = email.toLowerCase(Locale.ROOT);
                if (existingEmails.contains(emailKey)) {
                    continue;
                }

                DashboardDataService.addKppContact(conn, name, branch, email);
                existingEmails.add(emailKey);
            }
        } catch (Exception e) {
            LOGGER.warning("Failed to sync KPP contacts from CSV: " + e.getMessage());
        }
    }

    private void appendKppContactToCsv(String name, String branch, String email) {
        try {
            if (KPP_CSV_PATH.getParent() != null) {
                Files.createDirectories(KPP_CSV_PATH.getParent());
            }

            List<String> existing = Files.exists(KPP_CSV_PATH)
                    ? Files.readAllLines(KPP_CSV_PATH, StandardCharsets.UTF_8)
                    : new ArrayList<>();

            if (existing.isEmpty()) {
                existing.add("Nama KPP,Cawangan,E-mel");
            }

            for (int i = 1; i < existing.size(); i++) {
                List<String> row = parseCsvLine(existing.get(i));
                if (row.size() >= 3) {
                    String existingEmail = row.get(2) == null ? "" : row.get(2).trim();
                    if (existingEmail.equalsIgnoreCase(email)) {
                        return;
                    }
                }
            }

            String csvRow = csvEscape(name) + "," + csvEscape(branch) + "," + csvEscape(email);
            Files.write(KPP_CSV_PATH, List.of(csvRow), StandardCharsets.UTF_8,
                    StandardOpenOption.APPEND, StandardOpenOption.CREATE);
        } catch (Exception e) {
            LOGGER.warning("Failed to append KPP contact to CSV: " + e.getMessage());
        }
    }

    private void removeKppContactFromCsv(String email) {
        try {
            if (!Files.exists(KPP_CSV_PATH)) {
                return;
            }

            List<String> lines = Files.readAllLines(KPP_CSV_PATH, StandardCharsets.UTF_8);
            if (lines.isEmpty()) {
                return;
            }

            List<String> updated = new ArrayList<>();
            updated.add(lines.get(0));
            for (int i = 1; i < lines.size(); i++) {
                String line = lines.get(i);
                if (line == null || line.isBlank()) {
                    continue;
                }
                List<String> parts = parseCsvLine(line);
                if (parts.size() < 3) {
                    updated.add(line);
                    continue;
                }
                String rowEmail = parts.get(2) == null ? "" : parts.get(2).trim();
                if (!rowEmail.equalsIgnoreCase(email)) {
                    updated.add(line);
                }
            }

            Files.write(KPP_CSV_PATH, updated, StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        } catch (Exception e) {
            LOGGER.warning("Failed to remove KPP contact from CSV: " + e.getMessage());
        }
    }

    private List<String> parseCsvLine(String line) {
        List<String> values = new ArrayList<>();
        if (line == null) {
            return values;
        }

        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    current.append('"');
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
                continue;
            }
            if (c == ',' && !inQuotes) {
                values.add(current.toString());
                current.setLength(0);
                continue;
            }
            current.append(c);
        }
        values.add(current.toString());
        return values;
    }

    private String csvEscape(String value) {
        String safe = value == null ? "" : value;
        String escaped = safe.replace("\"", "\"\"");
        if (escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r")) {
            return "\"" + escaped + "\"";
        }
        return escaped;
    }
=======
>>>>>>> origin/SPPPA
}

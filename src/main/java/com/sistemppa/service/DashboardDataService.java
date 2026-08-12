package com.sistemppa.service;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DashboardDataService.
 * Dipanggil oleh servlet untuk proses logik bisnes.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.util.UserDisplayIdUtil;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class DashboardDataService {
    private static final Pattern LEGACY_ADMIN_ID_PATTERN = Pattern.compile("Admin\\s*#(\\d+)");
        private static final String APPLICATION_STATUS_ENUM = "ENUM('DRAFT', 'NEW', 'UNDER_REVIEW', 'IN_PROGRESS', "
            + "'MENUNGGU_TINDAKAN_PENGARAH', 'MENUNGGU_SETERUSNYA_DILULUSKAN', "
            + "'MENUNGGU_SETERUSNYA_GAGAL', 'MENUNGGU_SETERUSNYA_GANTUNG', "
            + "'MENUNGGU_SETERUSNYA_BATAL', 'DILULUSKAN_PENGARAH', 'APPROVED', 'REJECTED', 'SUSPENDED', 'ARCHIVED', 'KUERI')";

    private DashboardDataService() {
    }

    public static void ensureApplicationWorkflowSchema(Connection conn) throws SQLException {
        ensureApplicationStatusColumn(conn);
        ensureStatusHistoryTable(conn);
        ensureStatusHistoryColumnWidths(conn);
    }

    public static Map<String, Integer> loadAdminStats(Connection conn) throws SQLException {
        ensureApplicationArchiveTable(conn);
        ensureUserProfileReviewColumns(conn);

        Map<String, Integer> stats = new HashMap<>();

        String sql = "SELECT "
                + "COUNT(CASE WHEN aa.application_id IS NULL THEN 1 END) AS total_applications, "
            + "SUM(CASE WHEN aa.application_id IS NULL AND ((COALESCE(ad.application_type, 'BAHARU') IN ('BAHARU', 'PEMBAHARUAN') AND a.status = 'DILULUSKAN_PENGARAH') OR (COALESCE(ad.application_type, 'BAHARU') = 'KEMASKINI' AND a.status IN ('NEW', 'DRAFT', 'UNDER_REVIEW'))) THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'SUSPENDED' THEN 1 ELSE 0 END) AS suspended_count, "
                + "SUM(CASE WHEN aa.application_id IS NOT NULL THEN 1 ELSE 0 END) AS archived_count "
                + "FROM applications a "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("total_applications", rs.getInt("total_applications"));
                stats.put("pending_count", rs.getInt("pending_count"));
                stats.put("approved_count", rs.getInt("approved_count"));
                stats.put("rejected_count", rs.getInt("rejected_count"));
                stats.put("suspended_count", rs.getInt("suspended_count"));
                stats.put("archived_count", rs.getInt("archived_count"));
            }
        }

        stats.put("active_users", countByQuery(conn,
                "SELECT COUNT(*) FROM users WHERE status = 'ACTIVE'"));
        stats.put("registered_users", countRegisteredUsers(conn, false));
        stats.put("new_registered_users", countRegisteredUsers(conn, true));
        stats.put("profile_pending_count", countByQuery(conn,
            "SELECT COUNT(*) FROM users WHERE role = 'USER' AND profile_review_status = 'PENDING_REVIEW'"));
        stats.put("total_products", countProducts(conn, null, null));
        return stats;
    }

    public static List<Map<String, Object>> loadRegisteredUsers(Connection conn, String search,
                                                                 boolean onlyNew, int limit) throws SQLException {
        ensureUserProfileReviewColumns(conn);
        StringBuilder sql = new StringBuilder("SELECT id, username, full_name, email, phone_number, role, role_seq, status, avatar_url, supporting_document_url, profile_review_status, profile_submitted_at, profile_reviewed_at, profile_reviewed_by, profile_review_notes, created_at "
            + "FROM users WHERE role = 'USER'");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (onlyNew) {
            sql.append(" AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)");
        }

        sql.append(" ORDER BY created_at DESC, id DESC");
        if (limit > 0) {
            sql.append(" LIMIT ?");
        }

        List<Map<String, Object>> users = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            int index = applyParameters(stmt, parameters);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("username", rs.getString("username"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("email", rs.getString("email"));
                    row.put("phone_number", rs.getString("phone_number"));
                        row.put("display_id", UserDisplayIdUtil.format(
                            rs.getInt("id"),
                            rs.getString("role"),
                            rs.getObject("role_seq", Integer.class)));
                    row.put("avatar_url", rs.getString("avatar_url"));
                    row.put("supporting_document_url", rs.getString("supporting_document_url"));
                    row.put("profile_review_status", rs.getString("profile_review_status"));
                    row.put("profile_submitted_at", rs.getTimestamp("profile_submitted_at"));
                    row.put("profile_reviewed_at", rs.getTimestamp("profile_reviewed_at"));
                    row.put("profile_reviewed_by", rs.getObject("profile_reviewed_by"));
                    row.put("profile_review_notes", rs.getString("profile_review_notes"));
                    row.put("status", rs.getString("status"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    users.add(row);
                }
            }
        }
        return users;
    }

    public static int countRegisteredUsers(Connection conn, boolean onlyNew) throws SQLException {
        String sql = onlyNew
                ? "SELECT COUNT(*) FROM users WHERE role = 'USER' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
                : "SELECT COUNT(*) FROM users WHERE role = 'USER'";
        return countByQuery(conn, sql);
    }

    public static Map<String, Object> loadUserSummary(Connection conn, int userId) throws SQLException {
        ensureUserProfileReviewColumns(conn);
        Map<String, Object> user = new HashMap<>();
        String sql = "SELECT username, full_name, email, phone_number, avatar_url, supporting_document_url, profile_review_status, profile_submitted_at, profile_reviewed_at, profile_reviewed_by, profile_review_notes, status, created_at "
                + "FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    user.put("username", rs.getString("username"));
                    user.put("full_name", rs.getString("full_name"));
                    user.put("email", rs.getString("email"));
                    user.put("phone_number", rs.getString("phone_number"));
                    user.put("avatar_url", rs.getString("avatar_url"));
                    user.put("supporting_document_url", rs.getString("supporting_document_url"));
                    user.put("profile_review_status", rs.getString("profile_review_status"));
                    user.put("profile_submitted_at", rs.getTimestamp("profile_submitted_at"));
                    user.put("profile_reviewed_at", rs.getTimestamp("profile_reviewed_at"));
                    user.put("profile_reviewed_by", rs.getObject("profile_reviewed_by"));
                    user.put("profile_review_notes", rs.getString("profile_review_notes"));
                    user.put("status", rs.getString("status"));
                    user.put("created_at", rs.getTimestamp("created_at"));
                }
            }
        }
        return user;
    }

    public static int countUserApplications(Connection conn, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM applications WHERE user_id = ?")) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countPendingUserApplications(Connection conn, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM applications WHERE user_id = ? AND status IN ('DIRECTOR_REVIEW', 'NEW')")) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countApplicationsByStatuses(Connection conn, String... statuses) throws SQLException {
        ensureApplicationArchiveTable(conn);
        if (statuses == null || statuses.length == 0) return 0;
        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < statuses.length; i++) {
            if (i > 0) placeholders.append(',');
            placeholders.append('?');
        }
        String sql = "SELECT COUNT(*) FROM applications a LEFT JOIN application_archives aa ON aa.application_id = a.id "
            + "WHERE aa.application_id IS NULL AND UPPER(a.status) IN (" + placeholders.toString() + ")";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (int i = 0; i < statuses.length; i++) {
                stmt.setString(i + 1, statuses[i].toUpperCase(java.util.Locale.ROOT));
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countApplicationsByAdminNotesPattern(Connection conn, String pattern) throws SQLException {
        if (pattern == null || pattern.isBlank()) return 0;
        String sql = "SELECT COUNT(*) FROM applications WHERE admin_notes IS NOT NULL AND LOWER(admin_notes) LIKE ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, pattern.toLowerCase(java.util.Locale.ROOT));
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countUserApplicationsByStatus(Connection conn, int userId, String status) throws SQLException {
        if (status == null || status.isBlank()) return 0;
        String sql = "SELECT COUNT(*) FROM applications WHERE user_id = ? AND UPPER(status) = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, status.toUpperCase(java.util.Locale.ROOT));
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countNotificationsByType(Connection conn, int userId, String type) throws SQLException {
        if (type == null || type.isBlank()) return 0;
        String sql = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND UPPER(type) = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, type.toUpperCase(java.util.Locale.ROOT));
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<Map<String, Object>> loadUserApplications(Connection conn, int userId) throws SQLException {
        List<Map<String, Object>> applications = new ArrayList<>();
        String sql = "SELECT id, product_name, company_name, status, submitted_at, admin_notes "
                + "FROM applications WHERE user_id = ? ORDER BY created_at DESC";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("status", rs.getString("status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static List<Map<String, Object>> loadApplications(Connection conn, String search, String status,
            String dateFrom, String dateTo, int limit) throws SQLException {
        ensureApplicationArchiveTable(conn);

        QueryParts queryParts = buildApplicationFilter(search, status, dateFrom, dateTo);
        String sql = "SELECT a.id, a.company_name, a.company_address, a.contact_number, a.email AS supplier_email, "
            + "a.product_category, a.product_name, a.product_description, "
            + "CASE WHEN aa.application_id IS NOT NULL THEN 'ARCHIVED' ELSE a.status END AS display_status, "
            + "a.submitted_at, aa.archived_at, aa.archive_notes, aa.archived_by, "
                + "u.full_name, u.email AS user_email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
                + "ad.declaration_name, ad.declaration_position "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + queryParts.clause
                + " ORDER BY COALESCE(aa.archived_at, a.created_at) DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> applications = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = applyParameters(stmt, queryParts.parameters);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("company_address", rs.getString("company_address"));
                    row.put("contact_number", rs.getString("contact_number"));
                    row.put("supplier_email", rs.getString("supplier_email"));
                    row.put("product_category", rs.getString("product_category"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("product_description", rs.getString("product_description"));
                    String displayStatus = rs.getString("display_status");
                    row.put("status", displayStatus);
                    row.put("director_action_pending", isDirectorActionPendingStatus(displayStatus));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("archived_at", rs.getTimestamp("archived_at"));
                    row.put("archive_notes", rs.getString("archive_notes"));
                    row.put("archived_by", rs.getObject("archived_by"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    row.put("application_type", rs.getString("application_type"));
                    row.put("supplier_name", rs.getString("supplier_name"));
                    row.put("supplier_address", rs.getString("supplier_address"));
                    row.put("supplier_phone", rs.getString("supplier_phone"));
                    row.put("manufacturer_name", rs.getString("manufacturer_name"));
                    row.put("manufacturer_address", rs.getString("manufacturer_address"));
                    row.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    row.put("principal_name", rs.getString("principal_name"));
                    row.put("principal_address", rs.getString("principal_address"));
                    row.put("principal_phone", rs.getString("principal_phone"));
                    row.put("standard_name", rs.getString("standard_name"));
                    row.put("certification_license", rs.getString("certification_license"));
                    row.put("certification_valid_until", rs.getDate("certification_valid_until"));
                    row.put("test_report_reference", rs.getString("test_report_reference"));
                    row.put("test_report_date", rs.getDate("test_report_date"));
                    row.put("warranty_years", rs.getBigDecimal("warranty_years"));
                    row.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    row.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    row.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    row.put("declaration_name", rs.getString("declaration_name"));
                    row.put("declaration_position", rs.getString("declaration_position"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static int countDirectorActionPendingForAdmin(Connection conn) throws SQLException {
        return countApplicationsByStatuses(conn,
                "MENUNGGU_SETERUSNYA_DILULUSKAN",
                "MENUNGGU_SETERUSNYA_GAGAL",
                "MENUNGGU_SETERUSNYA_GANTUNG",
                "MENUNGGU_SETERUSNYA_BATAL");
    }

    public static List<Map<String, Object>> loadDirectorProcessedApplications(Connection conn, int directorUserId,
            String search, String dateFrom, String dateTo, int limit) throws SQLException {
        ensureApplicationArchiveTable(conn);

        StringBuilder clause = new StringBuilder(" WHERE a.reviewed_by = ? AND a.status <> 'DIRECTOR_REVIEW'");
        List<Object> parameters = new ArrayList<>();
        parameters.add(directorUserId);

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        String sql = "SELECT a.id, a.company_name, a.company_address, a.contact_number, a.email AS supplier_email, "
            + "a.product_category, a.product_name, a.product_description, "
            + "CASE WHEN aa.application_id IS NOT NULL THEN 'ARCHIVED' ELSE a.status END AS display_status, "
            + "a.submitted_at, a.reviewed_at, a.reviewed_by, a.admin_notes, aa.archived_at, aa.archive_notes, aa.archived_by, "
            + "u.full_name, u.email AS user_email, "
            + "ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
            + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
            + "ad.principal_name, ad.principal_address, ad.principal_phone, "
            + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
            + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
            + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
            + "ad.declaration_name, ad.declaration_position "
            + "FROM applications a "
            + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
            + clause.toString()
            + " ORDER BY COALESCE(a.reviewed_at, a.created_at) DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> applications = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = 1;
            for (Object parameter : parameters) {
                stmt.setObject(index++, parameter);
            }
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("company_address", rs.getString("company_address"));
                    row.put("contact_number", rs.getString("contact_number"));
                    row.put("supplier_email", rs.getString("supplier_email"));
                    row.put("product_category", rs.getString("product_category"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("product_description", rs.getString("product_description"));
                    row.put("status", rs.getString("display_status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                    row.put("reviewed_by", rs.getObject("reviewed_by"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    row.put("archived_at", rs.getTimestamp("archived_at"));
                    row.put("archive_notes", rs.getString("archive_notes"));
                    row.put("archived_by", rs.getObject("archived_by"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    row.put("application_type", rs.getString("application_type"));
                    row.put("supplier_name", rs.getString("supplier_name"));
                    row.put("supplier_address", rs.getString("supplier_address"));
                    row.put("supplier_phone", rs.getString("supplier_phone"));
                    row.put("manufacturer_name", rs.getString("manufacturer_name"));
                    row.put("manufacturer_address", rs.getString("manufacturer_address"));
                    row.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    row.put("principal_name", rs.getString("principal_name"));
                    row.put("principal_address", rs.getString("principal_address"));
                    row.put("principal_phone", rs.getString("principal_phone"));
                    row.put("standard_name", rs.getString("standard_name"));
                    row.put("certification_license", rs.getString("certification_license"));
                    row.put("certification_valid_until", rs.getDate("certification_valid_until"));
                    row.put("test_report_reference", rs.getString("test_report_reference"));
                    row.put("test_report_date", rs.getDate("test_report_date"));
                    row.put("warranty_years", rs.getBigDecimal("warranty_years"));
                    row.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    row.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    row.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    row.put("declaration_name", rs.getString("declaration_name"));
                    row.put("declaration_position", rs.getString("declaration_position"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static int countDirectorProcessedApplications(Connection conn, int directorUserId, String search,
            String dateFrom, String dateTo) throws SQLException {
        ensureApplicationArchiveTable(conn);

        StringBuilder clause = new StringBuilder(" WHERE a.reviewed_by = ? AND a.status <> 'DIRECTOR_REVIEW'");
        List<Object> parameters = new ArrayList<>();
        parameters.add(directorUserId);

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        String sql = "SELECT COUNT(*) FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id"
                + clause;
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = 1;
            for (Object parameter : parameters) {
                stmt.setObject(index++, parameter);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countDirectorProcessedApplicationsByStatus(Connection conn, int directorUserId, String status,
            String search, String dateFrom, String dateTo) throws SQLException {
        ensureApplicationArchiveTable(conn);

        String normalizedStatus = normalizeApplicationStatusFilter(status);
        if (normalizedStatus == null || "DIRECTOR_REVIEW".equals(normalizedStatus)) {
            return 0;
        }

        String historyStatus = normalizedStatus;
        if ("APPROVED".equals(normalizedStatus)) {
            historyStatus = "NEW";
        }

        StringBuilder clause = new StringBuilder(
                " WHERE ash.changed_by = ? AND ash.new_status = ? AND ash.id = latest.max_id");
        List<Object> parameters = new ArrayList<>();
        parameters.add(directorUserId);
        parameters.add(historyStatus);

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        String sql = "SELECT COUNT(*) FROM application_status_history ash "
                + "JOIN (SELECT application_id, MAX(id) AS max_id FROM application_status_history WHERE changed_by = ? GROUP BY application_id) latest ON latest.max_id = ash.id "
                + "JOIN applications a ON a.id = ash.application_id "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id"
                + clause;
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = 1;
            stmt.setInt(index++, directorUserId);
            for (Object parameter : parameters) {
                stmt.setObject(index++, parameter);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<Map<String, Object>> loadDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo, int limit) throws SQLException {
        return loadDirectorAdminApplications(conn, search, dateFrom, dateTo, limit, null, null);
    }

    public static List<Map<String, Object>> loadDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo, int limit, String reviewType) throws SQLException {
        return loadDirectorAdminApplications(conn, search, dateFrom, dateTo, limit, reviewType, null);
    }

    /**
     * @param fromAdmin null = no filter, true = only applications forwarded by ADMIN, false = only applications NOT from ADMIN
     */
    public static List<Map<String, Object>> loadDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo, int limit, String reviewType, Boolean fromAdmin) throws SQLException {
        ensureApplicationArchiveTable(conn);
        ensureStatusHistoryTable(conn);

        StringBuilder clause = new StringBuilder(" WHERE a.status = 'MENUNGGU_TINDAKAN_PENGARAH'");
        // Exclude KEMASKINI application type from director dashboard
        clause.append(" AND (ad.application_type IS NULL OR UPPER(ad.application_type) <> 'KEMASKINI')");
        if (reviewType != null && !reviewType.isBlank()) {
            clause.append(" AND a.director_review_type = '").append(reviewType.toUpperCase().replace("'","")).append("'");
        }
        if (Boolean.TRUE.equals(fromAdmin)) {
            clause.append(" AND actor.role = 'ADMIN'");
        } else if (Boolean.FALSE.equals(fromAdmin)) {
            clause.append(" AND (actor.role IS NULL OR actor.role <> 'ADMIN')");
        }
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        String sql = "SELECT a.id, a.company_name, a.company_address, a.contact_number, a.email AS supplier_email, "
            + "a.product_category, a.product_name, a.product_description, "
            + "a.status AS display_status, "
            + "a.submitted_at, a.reviewed_at, a.reviewed_by, a.admin_notes, "
            + "u.full_name, u.email AS user_email, "
            + "ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
            + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
            + "ad.principal_name, ad.principal_address, ad.principal_phone, "
            + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
            + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
            + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
            + "ad.declaration_name, ad.declaration_position, "
            + "hist.changed_at AS admin_sent_at, actor.full_name AS last_changed_by_name, actor.role AS last_changed_by_role "
            + "FROM applications a "
            + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN (SELECT application_id, MAX(id) AS max_id FROM application_status_history GROUP BY application_id) latest ON latest.application_id = a.id "
            + "LEFT JOIN application_status_history hist ON hist.id = latest.max_id "
            + "LEFT JOIN users actor ON actor.id = hist.changed_by "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
            + clause.toString()
            + " ORDER BY COALESCE(a.reviewed_at, hist.changed_at, a.created_at) DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> applications = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = 1;
            for (Object parameter : parameters) {
                stmt.setObject(index++, parameter);
            }
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("company_address", rs.getString("company_address"));
                    row.put("contact_number", rs.getString("contact_number"));
                    row.put("supplier_email", rs.getString("supplier_email"));
                    row.put("product_category", rs.getString("product_category"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("product_description", rs.getString("product_description"));
                    row.put("status", rs.getString("display_status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                    row.put("reviewed_by", rs.getObject("reviewed_by"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    row.put("application_type", rs.getString("application_type"));
                    row.put("supplier_name", rs.getString("supplier_name"));
                    row.put("supplier_address", rs.getString("supplier_address"));
                    row.put("supplier_phone", rs.getString("supplier_phone"));
                    row.put("manufacturer_name", rs.getString("manufacturer_name"));
                    row.put("manufacturer_address", rs.getString("manufacturer_address"));
                    row.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    row.put("principal_name", rs.getString("principal_name"));
                    row.put("principal_address", rs.getString("principal_address"));
                    row.put("principal_phone", rs.getString("principal_phone"));
                    row.put("standard_name", rs.getString("standard_name"));
                    row.put("certification_license", rs.getString("certification_license"));
                    row.put("certification_valid_until", rs.getDate("certification_valid_until"));
                    row.put("test_report_reference", rs.getString("test_report_reference"));
                    row.put("test_report_date", rs.getDate("test_report_date"));
                    row.put("warranty_years", rs.getBigDecimal("warranty_years"));
                    row.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    row.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    row.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    row.put("declaration_name", rs.getString("declaration_name"));
                    row.put("declaration_position", rs.getString("declaration_position"));
                    row.put("admin_sent_at", rs.getTimestamp("admin_sent_at"));
                    row.put("last_changed_by_name", rs.getString("last_changed_by_name"));
                    row.put("last_changed_by_role", rs.getString("last_changed_by_role"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static int countDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo) throws SQLException {
        return countDirectorAdminApplications(conn, search, dateFrom, dateTo, null, null);
    }

    public static int countDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo, String reviewType) throws SQLException {
        return countDirectorAdminApplications(conn, search, dateFrom, dateTo, reviewType, null);
    }

    /**
     * @param fromAdmin null = no filter, true = only from ADMIN, false = only NOT from ADMIN
     */
    public static int countDirectorAdminApplications(Connection conn, String search,
            String dateFrom, String dateTo, String reviewType, Boolean fromAdmin) throws SQLException {
        ensureApplicationArchiveTable(conn);
        ensureStatusHistoryTable(conn);

        StringBuilder clause = new StringBuilder(" WHERE a.status = 'MENUNGGU_TINDAKAN_PENGARAH'");
        // Exclude KEMASKINI application type from director dashboard
        clause.append(" AND (ad.application_type IS NULL OR UPPER(ad.application_type) <> 'KEMASKINI')");
        if (reviewType != null && !reviewType.isBlank()) {
            clause.append(" AND a.director_review_type = '").append(reviewType.toUpperCase().replace("'","")).append("'");
        }
        if (Boolean.TRUE.equals(fromAdmin)) {
            clause.append(" AND actor.role = 'ADMIN'");
        } else if (Boolean.FALSE.equals(fromAdmin)) {
            clause.append(" AND (actor.role IS NULL OR actor.role <> 'ADMIN')");
        }
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        String sql = "SELECT COUNT(*) FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN (SELECT application_id, MAX(id) AS max_id FROM application_status_history GROUP BY application_id) latest ON latest.application_id = a.id "
                + "LEFT JOIN application_status_history hist ON hist.id = latest.max_id "
                + "LEFT JOIN users actor ON actor.id = hist.changed_by "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id"
                + clause;
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = 1;
            for (Object parameter : parameters) {
                stmt.setObject(index++, parameter);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static int countApplications(Connection conn, String search, String status,
            String dateFrom, String dateTo) throws SQLException {
        ensureApplicationArchiveTable(conn);

        QueryParts queryParts = buildApplicationFilter(search, status, dateFrom, dateTo);
        String sql = "SELECT COUNT(*) FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id"
                + queryParts.clause;
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            applyParameters(stmt, queryParts.parameters);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<Map<String, Object>> loadProducts(Connection conn, String search, String productType, int limit)
            throws SQLException {
        String tableName = resolveProductTable(conn);
        QueryParts queryParts = buildProductFilter(search, productType);
        String sql = "SELECT no, supplier_agent, supplier_valid_until, product_materials, product_type, "
            + "classification, brand, attachment_urls, source_url "
                + "FROM " + tableName + queryParts.clause + " ORDER BY no ASC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> products = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = applyParameters(stmt, queryParts.parameters);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("no", rs.getInt("no"));
                    row.put("supplier_agent", rs.getString("supplier_agent"));
                    row.put("supplier_valid_until", rs.getDate("supplier_valid_until"));
                    row.put("product_materials", rs.getString("product_materials"));
                    row.put("product_type", rs.getString("product_type"));
                    row.put("classification", rs.getString("classification"));
                    row.put("brand", rs.getString("brand"));
                    row.put("attachment_urls", rs.getString("attachment_urls"));
                    row.put("source_url", rs.getString("source_url"));
                    products.add(row);
                }
            }
        }
        return products;
    }

    public static int countProducts(Connection conn, String search, String productType) throws SQLException {
        String tableName = resolveProductTable(conn);
        QueryParts queryParts = buildProductFilter(search, productType);
        String sql = "SELECT COUNT(*) FROM " + tableName + queryParts.clause;
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            applyParameters(stmt, queryParts.parameters);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<String> loadProductTypes(Connection conn) throws SQLException {
        String tableName = resolveProductTable(conn);
        List<String> productTypes = new ArrayList<>();
        String sql = "SELECT DISTINCT product_type FROM " + tableName
                + " WHERE product_type IS NOT NULL AND product_type <> '' ORDER BY product_type ASC";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                productTypes.add(rs.getString(1));
            }
        }
        return productTypes;
    }

    public static void createAnnouncement(Connection conn, String title, String content,
                                          String imageUrl, boolean isActive, Integer userId) throws SQLException {
        ensureAnnouncementsTable(conn);
        String sql = "INSERT INTO announcements (title, content, image_url, is_active, created_by, updated_by) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, title);
            stmt.setString(2, content);
            stmt.setString(3, imageUrl);
            stmt.setBoolean(4, isActive);
            if (userId == null) {
                stmt.setNull(5, java.sql.Types.INTEGER);
                stmt.setNull(6, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(5, userId);
                stmt.setInt(6, userId);
            }
            stmt.executeUpdate();
        }
    }

    public static void updateAnnouncement(Connection conn, int announcementId, String title, String content,
                                          String imageUrl, boolean isActive, Integer userId) throws SQLException {
        ensureAnnouncementsTable(conn);
        String sql = "UPDATE announcements "
                + "SET title = ?, content = ?, image_url = ?, is_active = ?, updated_by = ?, updated_at = CURRENT_TIMESTAMP "
                + "WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, title);
            stmt.setString(2, content);
            stmt.setString(3, imageUrl);
            stmt.setBoolean(4, isActive);
            if (userId == null) {
                stmt.setNull(5, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(5, userId);
            }
            stmt.setInt(6, announcementId);
            stmt.executeUpdate();
        }
    }

    public static void deleteAnnouncement(Connection conn, int announcementId) throws SQLException {
        ensureAnnouncementsTable(conn);
        try (PreparedStatement stmt = conn.prepareStatement("DELETE FROM announcements WHERE id = ?")) {
            stmt.setInt(1, announcementId);
            stmt.executeUpdate();
        }
    }

    public static Map<String, Object> loadAnnouncementById(Connection conn, int announcementId) throws SQLException {
        ensureAnnouncementsTable(conn);
        String sql = "SELECT a.id, a.title, a.content, a.image_url, a.is_active, a.created_at, a.updated_at, "
                + "a.created_by, a.updated_by, cu.full_name AS created_by_name, uu.full_name AS updated_by_name "
                + "FROM announcements a "
                + "LEFT JOIN users cu ON cu.id = a.created_by "
                + "LEFT JOIN users uu ON uu.id = a.updated_by "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, announcementId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapAnnouncementRow(rs);
                }
            }
        }
        return new HashMap<>();
    }

    public static List<Map<String, Object>> loadAllAnnouncements(Connection conn, int limit) throws SQLException {
        ensureAnnouncementsTable(conn);
        String sql = "SELECT a.id, a.title, a.content, a.image_url, a.is_active, a.created_at, a.updated_at, "
                + "a.created_by, a.updated_by, cu.full_name AS created_by_name, uu.full_name AS updated_by_name "
                + "FROM announcements a "
                + "LEFT JOIN users cu ON cu.id = a.created_by "
                + "LEFT JOIN users uu ON uu.id = a.updated_by "
                + "ORDER BY a.is_active DESC, a.updated_at DESC, a.id DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> announcements = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (limit > 0) {
                stmt.setInt(1, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    announcements.add(mapAnnouncementRow(rs));
                }
            }
        }
        return announcements;
    }

    public static List<Map<String, Object>> loadRecentAdminAuditLogs(Connection conn, int limit) throws SQLException {
        ensureAuditLogTable(conn);
        String sql = "SELECT al.id, al.user_id, al.action, al.details, al.ip_address, al.created_at, "
            + "u.username, u.full_name, u.role, u.role_seq "
                + "FROM audit_log al "
                + "JOIN users u ON u.id = al.user_id "
                + "WHERE u.role = 'ADMIN' "
                + "ORDER BY al.created_at DESC, al.id DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> logs = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (limit > 0) {
                stmt.setInt(1, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("user_id", rs.getObject("user_id"));
                    row.put("action", rs.getString("action"));
                    row.put("details", normalizeLegacyAuditDetails(rs.getString("details")));
                    row.put("ip_address", rs.getString("ip_address"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("username", rs.getString("username"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("role", rs.getString("role"));
                        row.put("display_user_id", UserDisplayIdUtil.format(
                            rs.getInt("user_id"),
                            rs.getString("role"),
                            rs.getObject("role_seq", Integer.class)));
                    logs.add(row);
                }
            }
        }
        return logs;
    }

    public static List<Map<String, Object>> loadRecentAdminAuditLogsByKeyword(
            Connection conn, String keyword, int limit) throws SQLException {
        ensureAuditLogTable(conn);
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        if (normalizedKeyword.isBlank()) {
            return loadRecentAdminAuditLogs(conn, limit);
        }

        String sql = "SELECT al.id, al.user_id, al.action, al.details, al.ip_address, al.created_at, "
            + "u.username, u.full_name, u.role, u.role_seq "
                + "FROM audit_log al "
                + "JOIN users u ON u.id = al.user_id "
                + "WHERE u.role = 'ADMIN' AND (al.action LIKE ? OR al.details LIKE ?) "
                + "ORDER BY al.created_at DESC, al.id DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> logs = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            String like = "%" + normalizedKeyword + "%";
            stmt.setString(1, like);
            stmt.setString(2, like);
            if (limit > 0) {
                stmt.setInt(3, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("user_id", rs.getObject("user_id"));
                    row.put("action", rs.getString("action"));
                    row.put("details", normalizeLegacyAuditDetails(rs.getString("details")));
                    row.put("ip_address", rs.getString("ip_address"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("username", rs.getString("username"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("role", rs.getString("role"));
                    row.put("display_user_id", UserDisplayIdUtil.format(
                            rs.getInt("user_id"),
                            rs.getString("role"),
                            rs.getObject("role_seq", Integer.class)));
                    logs.add(row);
                }
            }
        }
        return logs;
    }

    public static String resolveDisplayUserId(Connection conn, Integer userId, String fallbackRole) throws SQLException {
        if (userId == null || userId <= 0) {
            return "-";
        }

        String sql = "SELECT role, role_seq FROM users WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String role = rs.getString("role");
                    Integer roleSeq = rs.getObject("role_seq", Integer.class);
                    return UserDisplayIdUtil.format(userId, role, roleSeq);
                }
            }
        }

        return UserDisplayIdUtil.format(userId, fallbackRole);
    }

    public static void ensureAuditLogTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS audit_log ("
                + "id BIGINT AUTO_INCREMENT PRIMARY KEY, "
                + "user_id INT NOT NULL, "
                + "action VARCHAR(120) NOT NULL, "
                + "details TEXT NULL, "
                + "ip_address VARCHAR(64) NULL, "
                + "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
                + "INDEX idx_audit_created_at (created_at), "
                + "INDEX idx_audit_user_id (user_id), "
                + "INDEX idx_audit_action (action)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.executeUpdate();
        }
    }

    public static List<Map<String, Object>> loadActiveAnnouncements(Connection conn, int limit) throws SQLException {
        ensureAnnouncementsTable(conn);
        String sql = "SELECT id, title, content, image_url, is_active, created_at, updated_at "
                + "FROM announcements WHERE is_active = 1 "
                + "ORDER BY updated_at DESC, id DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> announcements = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            if (limit > 0) {
                stmt.setInt(1, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    announcements.add(mapAnnouncementRow(rs));
                }
            }
        }
        return announcements;
    }

    private static String normalizeLegacyAuditDetails(String details) {
        if (details == null || details.isBlank()) {
            return details;
        }
        Matcher matcher = LEGACY_ADMIN_ID_PATTERN.matcher(details);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            int adminId = Integer.parseInt(matcher.group(1));
            String replacement = "Admin " + UserDisplayIdUtil.format(adminId, "ADMIN");
            matcher.appendReplacement(sb, Matcher.quoteReplacement(replacement));
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    public static List<Map<String, Object>> loadKppGuestSubmissions(
            Connection conn,
            int limit,
            String search,
            boolean includeArchived
    ) throws SQLException {
        ensureKppGuestSubmissionTable(conn);

        StringBuilder sql = new StringBuilder(
                "SELECT id, recipient_email, action_type, submitter_email, form_payload, submitted_at, archived, archived_at "
                        + "FROM kpp_guest_form_submissions WHERE 1=1"
        );
        List<Object> params = new ArrayList<>();

        if (!includeArchived) {
            sql.append(" AND archived = 0");
        }

        if (search != null && !search.isBlank()) {
            sql.append(" AND (recipient_email LIKE ? OR action_type LIKE ? OR submitter_email LIKE ? OR form_payload LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            params.add(keyword);
            params.add(keyword);
            params.add(keyword);
            params.add(keyword);
        }

        sql.append(" ORDER BY submitted_at DESC, id DESC");
        if (limit > 0) {
            sql.append(" LIMIT ?");
        }

        List<Map<String, Object>> submissions = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            int index = applyParameters(stmt, params);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    String payload = rs.getString("form_payload");
                    String branch = firstNonBlank(
                            extractJsonStringValue(payload, "f_respondent_branch"),
                            extractJsonStringValue(payload, "f_branch")
                    );
                    String position = firstNonBlank(
                            extractJsonStringValue(payload, "f_respondent_title"),
                            extractJsonStringValue(payload, "f_respondent_position_grade"),
                            extractJsonStringValue(payload, "f_position_grade")
                    );

                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("recipient_email", rs.getString("recipient_email"));
                    row.put("action_type", rs.getString("action_type"));
                    row.put("submitter_email", rs.getString("submitter_email"));
                    row.put("form_payload", payload == null ? "" : payload);
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("archived", rs.getBoolean("archived"));
                    row.put("archived_at", rs.getTimestamp("archived_at"));
                    row.put("kpp_display", buildKppDisplay(position, branch, rs.getString("recipient_email")));
                    row.put("form_display", toKppFormLabel(rs.getString("action_type")));
                    submissions.add(row);
                }
            }
        }

        return submissions;
    }

    public static List<Map<String, Object>> loadKppContacts(Connection conn) throws SQLException {
        ensureKppContactsTable(conn);
        List<Map<String, Object>> contacts = new ArrayList<>();
        String sql = "SELECT id, name, branch, email, is_active, created_at "
                + "FROM kpp_contacts WHERE is_active = 1 ORDER BY name ASC, id ASC";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getLong("id"));
                row.put("name", rs.getString("name"));
                row.put("branch", rs.getString("branch"));
                row.put("email", rs.getString("email"));
                row.put("is_active", rs.getBoolean("is_active"));
                row.put("created_at", rs.getTimestamp("created_at"));
                contacts.add(row);
            }
        }
        return contacts;
    }

    public static void addKppContact(Connection conn, String name, String branch, String email) throws SQLException {
        ensureKppContactsTable(conn);
        String sql = "INSERT INTO kpp_contacts (name, branch, email, is_active, created_at) VALUES (?, ?, ?, 1, CURRENT_TIMESTAMP)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, name);
            stmt.setString(2, branch);
            stmt.setString(3, email);
            stmt.executeUpdate();
        }
    }

    public static int deleteKppContact(Connection conn, long contactId) throws SQLException {
        ensureKppContactsTable(conn);
        try (PreparedStatement stmt = conn.prepareStatement("DELETE FROM kpp_contacts WHERE id = ?")) {
            stmt.setLong(1, contactId);
            return stmt.executeUpdate();
        }
    }

    public static Map<String, Object> loadKppGuestSubmissionById(Connection conn, long id) throws SQLException {
        ensureKppGuestSubmissionTable(conn);
        String sql = "SELECT id, recipient_email, action_type, submitter_email, form_payload, submitted_at, archived, archived_at "
                + "FROM kpp_guest_form_submissions WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return new HashMap<>();
                }
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getLong("id"));
                row.put("recipient_email", rs.getString("recipient_email"));
                row.put("action_type", rs.getString("action_type"));
                row.put("submitter_email", rs.getString("submitter_email"));
                row.put("form_payload", rs.getString("form_payload"));
                row.put("submitted_at", rs.getTimestamp("submitted_at"));
                row.put("archived", rs.getBoolean("archived"));
                row.put("archived_at", rs.getTimestamp("archived_at"));
                return row;
            }
        }
    }

    public static int archiveKppGuestSubmission(Connection conn, long id) throws SQLException {
        ensureKppGuestSubmissionTable(conn);
        String sql = "UPDATE kpp_guest_form_submissions SET archived = 1, archived_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate();
        }
    }

    public static int unarchiveKppGuestSubmission(Connection conn, long id) throws SQLException {
        ensureKppGuestSubmissionTable(conn);
        String sql = "UPDATE kpp_guest_form_submissions SET archived = 0, archived_at = NULL WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate();
        }
    }

    public static int deleteKppGuestSubmission(Connection conn, long id) throws SQLException {
        ensureKppGuestSubmissionTable(conn);
        String sql = "DELETE FROM kpp_guest_form_submissions WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate();
        }
    }

    private static String buildKppDisplay(String position, String branch, String fallbackEmail) {
        String safePosition = firstNonBlank(position);
        String safeBranch = firstNonBlank(branch);

        if (safePosition != null && safeBranch != null) {
            return "Ketua Penolong Pengarah (" + safePosition + ") - " + safeBranch;
        }
        if (safePosition != null) {
            return "Ketua Penolong Pengarah (" + safePosition + ")";
        }
        if (safeBranch != null) {
            return "Ketua Penolong Pengarah (" + safeBranch + ")";
        }
        String fallback = firstNonBlank(fallbackEmail, "KPP Tidak Diketahui");
        return "Ketua Penolong Pengarah (" + fallback + ")";
    }

    private static String toKppFormLabel(String actionType) {
        String normalized = actionType == null ? "" : actionType.trim().toUpperCase(Locale.ROOT);
        if ("KSPP_UJPPP".equals(normalized)) {
            return "Borang KSPP/UJPPP";
        }
        if ("UJPPP".equals(normalized)) {
            return "Borang UJPPP";
        }
        if ("SIASATAN_ADUAN".equals(normalized)) {
            return "Borang Siasatan Aduan Pembekal dan Produk Air";
        }
        return "Borang KSPP";
    }

    private static String extractJsonStringValue(String json, String key) {
        if (json == null || json.isBlank() || key == null || key.isBlank()) {
            return "";
        }

        String pattern = "\"" + key + "\":\"";
        int start = json.indexOf(pattern);
        if (start < 0) {
            return "";
        }

        int cursor = start + pattern.length();
        StringBuilder value = new StringBuilder();
        boolean escaping = false;

        while (cursor < json.length()) {
            char ch = json.charAt(cursor++);
            if (escaping) {
                switch (ch) {
                    case 'n':
                        value.append('\n');
                        break;
                    case 'r':
                        value.append('\r');
                        break;
                    case 't':
                        value.append('\t');
                        break;
                    case '\\':
                        value.append('\\');
                        break;
                    case '"':
                        value.append('"');
                        break;
                    default:
                        value.append(ch);
                        break;
                }
                escaping = false;
                continue;
            }

            if (ch == '\\') {
                escaping = true;
                continue;
            }

            if (ch == '"') {
                break;
            }

            value.append(ch);
        }

        return value.toString().trim();
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null) {
                String trimmed = value.trim();
                if (!trimmed.isBlank()) {
                    return trimmed;
                }
            }
        }
        return null;
    }

    private static QueryParts buildApplicationFilter(String search, String status, String dateFrom, String dateTo) {
        StringBuilder clause = new StringBuilder(" WHERE 1=1");
        List<Object> parameters = new ArrayList<>();
        String normalizedStatus = normalizeApplicationStatusFilter(status);

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (normalizedStatus == null) {
            clause.append(" AND aa.application_id IS NULL");
            clause.append(" AND a.status <> 'DIRECTOR_REVIEW'");
            // BAHARU/PEMBAHARUAN only appear in admin list after director approval.
            clause.append(" AND NOT (COALESCE(ad.application_type, 'BAHARU') IN ('BAHARU', 'PEMBAHARUAN') AND a.status = 'MENUNGGU_TINDAKAN_PENGARAH')");
        } else if ("ARCHIVED".equals(normalizedStatus)) {
            clause.append(" AND aa.application_id IS NOT NULL");
        } else {
            clause.append(" AND aa.application_id IS NULL");
            clause.append(" AND a.status = ?");
            parameters.add(normalizedStatus);
        }

        if (dateFrom != null && !dateFrom.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) >= ?");
            parameters.add(dateFrom.trim());
        }
        if (dateTo != null && !dateTo.isBlank()) {
            clause.append(" AND DATE(a.submitted_at) <= ?");
            parameters.add(dateTo.trim());
        }

        return new QueryParts(clause.toString(), parameters);
    }

    private static void ensureKppContactsTable(Connection conn) throws SQLException {
        DatabaseMetaData meta = conn.getMetaData();
        try (ResultSet rs = meta.getTables(null, null, "kpp_contacts", null)) {
            if (rs.next()) {
                return;
            }
        }

        String ddl = "CREATE TABLE kpp_contacts ("
                + "id BIGINT NOT NULL AUTO_INCREMENT, "
                + "name VARCHAR(150) NOT NULL, "
                + "branch VARCHAR(180) NOT NULL, "
                + "email VARCHAR(200) NOT NULL, "
                + "is_active TINYINT(1) NOT NULL DEFAULT 1, "
                + "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
                + "PRIMARY KEY (id), "
                + "UNIQUE KEY uk_kpp_contacts_email (email)"
                + ")";

        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.executeUpdate();
        }
    }

    private static String normalizeApplicationStatusFilter(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }

        String normalized = status.trim().toUpperCase(Locale.ROOT);
        if ("DALAM_SEMAKAN".equals(normalized) || "DALAM SEMAKAN".equals(normalized)) {
            normalized = "UNDER_REVIEW";
        } else if ("DALAM_PROSES".equals(normalized) || "DALAM PROSES".equals(normalized)) {
            normalized = "IN_PROGRESS";
        } else if ("PERMOHONAN DITERIMA".equals(normalized)
                || "DITERIMA".equals(normalized)
                || "MENUNGGU_PENGARAH".equals(normalized)
                || "MENUNGGU PENGARAH".equals(normalized)
                || "DIRECTOR_REVIEW".equals(normalized)) {
            normalized = "UNDER_REVIEW";
        } else if ("DILULUSKAN_PENGARAH".equals(normalized)
                || "DILULUSKAN PENGARAH".equals(normalized)) {
            normalized = "DILULUSKAN_PENGARAH";
        } else if ("DILULUSKAN".equals(normalized)) {
            normalized = "APPROVED";
        } else if ("DITOLAK".equals(normalized)) {
            normalized = "REJECTED";
        } else if ("DIGANTUNG".equals(normalized)) {
            normalized = "SUSPENDED";
        } else if ("DIARKIB".equals(normalized)) {
            normalized = "ARCHIVED";
        }

        if ("ARCHIVED".equals(normalized)
            || "DIRECTOR_REVIEW".equals(normalized)
            || "NEW".equals(normalized)
            || "UNDER_REVIEW".equals(normalized)
            || "IN_PROGRESS".equals(normalized)
            || "MENUNGGU_TINDAKAN_PENGARAH".equals(normalized)
            || "MENUNGGU_SETERUSNYA_DILULUSKAN".equals(normalized)
            || "MENUNGGU_SETERUSNYA_GAGAL".equals(normalized)
            || "MENUNGGU_SETERUSNYA_GANTUNG".equals(normalized)
            || "MENUNGGU_SETERUSNYA_BATAL".equals(normalized)
            || "DILULUSKAN_PENGARAH".equals(normalized)
            || "APPROVED".equals(normalized)
            || "REJECTED".equals(normalized)
            || "SUSPENDED".equals(normalized)) {
            return normalized;
        }
        return null;
    }

    private static boolean isDirectorActionPendingStatus(String status) {
        if (status == null) {
            return false;
        }
        String normalized = status.trim().toUpperCase(Locale.ROOT).replace(' ', '_').replace('-', '_');
        return normalized.startsWith("MENUNGGU_SETERUSNYA_");
    }

    private static QueryParts buildProductFilter(String search, String productType) {
        StringBuilder clause = new StringBuilder(" WHERE 1=1");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (product_materials LIKE ? OR supplier_agent LIKE ? OR brand LIKE ? OR classification LIKE ? "
                    + "OR attachment_urls LIKE ? OR source_url LIKE ? "
                    + "OR DATE_FORMAT(supplier_valid_until, '%d-%m-%Y') LIKE ? OR DATE_FORMAT(supplier_valid_until, '%Y-%m-%d') LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (productType != null && !productType.isBlank()) {
            clause.append(" AND product_type = ?");
            parameters.add(productType.trim());
        }

        return new QueryParts(clause.toString(), parameters);
    }

    private static int applyParameters(PreparedStatement stmt, List<Object> parameters) throws SQLException {
        int index = 1;
        for (Object parameter : parameters) {
            stmt.setObject(index++, parameter);
        }
        return index;
    }

    private static Map<String, Object> mapAnnouncementRow(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<>();
        row.put("id", rs.getInt("id"));
        row.put("title", rs.getString("title"));
        row.put("content", rs.getString("content"));
        row.put("image_url", rs.getString("image_url"));
        row.put("is_active", rs.getBoolean("is_active"));
        row.put("created_at", rs.getTimestamp("created_at"));
        row.put("updated_at", rs.getTimestamp("updated_at"));

        try {
            row.put("created_by", rs.getObject("created_by"));
        } catch (SQLException ignored) {
            row.put("created_by", null);
        }
        try {
            row.put("updated_by", rs.getObject("updated_by"));
        } catch (SQLException ignored) {
            row.put("updated_by", null);
        }
        try {
            row.put("created_by_name", rs.getString("created_by_name"));
        } catch (SQLException ignored) {
            row.put("created_by_name", null);
        }
        try {
            row.put("updated_by_name", rs.getString("updated_by_name"));
        } catch (SQLException ignored) {
            row.put("updated_by_name", null);
        }
        return row;
    }

    private static void ensureAnnouncementsTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS announcements ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "title VARCHAR(180) NOT NULL, "
                + "content TEXT NOT NULL, "
                + "image_url VARCHAR(500) NULL, "
                + "is_active TINYINT(1) NOT NULL DEFAULT 1, "
                + "created_by INT NULL, "
                + "updated_by INT NULL, "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
                + "INDEX idx_announcements_active_updated (is_active, updated_at), "
                + "INDEX idx_announcements_updated_at (updated_at)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }

        // Backward-compatible migration for older deployments where announcements table exists
        // but misses newer columns required by current CRUD queries.
        ensureAnnouncementColumn(conn, "title", "ALTER TABLE announcements ADD COLUMN title VARCHAR(180) NOT NULL");
        ensureAnnouncementColumn(conn, "content", "ALTER TABLE announcements ADD COLUMN content TEXT NOT NULL");
        ensureAnnouncementColumn(conn, "image_url", "ALTER TABLE announcements ADD COLUMN image_url VARCHAR(500) NULL");
        ensureAnnouncementColumn(conn, "is_active", "ALTER TABLE announcements ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1");
        ensureAnnouncementColumn(conn, "created_by", "ALTER TABLE announcements ADD COLUMN created_by INT NULL");
        ensureAnnouncementColumn(conn, "updated_by", "ALTER TABLE announcements ADD COLUMN updated_by INT NULL");
        ensureAnnouncementColumn(conn, "created_at", "ALTER TABLE announcements ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
        ensureAnnouncementColumn(conn, "updated_at", "ALTER TABLE announcements ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
    }

    private static void ensureAnnouncementColumn(Connection conn, String columnName, String alterSql) throws SQLException {
        if (columnExists(conn, "announcements", columnName)) {
            return;
        }
        try (PreparedStatement stmt = conn.prepareStatement(alterSql)) {
            stmt.execute();
        }
    }

    private static void ensureKppGuestSubmissionTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS kpp_guest_form_submissions ("
                + "id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                + "recipient_email VARCHAR(255) NOT NULL,"
                + "action_type VARCHAR(30) NOT NULL,"
                + "token_hash VARCHAR(128) NOT NULL,"
                + "submitter_email VARCHAR(255) NOT NULL,"
                + "form_payload LONGTEXT NOT NULL,"
                + "source_ip VARCHAR(64),"
                + "archived TINYINT(1) NOT NULL DEFAULT 0,"
                + "archived_at TIMESTAMP NULL,"
                + "submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }

        ensureSubmissionColumn(conn, "archived",
                "ALTER TABLE kpp_guest_form_submissions ADD COLUMN archived TINYINT(1) NOT NULL DEFAULT 0");
        ensureSubmissionColumn(conn, "archived_at",
                "ALTER TABLE kpp_guest_form_submissions ADD COLUMN archived_at TIMESTAMP NULL");
    }

    private static void ensureSubmissionColumn(Connection conn, String columnName, String alterSql) throws SQLException {
        if (columnExists(conn, "kpp_guest_form_submissions", columnName)) {
            return;
        }
        try (PreparedStatement stmt = conn.prepareStatement(alterSql)) {
            stmt.execute();
        }
    }

    private static boolean columnExists(Connection conn, String tableName, String columnName) throws SQLException {
        DatabaseMetaData metaData = conn.getMetaData();
        String catalog = conn.getCatalog();
        try (ResultSet rs = metaData.getColumns(catalog, null, tableName, columnName)) {
            return rs.next();
        }
    }

    // Î“Ã¶Ã‡Î“Ã¶Ã‡ Application status history Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡

    public static void recordStatusHistory(Connection conn, int applicationId, String oldStatus,
            String newStatus, Integer changedBy, String adminNotes) throws SQLException {
        ensureStatusHistoryTable(conn);
        String sql = "INSERT INTO application_status_history "
                + "(application_id, old_status, new_status, changed_by, admin_notes) VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            if (oldStatus == null) stmt.setNull(2, java.sql.Types.VARCHAR);
            else stmt.setString(2, oldStatus);
            stmt.setString(3, newStatus);
            if (changedBy == null) stmt.setNull(4, java.sql.Types.INTEGER);
            else stmt.setInt(4, changedBy);
            if (adminNotes == null) stmt.setNull(5, java.sql.Types.VARCHAR);
            else stmt.setString(5, adminNotes);
            stmt.executeUpdate();
        }
    }

    public static Map<Integer, List<Map<String, Object>>> loadUserApplicationStatusHistory(
            Connection conn, int userId) throws SQLException {
        ensureStatusHistoryTable(conn);
        Map<Integer, List<Map<String, Object>>> historyMap = new java.util.LinkedHashMap<>();
        String sql = "SELECT ash.application_id, ash.old_status, ash.new_status, "
                + "ash.admin_notes, ash.changed_at, u.full_name AS changed_by_name "
                + "FROM application_status_history ash "
                + "JOIN applications a ON a.id = ash.application_id "
                + "LEFT JOIN users u ON u.id = ash.changed_by "
                + "WHERE a.user_id = ? "
                + "ORDER BY ash.application_id ASC, ash.changed_at ASC";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    int appId = rs.getInt("application_id");
                    Map<String, Object> row = new HashMap<>();
                    row.put("old_status", rs.getString("old_status"));
                    row.put("new_status", rs.getString("new_status"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    row.put("changed_at", rs.getTimestamp("changed_at"));
                    row.put("changed_by_name", rs.getString("changed_by_name"));
                    historyMap.computeIfAbsent(appId, k -> new ArrayList<>()).add(row);
                }
            }
        }
        return historyMap;
    }

    private static void ensureStatusHistoryTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS application_status_history ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "application_id INT NOT NULL, "
                + "old_status VARCHAR(20) NULL, "
                + "new_status VARCHAR(20) NOT NULL, "
                + "changed_by INT NULL, "
                + "admin_notes TEXT NULL, "
                + "changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "CONSTRAINT fk_ash_application FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE, "
                + "CONSTRAINT fk_ash_changed_by FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL, "
                + "INDEX idx_ash_application_id (application_id), "
                + "INDEX idx_ash_changed_at (changed_at)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    private static void ensureApplicationStatusColumn(Connection conn) throws SQLException {
        String columnType = getColumnType(conn, "applications", "status");
        if (columnType == null) {
            return;
        }

        String normalizedType = columnType.toUpperCase(Locale.ROOT);
        if (normalizedType.contains("MENUNGGU_TINDAKAN_PENGARAH")
                && normalizedType.contains("MENUNGGU_SETERUSNYA_DILULUSKAN")
                && normalizedType.contains("MENUNGGU_SETERUSNYA_GAGAL")
                && normalizedType.contains("MENUNGGU_SETERUSNYA_GANTUNG")
                && normalizedType.contains("MENUNGGU_SETERUSNYA_BATAL")) {
            return;
        }

        String sql = "ALTER TABLE applications MODIFY status " + APPLICATION_STATUS_ENUM + " NOT NULL DEFAULT 'NEW'";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.executeUpdate();
        }
    }

    private static void ensureStatusHistoryColumnWidths(Connection conn) throws SQLException {
        boolean needsOldStatusResize = needsVarcharResize(conn, "application_status_history", "old_status", 64);
        boolean needsNewStatusResize = needsVarcharResize(conn, "application_status_history", "new_status", 64);

        if (!needsOldStatusResize && !needsNewStatusResize) {
            return;
        }

        StringBuilder sql = new StringBuilder("ALTER TABLE application_status_history ");
        if (needsOldStatusResize) {
            sql.append("MODIFY old_status VARCHAR(64) NULL");
        }
        if (needsNewStatusResize) {
            if (needsOldStatusResize) {
                sql.append(", ");
            }
            sql.append("MODIFY new_status VARCHAR(64) NOT NULL");
        }

        try (PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            stmt.executeUpdate();
        }
    }

    private static boolean needsVarcharResize(Connection conn, String tableName, String columnName, int minimumLength)
            throws SQLException {
        String sql = "SELECT DATA_TYPE, CHARACTER_MAXIMUM_LENGTH "
                + "FROM information_schema.COLUMNS "
                + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, tableName);
            stmt.setString(2, columnName);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                String dataType = rs.getString("DATA_TYPE");
                int maximumLength = rs.getInt("CHARACTER_MAXIMUM_LENGTH");
                return !"varchar".equalsIgnoreCase(dataType) || maximumLength < minimumLength;
            }
        }
    }

    private static String getColumnType(Connection conn, String tableName, String columnName) throws SQLException {
        String sql = "SELECT COLUMN_TYPE FROM information_schema.COLUMNS "
                + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, tableName);
            stmt.setString(2, columnName);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("COLUMN_TYPE");
                }
            }
        }
        return null;
    }

    private static void ensureApplicationArchiveTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS application_archives ("
                + "application_id INT NOT NULL PRIMARY KEY, "
                + "archived_by INT NULL, "
                + "archive_notes VARCHAR(500) NULL, "
                + "archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "CONSTRAINT fk_application_archives_application FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE, "
                + "CONSTRAINT fk_application_archives_archived_by FOREIGN KEY (archived_by) REFERENCES users(id) ON DELETE SET NULL, "
                + "INDEX idx_application_archives_archived_at (archived_at)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    private static int countByQuery(Connection conn, String sql) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    private static String resolveProductTable(Connection conn) throws SQLException {
        if (tableExists(conn, "water_products") && countByQuery(conn, "SELECT COUNT(*) FROM water_products") > 0) {
            return "water_products";
        }
        if (tableExists(conn, "products")) {
            return "products";
        }
        throw new SQLException("Product table not found");
    }

    private static boolean tableExists(Connection conn, String tableName) throws SQLException {
        DatabaseMetaData metaData = conn.getMetaData();
        try (ResultSet rs = metaData.getTables(conn.getCatalog(), null, tableName, null)) {
            return rs.next();
        }
    }

    private static final class QueryParts {
        private final String clause;
        private final List<Object> parameters;

        private QueryParts(String clause, List<Object> parameters) {
            this.clause = clause;
            this.parameters = parameters;
        }
    }

    public static void ensureCertificateColumns(Connection conn) throws SQLException {
        if (!columnExists(conn, "applications", "certificate_number")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE applications ADD COLUMN certificate_number VARCHAR(60) NULL");
            }
        }
        if (!columnExists(conn, "applications", "issued_at")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE applications ADD COLUMN issued_at DATE NULL");
            }
        }
        if (!columnExists(conn, "applications", "valid_until")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE applications ADD COLUMN valid_until DATE NULL");
            }
        }
    }

    public static List<Map<String, Object>> loadUserApplicationsPaged(Connection conn, int userId, int page, int pageSize) throws SQLException {
        ensureCertificateColumns(conn);
        List<Map<String, Object>> applications = new ArrayList<>();
        int offset = (page - 1) * pageSize;
        String sql = "SELECT a.id, a.product_name, a.company_name, a.status, a.submitted_at, a.admin_notes, "
            + "a.certificate_number, a.issued_at, a.valid_until, ad.application_type "
            + "FROM applications a "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "WHERE a.user_id = ? ORDER BY a.created_at DESC LIMIT ? OFFSET ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, pageSize);
            stmt.setInt(3, offset);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("status", rs.getString("status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    row.put("certificate_number", rs.getString("certificate_number"));
                    row.put("issued_at", rs.getDate("issued_at"));
                    row.put("valid_until", rs.getDate("valid_until"));
                    row.put("application_type", rs.getString("application_type"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static List<Map<String, Object>> loadPendingProfileReviews(Connection conn, String search, int limit)
            throws SQLException {
        ensureUserProfileReviewColumns(conn);
        StringBuilder sql = new StringBuilder(
                "SELECT id, username, full_name, email, phone_number, avatar_url, supporting_document_url, profile_review_status, profile_submitted_at, profile_review_notes, status, created_at "
                        + "FROM users WHERE role = 'USER' AND profile_review_status IN ('PENDING_REVIEW', 'REJECTED')");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            sql.append(" AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        sql.append(" ORDER BY COALESCE(profile_submitted_at, created_at) DESC, id DESC");
        if (limit > 0) {
            sql.append(" LIMIT ?");
        }

        List<Map<String, Object>> rows = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            int index = applyParameters(stmt, parameters);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("username", rs.getString("username"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("email", rs.getString("email"));
                    row.put("phone_number", rs.getString("phone_number"));
                    row.put("avatar_url", rs.getString("avatar_url"));
                    row.put("supporting_document_url", rs.getString("supporting_document_url"));
                    row.put("profile_review_status", rs.getString("profile_review_status"));
                    row.put("profile_submitted_at", rs.getTimestamp("profile_submitted_at"));
                    row.put("profile_review_notes", rs.getString("profile_review_notes"));
                    row.put("status", rs.getString("status"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    public static int countPendingProfileReviews(Connection conn) throws SQLException {
        ensureUserProfileReviewColumns(conn);
        return countByQuery(conn,
                "SELECT COUNT(*) FROM users WHERE role = 'USER' AND profile_review_status IN ('PENDING_REVIEW', 'REJECTED')");
    }

    public static List<Map<String, Object>> loadUpdateApplicationsForReview(Connection conn, String search, int limit)
            throws SQLException {
        ensureApplicationArchiveTable(conn);
        ensureCertificateColumns(conn);

        StringBuilder clause = new StringBuilder(
                " WHERE ad.application_type = 'KEMASKINI' AND aa.application_id IS NULL AND a.status IN ('NEW', 'UNDER_REVIEW')");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        String sql = "SELECT a.id, a.company_name, a.product_name, a.product_category, a.product_description, a.status, a.submitted_at, "
                + "a.reviewed_at, a.reviewed_by, a.admin_notes, u.full_name, u.email AS user_email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_phone, ad.supplier_address, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + clause.toString()
                + " ORDER BY COALESCE(a.reviewed_at, a.created_at) DESC";
        if (limit > 0) {
            sql += " LIMIT ?";
        }

        List<Map<String, Object>> rows = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int index = applyParameters(stmt, parameters);
            if (limit > 0) {
                stmt.setInt(index, limit);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("product_category", rs.getString("product_category"));
                    row.put("product_description", rs.getString("product_description"));
                    row.put("status", rs.getString("status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                    row.put("reviewed_by", rs.getObject("reviewed_by"));
                    row.put("admin_notes", rs.getString("admin_notes"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    row.put("application_type", rs.getString("application_type"));
                    row.put("supplier_name", rs.getString("supplier_name"));
                    row.put("supplier_phone", rs.getString("supplier_phone"));
                    row.put("supplier_address", rs.getString("supplier_address"));
                    row.put("manufacturer_name", rs.getString("manufacturer_name"));
                    row.put("manufacturer_address", rs.getString("manufacturer_address"));
                    row.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    row.put("principal_name", rs.getString("principal_name"));
                    row.put("principal_address", rs.getString("principal_address"));
                    row.put("principal_phone", rs.getString("principal_phone"));
                    row.put("standard_name", rs.getString("standard_name"));
                    row.put("certification_license", rs.getString("certification_license"));
                    row.put("certification_valid_until", rs.getDate("certification_valid_until"));
                    row.put("test_report_reference", rs.getString("test_report_reference"));
                    row.put("test_report_date", rs.getDate("test_report_date"));
                    row.put("warranty_years", rs.getBigDecimal("warranty_years"));
                    row.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    row.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    row.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    public static int countUpdateApplicationsForReview(Connection conn) throws SQLException {
        ensureApplicationArchiveTable(conn);
        ensureCertificateColumns(conn);
        String sql = "SELECT COUNT(*) FROM applications a "
                + "JOIN application_details ad ON ad.application_id = a.id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + "WHERE ad.application_type = 'KEMASKINI' AND aa.application_id IS NULL AND a.status IN ('NEW', 'UNDER_REVIEW')";
        return countByQuery(conn, sql);
    }

    public static void updateUserProfileReviewStatus(Connection conn, int userId, String status,
                                                     Integer reviewedBy, String reviewNotes) throws SQLException {
        ensureUserProfileReviewColumns(conn);
        String sql = "UPDATE users SET profile_review_status = ?, profile_submitted_at = COALESCE(profile_submitted_at, CURRENT_TIMESTAMP), "
                + "profile_reviewed_at = CURRENT_TIMESTAMP, profile_reviewed_by = ?, profile_review_notes = ? WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            if (reviewedBy == null) {
                stmt.setNull(2, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(2, reviewedBy);
            }
            if (reviewNotes == null || reviewNotes.isBlank()) {
                stmt.setNull(3, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(3, reviewNotes);
            }
            stmt.setInt(4, userId);
            stmt.executeUpdate();
        }
    }

    public static void markUserProfileSubmitted(Connection conn, int userId) throws SQLException {
        ensureUserProfileReviewColumns(conn);
        String sql = "UPDATE users SET profile_review_status = 'PENDING_REVIEW', profile_submitted_at = CURRENT_TIMESTAMP, "
                + "profile_reviewed_at = NULL, profile_reviewed_by = NULL, profile_review_notes = NULL WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.executeUpdate();
        }
    }

    private static void ensureUserProfileReviewColumns(Connection conn) throws SQLException {
        if (!columnExists(conn, "users", "supporting_document_url")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN supporting_document_url VARCHAR(255) NULL AFTER avatar_url");
            }
        }
        if (!columnExists(conn, "users", "profile_review_status")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN profile_review_status ENUM('DRAFT','PENDING_REVIEW','APPROVED','REJECTED') NOT NULL DEFAULT 'DRAFT' AFTER supporting_document_url");
            }
        }
        if (!columnExists(conn, "users", "profile_submitted_at")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN profile_submitted_at TIMESTAMP NULL AFTER profile_review_status");
            }
        }
        if (!columnExists(conn, "users", "profile_reviewed_at")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN profile_reviewed_at TIMESTAMP NULL AFTER profile_submitted_at");
            }
        }
        if (!columnExists(conn, "users", "profile_reviewed_by")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN profile_reviewed_by INT NULL AFTER profile_reviewed_at");
            }
        }
        if (!columnExists(conn, "users", "profile_review_notes")) {
            try (java.sql.Statement stmt = conn.createStatement()) {
                stmt.execute("ALTER TABLE users ADD COLUMN profile_review_notes TEXT NULL AFTER profile_reviewed_by");
            }
        }
    }

    public static List<Map<String, Object>> loadAdminRecipients(Connection conn) throws SQLException {
        List<Map<String, Object>> recipients = new ArrayList<>();
        String sql = "SELECT id, full_name, username, email FROM users WHERE role = 'ADMIN' AND status = 'ACTIVE' ORDER BY role_seq ASC, id ASC";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("full_name", rs.getString("full_name"));
                row.put("username", rs.getString("username"));
                row.put("email", rs.getString("email"));
                recipients.add(row);
            }
        }
        return recipients;
    }

    // Î“Ã¶Ã‡Î“Ã¶Ã‡ Presentation invitations Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡

    public static long createPresentationInvite(Connection conn,
            int applicationId,
            int userId,
            Integer invitedBy,
            String presentationDate,
            String presentationTime,
            String presentationVenue,
            String applicantMemo,
            String kppEmails,
            String kppMemo,
            boolean rescheduled,
            Long replacesInviteId) throws SQLException {
        ensurePresentationInviteTable(conn);

        if (replacesInviteId != null) {
            try (PreparedStatement closeStmt = conn.prepareStatement(
                    "UPDATE presentation_invites SET is_active = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?")) {
                closeStmt.setLong(1, replacesInviteId);
                closeStmt.executeUpdate();
            }
        }

        if (replacesInviteId == null) {
            try (PreparedStatement closeByAppStmt = conn.prepareStatement(
                    "UPDATE presentation_invites SET is_active = 0, updated_at = CURRENT_TIMESTAMP WHERE application_id = ? AND is_active = 1")) {
                closeByAppStmt.setInt(1, applicationId);
                closeByAppStmt.executeUpdate();
            }
        }

        String sql = "INSERT INTO presentation_invites ("
                + "application_id, user_id, invited_by, presentation_date, presentation_time, presentation_venue, "
                + "applicant_memo, kpp_emails, kpp_memo, invite_status, applicant_response, reschedule_count, is_active"
                + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, 1)";

        try (PreparedStatement stmt = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, applicationId);
            stmt.setInt(2, userId);
            if (invitedBy == null) {
                stmt.setNull(3, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(3, invitedBy);
            }
            stmt.setString(4, presentationDate);
            stmt.setString(5, presentationTime);
            stmt.setString(6, presentationVenue);
            stmt.setString(7, applicantMemo);
            stmt.setString(8, kppEmails);
            stmt.setString(9, kppMemo);
            stmt.setString(10, "MENUNGGU_MAKLUM_BALAS");
            stmt.setInt(11, rescheduled ? 1 : 0);
            stmt.executeUpdate();

            try (ResultSet rs = stmt.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }

        return 0L;
    }

    public static Map<String, Object> loadLatestActivePresentationInviteByUser(Connection conn, int userId) throws SQLException {
        ensurePresentationInviteTable(conn);
        String sql = "SELECT pi.id, pi.application_id, pi.user_id, pi.presentation_date, pi.presentation_time, pi.presentation_venue, "
                + "pi.applicant_memo, pi.kpp_emails, pi.kpp_memo, pi.invite_status, pi.applicant_response, pi.applicant_rep_name, "
                + "pi.applicant_attendee_count, pi.applicant_absence_reason, pi.reschedule_count, pi.responded_at, pi.created_at, pi.updated_at, "
                + "a.product_name, a.company_name "
                + "FROM presentation_invites pi "
                + "JOIN applications a ON a.id = pi.application_id "
                + "WHERE pi.user_id = ? AND pi.is_active = 1 "
                + "ORDER BY pi.updated_at DESC, pi.id DESC LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("application_id", rs.getInt("application_id"));
                    row.put("user_id", rs.getInt("user_id"));
                    row.put("presentation_date", rs.getString("presentation_date"));
                    row.put("presentation_time", rs.getString("presentation_time"));
                    row.put("presentation_venue", rs.getString("presentation_venue"));
                    row.put("applicant_memo", rs.getString("applicant_memo"));
                    row.put("kpp_emails", rs.getString("kpp_emails"));
                    row.put("kpp_memo", rs.getString("kpp_memo"));
                    row.put("invite_status", rs.getString("invite_status"));
                    row.put("applicant_response", rs.getString("applicant_response"));
                    row.put("applicant_rep_name", rs.getString("applicant_rep_name"));
                    row.put("applicant_attendee_count", rs.getObject("applicant_attendee_count"));
                    row.put("applicant_absence_reason", rs.getString("applicant_absence_reason"));
                    row.put("reschedule_count", rs.getInt("reschedule_count"));
                    row.put("responded_at", rs.getTimestamp("responded_at"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("updated_at", rs.getTimestamp("updated_at"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    return row;
                }
            }
        }
        return null;
    }

    public static int countPendingPresentationInvitesByUser(Connection conn, int userId) throws SQLException {
        ensurePresentationInviteTable(conn);
        String sql = "SELECT COUNT(*) FROM presentation_invites "
                + "WHERE user_id = ? AND is_active = 1 AND invite_status IN ('MENUNGGU_MAKLUM_BALAS', 'MENUNGGU_PENJADUALAN_SEMULA')";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<Map<String, Object>> loadPresentationInviteHistoryByUser(Connection conn, int userId, int limit) throws SQLException {
        ensurePresentationInviteTable(conn);
        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT pi.id, pi.application_id, pi.user_id, pi.presentation_date, pi.presentation_time, pi.presentation_venue, "
                + "pi.applicant_memo, pi.kpp_emails, pi.kpp_memo, pi.invite_status, pi.applicant_response, pi.applicant_rep_name, "
                + "pi.applicant_attendee_count, pi.applicant_absence_reason, pi.reschedule_count, pi.responded_at, pi.created_at, pi.updated_at, "
                + "a.product_name, a.company_name "
                + "FROM presentation_invites pi "
                + "JOIN applications a ON a.id = pi.application_id "
                + "WHERE pi.user_id = ? "
                + "ORDER BY pi.updated_at DESC, pi.id DESC "
                + "LIMIT ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, Math.max(1, limit));
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("application_id", rs.getInt("application_id"));
                    row.put("user_id", rs.getInt("user_id"));
                    row.put("presentation_date", rs.getString("presentation_date"));
                    row.put("presentation_time", rs.getString("presentation_time"));
                    row.put("presentation_venue", rs.getString("presentation_venue"));
                    row.put("applicant_memo", rs.getString("applicant_memo"));
                    row.put("kpp_emails", rs.getString("kpp_emails"));
                    row.put("kpp_memo", rs.getString("kpp_memo"));
                    row.put("invite_status", rs.getString("invite_status"));
                    row.put("applicant_response", rs.getString("applicant_response"));
                    row.put("applicant_rep_name", rs.getString("applicant_rep_name"));
                    row.put("applicant_attendee_count", rs.getObject("applicant_attendee_count"));
                    row.put("applicant_absence_reason", rs.getString("applicant_absence_reason"));
                    row.put("reschedule_count", rs.getInt("reschedule_count"));
                    row.put("responded_at", rs.getTimestamp("responded_at"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("updated_at", rs.getTimestamp("updated_at"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    public static boolean respondToPresentationInvite(Connection conn,
            long inviteId,
            int userId,
            String response,
            String representativeName,
            Integer attendeeCount,
            String absenceReason) throws SQLException {
        ensurePresentationInviteTable(conn);
        String normalizedResponse = response == null ? "" : response.trim().toUpperCase(Locale.ROOT);
        String status;
        if ("HADIR".equals(normalizedResponse)) {
            status = "HADIR";
        } else if ("TIDAK_HADIR".equals(normalizedResponse)) {
            status = "TIDAK_HADIR";
        } else {
            return false;
        }

        String sql = "UPDATE presentation_invites SET invite_status = ?, applicant_response = ?, "
                + "applicant_rep_name = ?, applicant_attendee_count = ?, applicant_absence_reason = ?, "
                + "responded_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP "
                + "WHERE id = ? AND user_id = ? AND is_active = 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, normalizedResponse);
            stmt.setString(3, representativeName);
            if (attendeeCount == null) {
                stmt.setNull(4, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(4, attendeeCount);
            }
            stmt.setString(5, absenceReason);
            stmt.setLong(6, inviteId);
            stmt.setInt(7, userId);
            return stmt.executeUpdate() > 0;
        }
    }

    public static List<Map<String, Object>> loadPresentationInvitesForAdmin(Connection conn, int limit) throws SQLException {
        ensurePresentationInviteTable(conn);
        List<Map<String, Object>> rows = new ArrayList<>();
        String sql = "SELECT pi.id, pi.application_id, pi.user_id, pi.presentation_date, pi.presentation_time, pi.presentation_venue, "
                + "pi.applicant_memo, pi.kpp_emails, pi.kpp_memo, pi.invite_status, pi.applicant_response, pi.applicant_rep_name, "
                + "pi.applicant_attendee_count, pi.applicant_absence_reason, pi.reschedule_count, pi.responded_at, pi.created_at, pi.updated_at, "
                + "a.product_name, a.company_name, u.full_name AS applicant_name, u.email AS applicant_email "
                + "FROM presentation_invites pi "
                + "JOIN applications a ON a.id = pi.application_id "
                + "JOIN users u ON u.id = pi.user_id "
                + "ORDER BY pi.updated_at DESC, pi.id DESC "
                + "LIMIT ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, Math.max(1, limit));
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("application_id", rs.getInt("application_id"));
                    row.put("user_id", rs.getInt("user_id"));
                    row.put("presentation_date", rs.getString("presentation_date"));
                    row.put("presentation_time", rs.getString("presentation_time"));
                    row.put("presentation_venue", rs.getString("presentation_venue"));
                    row.put("applicant_memo", rs.getString("applicant_memo"));
                    row.put("kpp_emails", rs.getString("kpp_emails"));
                    row.put("kpp_memo", rs.getString("kpp_memo"));
                    row.put("invite_status", rs.getString("invite_status"));
                    row.put("applicant_response", rs.getString("applicant_response"));
                    row.put("applicant_rep_name", rs.getString("applicant_rep_name"));
                    row.put("applicant_attendee_count", rs.getObject("applicant_attendee_count"));
                    row.put("applicant_absence_reason", rs.getString("applicant_absence_reason"));
                    row.put("reschedule_count", rs.getInt("reschedule_count"));
                    row.put("responded_at", rs.getTimestamp("responded_at"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("updated_at", rs.getTimestamp("updated_at"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("applicant_name", rs.getString("applicant_name"));
                    row.put("applicant_email", rs.getString("applicant_email"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    public static Map<String, Object> loadPresentationInviteById(Connection conn, long inviteId) throws SQLException {
        ensurePresentationInviteTable(conn);
        String sql = "SELECT id, application_id, user_id, invited_by, presentation_date, presentation_time, presentation_venue, "
                + "applicant_memo, kpp_emails, kpp_memo, invite_status, applicant_response, applicant_rep_name, "
                + "applicant_attendee_count, applicant_absence_reason, reschedule_count, is_active, responded_at, created_at, updated_at "
                + "FROM presentation_invites WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, inviteId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("application_id", rs.getInt("application_id"));
                    row.put("user_id", rs.getInt("user_id"));
                    row.put("invited_by", rs.getObject("invited_by"));
                    row.put("presentation_date", rs.getString("presentation_date"));
                    row.put("presentation_time", rs.getString("presentation_time"));
                    row.put("presentation_venue", rs.getString("presentation_venue"));
                    row.put("applicant_memo", rs.getString("applicant_memo"));
                    row.put("kpp_emails", rs.getString("kpp_emails"));
                    row.put("kpp_memo", rs.getString("kpp_memo"));
                    row.put("invite_status", rs.getString("invite_status"));
                    row.put("applicant_response", rs.getString("applicant_response"));
                    row.put("applicant_rep_name", rs.getString("applicant_rep_name"));
                    row.put("applicant_attendee_count", rs.getObject("applicant_attendee_count"));
                    row.put("applicant_absence_reason", rs.getString("applicant_absence_reason"));
                    row.put("reschedule_count", rs.getInt("reschedule_count"));
                    row.put("is_active", rs.getInt("is_active"));
                    row.put("responded_at", rs.getTimestamp("responded_at"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    row.put("updated_at", rs.getTimestamp("updated_at"));
                    return row;
                }
            }
        }
        return null;
    }

    private static void ensurePresentationInviteTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS presentation_invites ("
                + "id BIGINT AUTO_INCREMENT PRIMARY KEY, "
                + "application_id INT NOT NULL, "
                + "user_id INT NOT NULL, "
                + "invited_by INT NULL, "
                + "presentation_date DATE NOT NULL, "
                + "presentation_time VARCHAR(10) NOT NULL, "
                + "presentation_venue VARCHAR(255) NOT NULL, "
                + "applicant_memo TEXT NULL, "
                + "kpp_emails TEXT NULL, "
                + "kpp_memo TEXT NULL, "
                + "invite_status VARCHAR(50) NOT NULL DEFAULT 'MENUNGGU_MAKLUM_BALAS', "
                + "applicant_response VARCHAR(30) NULL, "
                + "applicant_rep_name VARCHAR(180) NULL, "
                + "applicant_attendee_count INT NULL, "
                + "applicant_absence_reason TEXT NULL, "
                + "reschedule_count INT NOT NULL DEFAULT 0, "
                + "is_active TINYINT(1) NOT NULL DEFAULT 1, "
                + "responded_at TIMESTAMP NULL, "
                + "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
                + "updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
                + "INDEX idx_presentation_invites_user (user_id, is_active), "
                + "INDEX idx_presentation_invites_app (application_id), "
                + "INDEX idx_presentation_invites_status (invite_status), "
                + "CONSTRAINT fk_presentation_invites_app FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE, "
                + "CONSTRAINT fk_presentation_invites_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE, "
                + "CONSTRAINT fk_presentation_invites_admin FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    // Î“Ã¶Ã‡Î“Ã¶Ã‡ In-system notifications Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡

    public static void insertNotification(Connection conn, int userId, String message, String type) throws SQLException {
        ensureNotificationsTable(conn);
        String sql = "INSERT INTO notifications (user_id, message, type) VALUES (?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, message);
            stmt.setString(3, type);
            stmt.executeUpdate();
        }
    }

    public static List<Map<String, Object>> loadUserNotifications(Connection conn, int userId, int limit) throws SQLException {
        ensureNotificationsTable(conn);
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT id, message, type, is_read, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("message", rs.getString("message"));
                    row.put("type", rs.getString("type"));
                    row.put("is_read", rs.getInt("is_read"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    list.add(row);
                }
            }
        }
        return list;
    }

    public static Map<String, Object> loadLatestUnreadNotificationByType(Connection conn, int userId, String type) throws SQLException {
        ensureNotificationsTable(conn);
        String sql = "SELECT id, message, type, created_at FROM notifications "
                + "WHERE user_id = ? AND is_read = 0 AND type = ? ORDER BY created_at DESC LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, type);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("message", rs.getString("message"));
                    row.put("type", rs.getString("type"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    return row;
                }
            }
        }
        return null;
    }

    public static Map<String, Object> loadLatestUnreadDecisionNotification(Connection conn, int userId) throws SQLException {
        ensureNotificationsTable(conn);
        String sql = "SELECT id, message, type, created_at FROM notifications "
                + "WHERE user_id = ? AND is_read = 0 AND UPPER(type) IN ('SUCCESS','ERROR','WARNING') "
                + "ORDER BY created_at DESC LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("message", rs.getString("message"));
                    row.put("type", rs.getString("type"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    return row;
                }
            }
        }
        return null;
    }

    public static int countUnreadNotifications(Connection conn, int userId) throws SQLException {
        ensureNotificationsTable(conn);
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0")) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static void markAllNotificationsRead(Connection conn, int userId) throws SQLException {
        ensureNotificationsTable(conn);
        try (PreparedStatement stmt = conn.prepareStatement(
                "UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0")) {
            stmt.setInt(1, userId);
            stmt.executeUpdate();
        }
    }

    private static void ensureNotificationsTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS notifications ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "user_id INT NOT NULL, "
                + "message VARCHAR(500) NOT NULL, "
                + "type VARCHAR(20) DEFAULT 'INFO', "
                + "is_read TINYINT(1) DEFAULT 0, "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "INDEX idx_notif_user (user_id, is_read)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    // Î“Ã¶Ã‡Î“Ã¶Ã‡ Email verification tokens Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡Î“Ã¶Ã‡

    public static void storeVerificationToken(Connection conn, int userId, String token, Timestamp expiresAt) throws SQLException {
        ensureVerificationTokensTable(conn);
        String sql = "INSERT INTO verification_tokens (user_id, token, expires_at) VALUES (?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE token = VALUES(token), expires_at = VALUES(expires_at), created_at = CURRENT_TIMESTAMP";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, token);
            stmt.setTimestamp(3, expiresAt);
            stmt.executeUpdate();
        }
    }

    public static Map<String, Object> findVerificationToken(Connection conn, String token) throws SQLException {
        ensureVerificationTokensTable(conn);
        String sql = "SELECT user_id, token, expires_at FROM verification_tokens WHERE token = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, token);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("user_id", rs.getInt("user_id"));
                    row.put("token", rs.getString("token"));
                    row.put("expires_at", rs.getTimestamp("expires_at"));
                    return row;
                }
            }
        }
        return null;
    }

    public static void deleteVerificationToken(Connection conn, String token) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "DELETE FROM verification_tokens WHERE token = ?")) {
            stmt.setString(1, token);
            stmt.executeUpdate();
        }
    }

    public static void activateUser(Connection conn, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "UPDATE users SET status = 'ACTIVE' WHERE id = ? AND status = 'INACTIVE'")) {
            stmt.setInt(1, userId);
            stmt.executeUpdate();
        }
    }

    private static void ensureVerificationTokensTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS verification_tokens ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "user_id INT NOT NULL UNIQUE, "
                + "token VARCHAR(64) NOT NULL UNIQUE, "
                + "expires_at TIMESTAMP NOT NULL, "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "INDEX idx_vtoken (token)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }
}


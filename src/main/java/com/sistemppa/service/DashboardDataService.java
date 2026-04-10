package com.sistemppa.service;

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

public final class DashboardDataService {
    private DashboardDataService() {
    }

    public static Map<String, Integer> loadAdminStats(Connection conn) throws SQLException {
        ensureApplicationArchiveTable(conn);

        Map<String, Integer> stats = new HashMap<>();

        String sql = "SELECT "
                + "COUNT(CASE WHEN aa.application_id IS NULL THEN 1 END) AS total_applications, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'SUSPENDED' THEN 1 ELSE 0 END) AS suspended_count, "
                + "SUM(CASE WHEN aa.application_id IS NULL AND a.status = 'DRAFT' THEN 1 ELSE 0 END) AS draft_count, "
                + "SUM(CASE WHEN aa.application_id IS NOT NULL THEN 1 ELSE 0 END) AS archived_count "
                + "FROM applications a "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("total_applications", rs.getInt("total_applications"));
                stats.put("pending_count", rs.getInt("pending_count"));
                stats.put("approved_count", rs.getInt("approved_count"));
                stats.put("rejected_count", rs.getInt("rejected_count"));
                stats.put("suspended_count", rs.getInt("suspended_count"));
                stats.put("draft_count", rs.getInt("draft_count"));
                stats.put("archived_count", rs.getInt("archived_count"));
            }
        }

        stats.put("active_users", countByQuery(conn,
                "SELECT COUNT(*) FROM users WHERE status = 'ACTIVE'"));
        stats.put("registered_users", countRegisteredUsers(conn, false));
        stats.put("new_registered_users", countRegisteredUsers(conn, true));
        stats.put("total_products", countProducts(conn, null, null));
        return stats;
    }

    public static List<Map<String, Object>> loadRegisteredUsers(Connection conn, String search,
                                                                 boolean onlyNew, int limit) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT id, username, full_name, email, status, created_at "
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
        Map<String, Object> user = new HashMap<>();
        String sql = "SELECT username, full_name, email, avatar_url, status, created_at "
                + "FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    user.put("username", rs.getString("username"));
                    user.put("full_name", rs.getString("full_name"));
                    user.put("email", rs.getString("email"));
                    user.put("avatar_url", rs.getString("avatar_url"));
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
                "SELECT COUNT(*) FROM applications WHERE user_id = ? AND status = 'PENDING'")) {
            stmt.setInt(1, userId);
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
        String sql = "SELECT a.id, a.company_name, a.product_category, a.product_name, "
            + "CASE WHEN aa.application_id IS NOT NULL THEN 'ARCHIVED' ELSE a.status END AS display_status, "
            + "a.submitted_at, "
                + "u.full_name, u.email AS user_email "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + queryParts.clause
                + " ORDER BY a.created_at DESC";
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
                    row.put("product_category", rs.getString("product_category"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("status", rs.getString("display_status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static int countApplications(Connection conn, String search, String status,
            String dateFrom, String dateTo) throws SQLException {
        ensureApplicationArchiveTable(conn);

        QueryParts queryParts = buildApplicationFilter(search, status, dateFrom, dateTo);
        String sql = "SELECT COUNT(*) FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
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

    private static String normalizeApplicationStatusFilter(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }

        String normalized = status.trim().toUpperCase(Locale.ROOT);
        if ("ARCHIVED".equals(normalized)
                || "PENDING".equals(normalized)
                || "APPROVED".equals(normalized)
                || "REJECTED".equals(normalized)
                || "SUSPENDED".equals(normalized)
                || "DRAFT".equals(normalized)) {
            return normalized;
        }
        return null;
    }

    private static QueryParts buildProductFilter(String search, String productType) {
        StringBuilder clause = new StringBuilder(" WHERE 1=1");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (product_materials LIKE ? OR supplier_agent LIKE ? OR brand LIKE ? OR classification LIKE ? "
                    + "OR DATE_FORMAT(supplier_valid_until, '%d-%m-%Y') LIKE ? OR DATE_FORMAT(supplier_valid_until, '%Y-%m-%d') LIKE ?)");
            String keyword = "%" + search.trim() + "%";
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

    private static boolean columnExists(Connection conn, String tableName, String columnName) throws SQLException {
        DatabaseMetaData metaData = conn.getMetaData();
        String catalog = conn.getCatalog();
        try (ResultSet rs = metaData.getColumns(catalog, null, tableName, columnName)) {
            return rs.next();
        }
    }

    // ── Application status history ─────────────────────────────────────────────

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
        String sql = "SELECT id, product_name, company_name, status, submitted_at, admin_notes, "
                + "certificate_number, issued_at, valid_until "
                + "FROM applications WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?";
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
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    // ── In-system notifications ────────────────────────────────────────────────

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

    // ── Email verification tokens ──────────────────────────────────────────────

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

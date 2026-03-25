package com.sistemppa.service;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class DashboardDataService {
    private DashboardDataService() {
    }

    public static Map<String, Integer> loadAdminStats(Connection conn) throws SQLException {
        Map<String, Integer> stats = new HashMap<>();

        String sql = "SELECT "
                + "COUNT(*) AS total_applications, "
                + "SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_count, "
                + "SUM(CASE WHEN status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_count "
                + "FROM applications";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("total_applications", rs.getInt("total_applications"));
                stats.put("pending_count", rs.getInt("pending_count"));
                stats.put("approved_count", rs.getInt("approved_count"));
                stats.put("rejected_count", rs.getInt("rejected_count"));
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

    public static List<Map<String, Object>> loadApplications(Connection conn, String search, String status, int limit)
            throws SQLException {
        QueryParts queryParts = buildApplicationFilter(search, status);
        String sql = "SELECT a.id, a.company_name, a.product_category, a.product_name, a.status, a.submitted_at, "
                + "u.full_name, u.email AS user_email "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
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
                    row.put("status", rs.getString("status"));
                    row.put("submitted_at", rs.getTimestamp("submitted_at"));
                    row.put("full_name", rs.getString("full_name"));
                    row.put("user_email", rs.getString("user_email"));
                    applications.add(row);
                }
            }
        }
        return applications;
    }

    public static int countApplications(Connection conn, String search, String status) throws SQLException {
        QueryParts queryParts = buildApplicationFilter(search, status);
        String sql = "SELECT COUNT(*) FROM applications a JOIN users u ON u.id = a.user_id" + queryParts.clause;
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

    private static QueryParts buildApplicationFilter(String search, String status) {
        StringBuilder clause = new StringBuilder(" WHERE 1=1");
        List<Object> parameters = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            clause.append(" AND (a.company_name LIKE ? OR a.product_name LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
            parameters.add(keyword);
        }

        if (status != null && !status.isBlank()) {
            clause.append(" AND a.status = ?");
            parameters.add(status.trim().toUpperCase());
        }

        return new QueryParts(clause.toString(), parameters);
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
}

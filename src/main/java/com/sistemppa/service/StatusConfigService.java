package com.sistemppa.service;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas StatusConfigService.
 * Dipanggil oleh servlet untuk proses logik bisnes.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Manages editable application status configuration (display labels, badge colours).
 * The internal status_key matches the applications.status enum values.
 */
public class StatusConfigService {

    private static final Logger LOGGER = Logger.getLogger(StatusConfigService.class.getName());

    // -------------------------------------------------------------------------
    // Data holder
    // -------------------------------------------------------------------------

    public static final class StatusConfig {
        public final int id;
        public final String key;
        public final String displayLabel;
        public final String bgColor;
        public final String textColor;
        public final String description;
        public final int sortOrder;

        public StatusConfig(int id, String key, String displayLabel,
                String bgColor, String textColor, String description, int sortOrder) {
            this.id = id;
            this.key = key;
            this.displayLabel = displayLabel;
            this.bgColor = bgColor;
            this.textColor = textColor;
            this.description = description;
            this.sortOrder = sortOrder;
        }
    }

    // -------------------------------------------------------------------------
    // Schema self-healing
    // -------------------------------------------------------------------------

    public static void ensureStatusConfigTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS application_status_config ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "status_key VARCHAR(100) NOT NULL,"
                + "display_label VARCHAR(200) NOT NULL,"
                + "badge_bg_color VARCHAR(30) NOT NULL DEFAULT '#e0f2fe',"
                + "badge_text_color VARCHAR(30) NOT NULL DEFAULT '#0369a1',"
                + "description VARCHAR(500) NULL,"
                + "sort_order INT NOT NULL DEFAULT 99,"
                + "is_active TINYINT(1) NOT NULL DEFAULT 1,"
                + "updated_by INT NULL,"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_status_key (status_key),"
                + "INDEX idx_status_active (is_active),"
                + "INDEX idx_status_sort (sort_order)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement ps = conn.prepareStatement(ddl)) {
            ps.execute();
        }
    }

    // -------------------------------------------------------------------------
    // Load
    // -------------------------------------------------------------------------

    /** Returns all configs ordered by sort_order. */
    public static List<StatusConfig> loadAll(Connection conn) throws SQLException {
        List<StatusConfig> list = new ArrayList<>();
        String sql = "SELECT id, status_key, display_label, badge_bg_color, badge_text_color, "
                + "description, sort_order FROM application_status_config "
                + "WHERE is_active = 1 ORDER BY sort_order ASC, id ASC";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new StatusConfig(
                        rs.getInt("id"),
                        rs.getString("status_key"),
                        rs.getString("display_label"),
                        rs.getString("badge_bg_color"),
                        rs.getString("badge_text_color"),
                        rs.getString("description"),
                        rs.getInt("sort_order")));
            }
        }
        return list;
    }

    /**
     * Returns a map of status_key â†’ display_label for fast JSP lookup.
     * Keys are stored UPPER_CASE.
     */
    public static Map<String, String> loadLabelMap(Connection conn) throws SQLException {
        Map<String, String> map = new LinkedHashMap<>();
        for (StatusConfig sc : loadAll(conn)) {
            map.put(sc.key.toUpperCase(java.util.Locale.ROOT), sc.displayLabel);
        }
        return map;
    }

    /**
     * Returns a map of status_key â†’ StatusConfig for badge colour lookup.
     */
    public static Map<String, StatusConfig> loadConfigMap(Connection conn) throws SQLException {
        Map<String, StatusConfig> map = new LinkedHashMap<>();
        for (StatusConfig sc : loadAll(conn)) {
            map.put(sc.key.toUpperCase(java.util.Locale.ROOT), sc);
        }
        return map;
    }

    // -------------------------------------------------------------------------
    // Save
    // -------------------------------------------------------------------------

    public static void saveStatusConfig(Connection conn, String key, String displayLabel,
            String bgColor, String textColor, String description,
            int sortOrder, Integer updatedBy) throws SQLException {
        String sql = "INSERT INTO application_status_config "
                + "(status_key, display_label, badge_bg_color, badge_text_color, description, sort_order, updated_by) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE "
                + "display_label = VALUES(display_label), "
                + "badge_bg_color = VALUES(badge_bg_color), "
                + "badge_text_color = VALUES(badge_text_color), "
                + "description = VALUES(description), "
                + "sort_order = VALUES(sort_order), "
                + "updated_by = VALUES(updated_by)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key.toUpperCase(java.util.Locale.ROOT));
            ps.setString(2, displayLabel);
            ps.setString(3, bgColor);
            ps.setString(4, textColor);
            ps.setString(5, description);
            ps.setInt(6, sortOrder);
            if (updatedBy == null) ps.setNull(7, java.sql.Types.INTEGER);
            else ps.setInt(7, updatedBy);
            ps.executeUpdate();
        }
    }

    // -------------------------------------------------------------------------
    // Convenience resolver â€” resolves label with DB fallback to hardcoded
    // -------------------------------------------------------------------------

    /**
     * Resolves the display label for a status key.
     * Checks the provided map first; falls back to the hardcoded default.
     */
    public static String resolveLabel(String statusKey, Map<String, String> labelMap) {
        if (statusKey == null) return "";
        String normalized = statusKey.trim().toUpperCase(java.util.Locale.ROOT);
        if (labelMap != null) {
            String fromDb = labelMap.get(normalized);
            if (fromDb != null && !fromDb.isBlank()) {
                return fromDb;
            }
        }
        return hardcodedLabel(normalized);
    }

    private static String hardcodedLabel(String normalized) {
        if ("APPROVED".equals(normalized) || "DILULUSKAN".equals(normalized)) return "DILULUSKAN";
        if ("REJECTED".equals(normalized) || "DITOLAK".equals(normalized))   return "DITOLAK";
        if ("SUSPENDED".equals(normalized) || "DIGANTUNG".equals(normalized)) return "DIGANTUNG";
        if ("DRAFT".equals(normalized) || "DRAF".equals(normalized))          return "DRAF";
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized))    return "DIARKIB";
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized)
                || "DALAM SEMAKAN".equals(normalized))                         return "PERMOHONAN DITERIMA";
        if ("MENUNGGU_TINDAKAN_PENGARAH".equals(normalized))                   return "MENUNGGU TINDAKAN PENGARAH";
        if (normalized.startsWith("MENUNGGU_SETERUSNYA_"))                     return "MENUNGGU SETERUSNYA";
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized)
                || "DALAM PROSES".equals(normalized))                          return "DALAM PROSES";
        if ("NEW".equals(normalized))                                          return "BAHARU";
        return normalized.replace('_', ' ');
    }
}


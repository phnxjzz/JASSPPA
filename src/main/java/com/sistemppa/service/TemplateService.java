package com.sistemppa.service;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas TemplateService.
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
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Manages editable email and notification templates stored in the database.
 * Falls back to a supplied default if the DB template is missing or inactive.
 */
public class TemplateService {

    private static final Logger LOGGER = Logger.getLogger(TemplateService.class.getName());
    private static final Pattern CURLY_PLACEHOLDER_PATTERN = Pattern.compile("\\{\\{\\s*([^{}]+?)\\s*\\}\\}");
    private static final Pattern BRACKET_PLACEHOLDER_PATTERN = Pattern.compile("\\[\\s*([^\\[\\]]+?)\\s*\\]");
    private static final Map<String, String> PLACEHOLDER_ALIASES = buildPlaceholderAliases();

    private static Map<String, String> buildPlaceholderAliases() {
        Map<String, String> aliases = new LinkedHashMap<>();

        // Common Malay labels used by admins.
        aliases.put("nama", "full_name");
        aliases.put("nama penuh", "full_name");
        aliases.put("nama pemohon", "applicant_name");
        aliases.put("email", "user_email");
        aliases.put("emel", "user_email");
        aliases.put("no rujukan", "app_ref");
        aliases.put("rujukan", "app_ref");
        aliases.put("no rujukan surat", "no_rujukan_surat");
        aliases.put("tarikh", "tarikh_surat");
        aliases.put("tarikh surat", "tarikh_surat");
        aliases.put("nama produk", "product_name");
        aliases.put("jenama", "brand");
        aliases.put("catatan", "admin_notes");
        aliases.put("status", "status");
        aliases.put("no sijil", "cert_ref");
        aliases.put("no perakuan", "cert_ref");
        aliases.put("pautan", "link");
        aliases.put("pautan semakan", "verify_url");

        return aliases;
    }

    // -------------------------------------------------------------------------
    // Public data holders
    // -------------------------------------------------------------------------

    public static final class EmailTemplate {
        public final int id;
        public final String key;
        public final String name;
        public final String subject;
        public final String body;
        public final String description;
        public final String variables;

        public EmailTemplate(int id, String key, String name, String subject, String body, String description, String variables) {
            this.id = id;
            this.key = key;
            this.name = name;
            this.subject = subject;
            this.body = body;
            this.description = description;
            this.variables = variables;
        }
    }

    public static final class NotifTemplate {
        public final int id;
        public final String key;
        public final String name;
        public final String message;
        public final String description;
        public final String variables;

        public NotifTemplate(int id, String key, String name, String message, String description, String variables) {
            this.id = id;
            this.key = key;
            this.name = name;
            this.message = message;
            this.description = description;
            this.variables = variables;
        }
    }

    // -------------------------------------------------------------------------
    // Schema self-healing (called once at startup / first use)
    // -------------------------------------------------------------------------

    public static void ensureTemplateTables(Connection conn) throws SQLException {
        String emailDdl = "CREATE TABLE IF NOT EXISTS email_templates ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "template_key VARCHAR(100) NOT NULL,"
                + "name VARCHAR(200) NOT NULL,"
                + "subject VARCHAR(500) NOT NULL,"
                + "body MEDIUMTEXT NOT NULL,"
                + "description VARCHAR(500) NULL,"
                + "variables VARCHAR(1000) NULL,"
                + "is_active TINYINT(1) NOT NULL DEFAULT 1,"
                + "updated_by INT NULL,"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_email_template_key (template_key),"
                + "INDEX idx_email_template_active (is_active)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        String notifDdl = "CREATE TABLE IF NOT EXISTS notification_templates ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "template_key VARCHAR(100) NOT NULL,"
                + "name VARCHAR(200) NOT NULL,"
                + "message TEXT NOT NULL,"
                + "description VARCHAR(500) NULL,"
                + "variables VARCHAR(1000) NULL,"
                + "is_active TINYINT(1) NOT NULL DEFAULT 1,"
                + "updated_by INT NULL,"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_notif_template_key (template_key),"
                + "INDEX idx_notif_template_active (is_active)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        try (PreparedStatement ps = conn.prepareStatement(emailDdl)) { ps.execute(); }
        try (PreparedStatement ps = conn.prepareStatement(notifDdl)) { ps.execute(); }
    }

    // -------------------------------------------------------------------------
    // Load single templates
    // -------------------------------------------------------------------------

    /**
     * Load an email template by key. Returns null if not found or inactive.
     */
    public static EmailTemplate loadEmailTemplate(Connection conn, String key) throws SQLException {
        String sql = "SELECT id, template_key, name, subject, body, description, variables "
                + "FROM email_templates WHERE template_key = ? AND is_active = 1 LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new EmailTemplate(
                            rs.getInt("id"),
                            rs.getString("template_key"),
                            rs.getString("name"),
                            rs.getString("subject"),
                            rs.getString("body"),
                            rs.getString("description"),
                            rs.getString("variables"));
                }
            }
        }
        return null;
    }

    /**
     * Load a notification template by key. Returns null if not found or inactive.
     */
    public static NotifTemplate loadNotifTemplate(Connection conn, String key) throws SQLException {
        String sql = "SELECT id, template_key, name, message, description, variables "
                + "FROM notification_templates WHERE template_key = ? AND is_active = 1 LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new NotifTemplate(
                            rs.getInt("id"),
                            rs.getString("template_key"),
                            rs.getString("name"),
                            rs.getString("message"),
                            rs.getString("description"),
                            rs.getString("variables"));
                }
            }
        }
        return null;
    }

    // -------------------------------------------------------------------------
    // Load all templates (for admin UI)
    // -------------------------------------------------------------------------

    public static List<EmailTemplate> loadAllEmailTemplates(Connection conn) throws SQLException {
        List<EmailTemplate> list = new ArrayList<>();
        String sql = "SELECT id, template_key, name, subject, body, description, variables "
                + "FROM email_templates ORDER BY id ASC";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new EmailTemplate(
                        rs.getInt("id"),
                        rs.getString("template_key"),
                        rs.getString("name"),
                        rs.getString("subject"),
                        rs.getString("body"),
                        rs.getString("description"),
                        rs.getString("variables")));
            }
        }
        return list;
    }

    public static List<NotifTemplate> loadAllNotifTemplates(Connection conn) throws SQLException {
        List<NotifTemplate> list = new ArrayList<>();
        String sql = "SELECT id, template_key, name, message, description, variables "
                + "FROM notification_templates ORDER BY id ASC";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new NotifTemplate(
                        rs.getInt("id"),
                        rs.getString("template_key"),
                        rs.getString("name"),
                        rs.getString("message"),
                        rs.getString("description"),
                        rs.getString("variables")));
            }
        }
        return list;
    }

    // -------------------------------------------------------------------------
    // Save / upsert templates
    // -------------------------------------------------------------------------

    public static void saveEmailTemplate(Connection conn, String key, String name,
            String subject, String body, String description, Integer updatedBy) throws SQLException {
        String sql = "INSERT INTO email_templates (template_key, name, subject, body, description, updated_by) "
                + "VALUES (?, ?, ?, ?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE name = VALUES(name), subject = VALUES(subject), "
                + "body = VALUES(body), description = VALUES(description), updated_by = VALUES(updated_by)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            ps.setString(2, name);
            ps.setString(3, subject);
            ps.setString(4, body);
            ps.setString(5, description);
            if (updatedBy == null) ps.setNull(6, java.sql.Types.INTEGER);
            else ps.setInt(6, updatedBy);
            ps.executeUpdate();
        }
    }

    public static void saveNotifTemplate(Connection conn, String key, String name,
            String message, String description, Integer updatedBy) throws SQLException {
        String sql = "INSERT INTO notification_templates (template_key, name, message, description, updated_by) "
                + "VALUES (?, ?, ?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE name = VALUES(name), message = VALUES(message), "
                + "description = VALUES(description), updated_by = VALUES(updated_by)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            ps.setString(2, name);
            ps.setString(3, message);
            ps.setString(4, description);
            if (updatedBy == null) ps.setNull(5, java.sql.Types.INTEGER);
            else ps.setInt(5, updatedBy);
            ps.executeUpdate();
        }
    }

    // -------------------------------------------------------------------------
    // Template rendering â€” replaces {{key}} placeholders with values
    // -------------------------------------------------------------------------

    /**
     * Renders a template string by replacing all {{key}} placeholders with values from the map.
     * Missing keys are left as-is.
     */
    public static String render(String template, Map<String, String> vars) {
        if (template == null) return "";
        String result = normalizeTemplateInput(template);
        if (vars == null || vars.isEmpty()) return result;
        for (Map.Entry<String, String> entry : vars.entrySet()) {
            String placeholder = "{{" + entry.getKey() + "}}";
            String value = entry.getValue() == null ? "" : entry.getValue();
            result = result.replace(placeholder, value);
        }
        return result;
    }

    /**
     * Converts admin-friendly placeholders to canonical {{snake_case}} placeholders.
     * Supported examples:
     * - {{full_name}}
     * - {{Nama Penuh}}
     * - [Nama Penuh]
     * - [Tarikh Surat]
     */
    public static String normalizeTemplateInput(String template) {
        if (template == null || template.isEmpty()) {
            return template;
        }
        String normalized = normalizeCurlyPlaceholders(template);
        normalized = normalizeBracketPlaceholders(normalized);
        return normalized;
    }

    private static String normalizeCurlyPlaceholders(String input) {
        Matcher matcher = CURLY_PLACEHOLDER_PATTERN.matcher(input);
        StringBuffer output = new StringBuffer();
        while (matcher.find()) {
            String rawToken = matcher.group(1);
            String canonical = resolveCanonicalKey(rawToken);
            matcher.appendReplacement(output, Matcher.quoteReplacement("{{" + canonical + "}}"));
        }
        matcher.appendTail(output);
        return output.toString();
    }

    private static String normalizeBracketPlaceholders(String input) {
        Matcher matcher = BRACKET_PLACEHOLDER_PATTERN.matcher(input);
        StringBuffer output = new StringBuffer();
        while (matcher.find()) {
            String rawToken = matcher.group(1);
            String canonical = resolveCanonicalKey(rawToken);
            matcher.appendReplacement(output, Matcher.quoteReplacement("{{" + canonical + "}}"));
        }
        matcher.appendTail(output);
        return output.toString();
    }

    private static String resolveCanonicalKey(String rawToken) {
        String token = rawToken == null ? "" : rawToken.trim();
        if (token.isEmpty()) {
            return token;
        }

        String cleaned = token.replace('-', ' ').replace('_', ' ').trim();
        String lowered = cleaned.toLowerCase(java.util.Locale.ROOT).replaceAll("\\s+", " ");
        if (PLACEHOLDER_ALIASES.containsKey(lowered)) {
            return PLACEHOLDER_ALIASES.get(lowered);
        }

        String normalizedSnake = lowered.replaceAll("[^a-z0-9 ]", "").trim().replace(' ', '_');
        return normalizedSnake.isEmpty() ? token : normalizedSnake;
    }

    /**
     * Convenience: load + render email subject. Returns fallback if template not found.
     */
    public static String renderEmailSubject(Connection conn, String key, Map<String, String> vars, String fallback) {
        try {
            EmailTemplate t = loadEmailTemplate(conn, key);
            if (t != null && !t.subject.isBlank()) {
                return render(t.subject, vars);
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to load email template subject [" + key + "]: " + e.getMessage());
        }
        return fallback;
    }

    /**
     * Convenience: load + render email body. Returns fallback if template not found.
     */
    public static String renderEmailBody(Connection conn, String key, Map<String, String> vars, String fallback) {
        try {
            EmailTemplate t = loadEmailTemplate(conn, key);
            if (t != null && !t.body.isBlank()) {
                return render(t.body, vars);
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to load email template body [" + key + "]: " + e.getMessage());
        }
        return fallback;
    }

    /**
     * Convenience: load + render notification message. Returns fallback if template not found.
     */
    public static String renderNotif(Connection conn, String key, Map<String, String> vars, String fallback) {
        try {
            NotifTemplate t = loadNotifTemplate(conn, key);
            if (t != null && !t.message.isBlank()) {
                return render(t.message, vars);
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to load notification template [" + key + "]: " + e.getMessage());
        }
        return fallback;
    }
}


package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas KppReminderJobServlet.
 * Dipanggil melalui URL:  /internal/kpp-reminder-run (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.google.gson.JsonObject;
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.KppReminderService;
import com.sistemppa.util.EmailUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Locale;
import java.util.logging.Logger;

public class KppReminderJobServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(KppReminderJobServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");

        String configuredKey = getConfiguredJobKey(request);
        if (configuredKey.isBlank()) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonError("Tetapan kpp.reminder.job.key belum diisi."));
            return;
        }

        String providedKey = getProvidedKey(request);
        if (!configuredKey.equals(providedKey)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(jsonError("Kunci akses dalaman tidak sah."));
            return;
        }

        boolean dryRun = "1".equals(request.getParameter("dry_run"));
        int limit = parsePositiveInt(request.getParameter("limit"), 100);

        try (Connection conn = DatabaseConfig.getConnection()) {
            KppReminderService.ensureReminderTable(conn);

            EmailUtil emailUtil = null;
            if (!dryRun) {
                emailUtil = buildEmailUtil(request, conn);
                if (emailUtil == null) {
                    response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
                    response.getWriter().write(jsonError("SMTP belum dikonfigurasi untuk reminder KPP."));
                    return;
                }
            }

            KppReminderService.ReminderRunResult result = KppReminderService.processDueReminders(conn, emailUtil, limit, dryRun);
            response.getWriter().write(jsonOk(result, dryRun));
        } catch (SQLException e) {
            LOGGER.severe("Failed to run KPP reminder job: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(jsonError("Ralat pangkalan data semasa jalankan job reminder."));
        }
    }

    private EmailUtil buildEmailUtil(HttpServletRequest request, Connection conn) throws SQLException {
        Map<String, String> smtpSettings = loadSmtpSettings(conn);
        String smtpHost = firstNonBlank(smtpSettings.get("smtp_host"), getContextParam(request, "smtp.host", ""));
        int smtpPort = parsePositiveInt(firstNonBlank(smtpSettings.get("smtp_port"), getContextParam(request, "smtp.port", "587")), 587);
        boolean smtpAuth = parseBoolean(firstNonBlank(smtpSettings.get("smtp_auth"), getContextParam(request, "smtp.auth", "true")), true);
        boolean smtpTls = parseBoolean(firstNonBlank(smtpSettings.get("smtp_tls"), getContextParam(request, "smtp.tls", "true")), true);
        String smtpUser = firstNonBlank(smtpSettings.get("smtp_username"), getContextParam(request, "smtp.username", ""));
        String smtpPass = firstNonBlank(smtpSettings.get("smtp_password"), getContextParam(request, "smtp.password", ""));
        String smtpFrom = firstNonBlank(smtpSettings.get("smtp_from"), getContextParam(request, "smtp.from", smtpUser));

        if (smtpHost.isBlank()) {
            return null;
        }

        if (isPlaceholderSmtp(smtpHost, smtpUser, smtpPass, smtpFrom)
                || (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank()))) {
            return null;
        }

        return new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
    }

    private String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null ? "" : fallback.trim();
    }

    private boolean parseBoolean(String value, boolean defaultValue) {
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        if ("true".equals(normalized) || "1".equals(normalized) || "yes".equals(normalized) || "on".equals(normalized)) {
            return true;
        }
        if ("false".equals(normalized) || "0".equals(normalized) || "no".equals(normalized) || "off".equals(normalized)) {
            return false;
        }
        return defaultValue;
    }

    private Map<String, String> loadSmtpSettings(Connection conn) throws SQLException {
        ensureSmtpSettingsTable(conn);
        Map<String, String> settings = new LinkedHashMap<>();
        String sql = "SELECT setting_key, setting_value FROM smtp_settings WHERE enabled = 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                String key = rs.getString("setting_key");
                String val = rs.getString("setting_value");
                if (key != null && !key.isBlank()) {
                    settings.put(key.trim(), val == null ? "" : val.trim());
                }
            }
        }
        return settings;
    }

    private void ensureSmtpSettingsTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS smtp_settings ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "setting_key VARCHAR(100) NOT NULL,"
                + "setting_value VARCHAR(255) NOT NULL,"
                + "enabled TINYINT(1) NOT NULL DEFAULT 1,"
                + "description VARCHAR(255),"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_smtp_setting_key (setting_key),"
                + "INDEX idx_smtp_enabled (enabled)"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.execute();
        }
    }

    private String getConfiguredJobKey(HttpServletRequest request) {
        String key = getContextParam(request, "kpp.reminder.job.key", "");
        if (!key.isBlank()) {
            return key;
        }
        String envValue = System.getenv("KPP_REMINDER_JOB_KEY");
        return envValue == null ? "" : envValue.trim();
    }

    private String getProvidedKey(HttpServletRequest request) {
        String key = request.getHeader("X-Internal-Key");
        if (key != null && !key.isBlank()) {
            return key.trim();
        }
        String param = request.getParameter("key");
        return param == null ? "" : param.trim();
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private int parsePositiveInt(String value, int defaultValue) {
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        try {
            int parsed = Integer.parseInt(value.trim());
            return parsed > 0 ? parsed : defaultValue;
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    private boolean isPlaceholderSmtp(String smtpHost, String smtpUser, String smtpPass, String smtpFrom) {
        String host = smtpHost == null ? "" : smtpHost.trim().toLowerCase(Locale.ROOT);
        String user = smtpUser == null ? "" : smtpUser.trim().toLowerCase(Locale.ROOT);
        String pass = smtpPass == null ? "" : smtpPass.trim().toLowerCase(Locale.ROOT);
        String from = smtpFrom == null ? "" : smtpFrom.trim().toLowerCase(Locale.ROOT);

        return host.contains("example")
                || user.contains("your-email")
                || pass.contains("your-app-password")
                || pass.contains("change_me")
                || from.contains("your-email");
    }

    private String jsonOk(KppReminderService.ReminderRunResult result, boolean dryRun) {
        JsonObject json = new JsonObject();
        json.addProperty("success", true);
        json.addProperty("dryRun", dryRun);
        json.addProperty("dueCount", result.dueCount());
        json.addProperty("processedCount", result.processedCount());
        json.addProperty("sentCount", result.sentCount());
        json.addProperty("failedCount", result.failedCount());
        json.addProperty("rescheduledCount", result.rescheduledCount());
        return json.toString();
    }

    private String jsonError(String message) {
        JsonObject json = new JsonObject();
        json.addProperty("success", false);
        json.addProperty("message", message == null ? "" : message);
        return json.toString();
    }
}


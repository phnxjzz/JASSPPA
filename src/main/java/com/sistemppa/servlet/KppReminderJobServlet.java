package com.sistemppa.servlet;

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
import java.sql.SQLException;
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
                emailUtil = buildEmailUtil(request);
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

    private EmailUtil buildEmailUtil(HttpServletRequest request) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        int smtpPort = parsePositiveInt(getContextParam(request, "smtp.port", "587"), 587);
        boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
        boolean smtpTls = Boolean.parseBoolean(getContextParam(request, "smtp.tls", "true"));
        String smtpUser = getContextParam(request, "smtp.username", "");
        String smtpPass = getContextParam(request, "smtp.password", "");
        String smtpFrom = getContextParam(request, "smtp.from", smtpUser);

        if (smtpHost.isBlank()) {
            return null;
        }

        if (isPlaceholderSmtp(smtpHost, smtpUser, smtpPass, smtpFrom)
                || (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank()))) {
            return null;
        }

        return new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
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

package com.sistemppa.service;

import com.sistemppa.util.EmailUtil;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class KppReminderService {
    private static final int REMINDER_TOTAL = 3;
    private static final int REMINDER_GAP_DAYS = 4;
    private static final int MAX_SEND_ATTEMPTS = 3;
    private static final int RETRY_DELAY_HOURS = 24;

    private KppReminderService() {
    }

    public static void ensureReminderTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS kpp_reminder_queue ("
                + "id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                + "recipient_email VARCHAR(255) NOT NULL,"
                + "action_type VARCHAR(30) NOT NULL,"
                + "application_ref VARCHAR(80) NOT NULL,"
                + "guest_link VARCHAR(1200) NULL,"
                + "source_subject VARCHAR(300) NULL,"
                + "reminder_no TINYINT NOT NULL,"
                + "due_at TIMESTAMP NOT NULL,"
                + "status VARCHAR(20) NOT NULL DEFAULT 'PENDING',"
                + "attempt_count INT NOT NULL DEFAULT 0,"
                + "sent_at TIMESTAMP NULL,"
                + "cancelled_at TIMESTAMP NULL,"
                + "last_error VARCHAR(600) NULL,"
                + "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uk_kpp_reminder_unique (recipient_email, action_type, application_ref, reminder_no),"
                + "KEY idx_kpp_reminder_due (status, due_at),"
                + "KEY idx_kpp_reminder_lookup (recipient_email, action_type, application_ref)"
                + ")";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    public static int scheduleReminderSeries(
            Connection conn,
            String recipientEmail,
            String actionType,
            String applicationRef,
            String guestLink,
            String sourceSubject
    ) throws SQLException {
        ensureReminderTable(conn);

        String email = normalizeEmail(recipientEmail);
        String action = normalizeActionType(actionType);
        String appRef = normalizeApplicationRef(applicationRef);
        String link = normalizeText(guestLink, 1200);
        String subject = normalizeText(sourceSubject, 300);

        if (email.isBlank() || action.isBlank() || appRef.isBlank()) {
            return 0;
        }

        int inserted = 0;
        String sql = "INSERT INTO kpp_reminder_queue "
                + "(recipient_email, action_type, application_ref, guest_link, source_subject, reminder_no, due_at, status) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING') "
                + "ON DUPLICATE KEY UPDATE "
                + "guest_link = VALUES(guest_link), "
                + "source_subject = VALUES(source_subject), "
                + "updated_at = CURRENT_TIMESTAMP";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (int reminderNo = 1; reminderNo <= REMINDER_TOTAL; reminderNo++) {
                Timestamp dueAt = Timestamp.from(Instant.now().plus((long) reminderNo * REMINDER_GAP_DAYS, ChronoUnit.DAYS));
                stmt.setString(1, email);
                stmt.setString(2, action);
                stmt.setString(3, appRef);
                stmt.setString(4, link.isBlank() ? null : link);
                stmt.setString(5, subject.isBlank() ? null : subject);
                stmt.setInt(6, reminderNo);
                stmt.setTimestamp(7, dueAt);
                int updated = stmt.executeUpdate();
                if (updated > 0) {
                    inserted++;
                }
            }
        }

        return inserted;
    }

    public static int cancelPendingReminders(
            Connection conn,
            String recipientEmail,
            String actionType,
            String applicationRef
    ) throws SQLException {
        ensureReminderTable(conn);

        String sql = "UPDATE kpp_reminder_queue "
                + "SET status = 'COMPLETED', cancelled_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP "
                + "WHERE recipient_email = ? AND action_type = ? AND application_ref = ? AND status = 'PENDING'";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, normalizeEmail(recipientEmail));
            stmt.setString(2, normalizeActionType(actionType));
            stmt.setString(3, normalizeApplicationRef(applicationRef));
            return stmt.executeUpdate();
        }
    }

    public static ReminderRunResult processDueReminders(
            Connection conn,
            EmailUtil emailUtil,
            int batchLimit,
            boolean dryRun
    ) throws SQLException {
        ensureReminderTable(conn);

        List<ReminderRow> dueRows = loadDueRows(conn, batchLimit <= 0 ? 100 : batchLimit);
        int totalDue = dueRows.size();

        if (dryRun || dueRows.isEmpty()) {
            return new ReminderRunResult(totalDue, 0, 0, 0, 0);
        }

        int sentCount = 0;
        int failedCount = 0;
        int rescheduledCount = 0;

        for (ReminderRow row : dueRows) {
            String subject = buildReminderSubject(row);
            String body = buildReminderBody(row);
            boolean sent = emailUtil.sendHtml(row.recipientEmail(), subject, body);
            if (sent) {
                markSent(conn, row.id());
                sentCount++;
            } else {
                boolean rescheduled = markFailure(conn, row.id(), row.attemptCount() + 1);
                failedCount++;
                if (rescheduled) {
                    rescheduledCount++;
                }
            }
        }

        return new ReminderRunResult(totalDue, dueRows.size(), sentCount, failedCount, rescheduledCount);
    }

    private static List<ReminderRow> loadDueRows(Connection conn, int limit) throws SQLException {
        String sql = "SELECT id, recipient_email, action_type, application_ref, guest_link, source_subject, reminder_no, attempt_count "
                + "FROM kpp_reminder_queue "
                + "WHERE status = 'PENDING' AND due_at <= CURRENT_TIMESTAMP "
                + "ORDER BY due_at ASC, id ASC LIMIT ?";

        List<ReminderRow> rows = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    rows.add(new ReminderRow(
                            rs.getLong("id"),
                            normalizeEmail(rs.getString("recipient_email")),
                            normalizeActionType(rs.getString("action_type")),
                            normalizeApplicationRef(rs.getString("application_ref")),
                            normalizeText(rs.getString("guest_link"), 1200),
                            normalizeText(rs.getString("source_subject"), 300),
                            rs.getInt("reminder_no"),
                            rs.getInt("attempt_count")
                    ));
                }
            }
        }
        return rows;
    }

    private static void markSent(Connection conn, long id) throws SQLException {
        String sql = "UPDATE kpp_reminder_queue "
                + "SET status = 'SENT', sent_at = CURRENT_TIMESTAMP, last_error = NULL, updated_at = CURRENT_TIMESTAMP "
                + "WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            stmt.executeUpdate();
        }
    }

    private static boolean markFailure(Connection conn, long id, int nextAttemptCount) throws SQLException {
        if (nextAttemptCount >= MAX_SEND_ATTEMPTS) {
            String sql = "UPDATE kpp_reminder_queue "
                    + "SET status = 'FAILED', attempt_count = ?, last_error = ?, updated_at = CURRENT_TIMESTAMP "
                    + "WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, nextAttemptCount);
                stmt.setString(2, "Gagal dihantar selepas cubaan berulang.");
                stmt.setLong(3, id);
                stmt.executeUpdate();
            }
            return false;
        }

        String sql = "UPDATE kpp_reminder_queue "
                + "SET attempt_count = ?, due_at = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL ? HOUR), "
                + "last_error = ?, updated_at = CURRENT_TIMESTAMP "
                + "WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, nextAttemptCount);
            stmt.setInt(2, RETRY_DELAY_HOURS);
            stmt.setString(3, "Gagal hantar email. Akan cuba semula.");
            stmt.setLong(4, id);
            stmt.executeUpdate();
        }
        return true;
    }

    private static String buildReminderSubject(ReminderRow row) {
        String base = !row.sourceSubject().isBlank()
                ? row.sourceSubject()
                : "Tindakan KPP diperlukan";
        String appRefLabel = row.applicationRef().isBlank() ? "" : (" - " + row.applicationRef());
        if (row.reminderNo() == 3) {
            return "PERINGATAN 3 (SURAT TUNJUK SEBAB): " + base + appRefLabel;
        }
        return "PERINGATAN " + row.reminderNo() + ": " + base + appRefLabel;
    }

    private static String buildReminderBody(ReminderRow row) {
        String actionLabel = toActionLabel(row.actionType());
        String appRef = row.applicationRef().isBlank() ? "-" : row.applicationRef();
        StringBuilder body = new StringBuilder();
        body.append("Assalamualaikum/Salam Sejahtera,\n\n")
                .append("Ini adalah peringatan ke-")
                .append(row.reminderNo())
                .append(" untuk tindakan KPP bagi borang ")
                .append(actionLabel)
                .append(".\n")
                .append("Rujukan permohonan: ")
                .append(appRef)
                .append(".\n\n");

        if (!row.guestLink().isBlank()) {
            body.append("Sila lengkapkan tindakan melalui pautan khas berikut:\n")
                    .append(row.guestLink())
                    .append("\n\n");
        }

        if (row.reminderNo() == 3) {
            body.append("Ini adalah peringatan terakhir. Sekiranya masih tiada tindakan, "
                    + "sila kemukakan surat tunjuk sebab dengan kadar segera.\n\n");
        }

        body.append("Terima kasih.");

        return "<div style=\"font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:14px;line-height:1.6;color:#183244;\">"
                + escapeHtml(body.toString()).replace("\n", "<br>")
                + "</div>";
    }

    private static String escapeHtml(String text) {
        if (text == null || text.isBlank()) {
            return "";
        }
        return text
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String toActionLabel(String actionType) {
        String action = normalizeActionType(actionType);
        if ("KSPP_UJPPP".equals(action)) {
            return "KSPP/UJPPP";
        }
        return action.isBlank() ? "KSPP" : action;
    }

    private static String normalizeEmail(String value) {
        String normalized = normalizeText(value, 255).toLowerCase(Locale.ROOT);
        if (!normalized.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            return "";
        }
        return normalized;
    }

    private static String normalizeActionType(String value) {
        String normalized = normalizeText(value, 30).toUpperCase(Locale.ROOT)
                .replace('-', '_')
                .replace(' ', '_');
        if ("KSPP+UJPPP".equals(normalized) || "BOTH".equals(normalized)) {
            return "KSPP_UJPPP";
        }
        if ("KSPP".equals(normalized) || "UJPPP".equals(normalized) || "KSPP_UJPPP".equals(normalized)) {
            return normalized;
        }
        return "";
    }

    private static String normalizeApplicationRef(String value) {
        String normalized = normalizeText(value, 80);
        if (!normalized.matches("^[A-Za-z0-9._-]*$")) {
            return "";
        }
        return normalized;
    }

    private static String normalizeText(String value, int maxLength) {
        if (value == null) {
            return "";
        }
        String normalized = value.trim().replace('\n', ' ').replace('\r', ' ');
        if (normalized.length() > maxLength) {
            return normalized.substring(0, maxLength);
        }
        return normalized;
    }

    private record ReminderRow(
            long id,
            String recipientEmail,
            String actionType,
            String applicationRef,
            String guestLink,
            String sourceSubject,
            int reminderNo,
            int attemptCount
    ) {
    }

    public record ReminderRunResult(
            int dueCount,
            int processedCount,
            int sentCount,
            int failedCount,
            int rescheduledCount
    ) {
    }
}
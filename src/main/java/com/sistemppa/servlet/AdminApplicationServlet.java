package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas AdminApplicationServlet.
 * Dipanggil melalui URL:  /admin/application (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.service.TemplateService;
import com.sistemppa.util.EmailUtil;
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
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

public class AdminApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminApplicationServlet.class.getName());
    private static final Path KPP_CSV_PATH = Paths.get("P:/ProjectLI/data/Senarai KPP.csv");

    // Titik masuk GET untuk /admin/application.
    // Buka halaman semakan terperinci satu permohonan (admin-application.jsp).
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        String applicationId = request.getParameter("id");
        if (applicationId == null || applicationId.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureApplicationArchiveTable(conn);
            DashboardDataService.ensureCertificateColumns(conn);
            renderApplicationPage(conn, request, response, Integer.parseInt(applicationId), null);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load admin application review page: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan permohonan");
        }
    }

    // Titik masuk POST untuk tindakan admin pada permohonan:
    // semak status workflow, kemas kini status, hantar notifikasi, dan audit log.
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        boolean ajaxRequest = isAjaxRequest(request);
        String action = request.getParameter("action");
        boolean archiveFlow = "archive".equals(action) || "unarchive".equals(action);
        boolean shouldReturnJson = ajaxRequest || archiveFlow || "1".equals(request.getParameter("ajax"));

        Integer applicationIdValue = firstValidInteger(
            request.getParameter("id"),
            request.getParameter("application_id"),
            request.getParameter("applicationId"));
        if (applicationIdValue == null) {
            if (shouldReturnJson) {
                writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "ID permohonan tidak sah", null);
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard?error=invalid_application_id");
            }
            return;
        }

        int applicationId = applicationIdValue;
        String adminNotes = trim(request.getParameter("admin_notes"));
        String validUntilStr = trim(request.getParameter("valid_until"));
        String presentationDate = trim(request.getParameter("presentation_date"));
        String presentationTime = trim(request.getParameter("presentation_time"));
        String presentationVenue = trim(request.getParameter("presentation_venue"));
        String presentationMessage = trim(request.getParameter("presentation_message"));
        String kppInviteEmails = trim(request.getParameter("kpp_invite_emails"));
        String kppInviteMemo = trim(request.getParameter("kpp_invite_memo"));
        String inviteMode = trim(request.getParameter("invite_mode"));
        Long replaceInviteId = parseLong(request.getParameter("replace_invite_id"));
        Integer adminUserId = (Integer) request.getSession(false).getAttribute("user_id");

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureApplicationArchiveTable(conn);
            DashboardDataService.ensureCertificateColumns(conn);
            String adminDisplayId = DashboardDataService.resolveDisplayUserId(conn, adminUserId, "ADMIN");

            if ("reject".equals(action) && (adminNotes == null || adminNotes.isBlank())) {
                if (ajaxRequest) {
                    writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                            "Sebab penolakan wajib diisi sebelum permohonan ditolak.", action);
                } else {
                    request.setAttribute("error", "Sebab penolakan wajib diisi sebelum permohonan ditolak.");
                    renderApplicationPage(conn, request, response, applicationId, "");
                }
                return;
            }

            Map<String, Object> workflowState = loadWorkflowState(conn, applicationId);
            String currentStatus = normalizeStatus((String) workflowState.get("status"));

            if ("approve".equals(action)) {
                requireAllowedStatus(action, currentStatus, "NEW", "DILULUSKAN_PENGARAH");
                updateApplicationStatus(conn, applicationId, currentStatus, "UNDER_REVIEW", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "ACCEPT APPLICATION",
                    "Admin " + adminDisplayId + " terima permohonan PPP" + String.format("%03d", applicationId) + " untuk semakan", request.getRemoteAddr());
            } else if ("reject".equals(action)) {
                requireAllowedStatus(action, currentStatus, "NEW", "DILULUSKAN_PENGARAH", "UNDER_REVIEW", "IN_PROGRESS");
                updateApplicationStatus(conn, applicationId, currentStatus, "REJECTED", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "REJECT APPLICATION",
                    "Admin " + adminDisplayId + " tolak permohonan PPP" + String.format("%03d", applicationId) + ". Sebab: " + adminNotes, request.getRemoteAddr());
                sendStatusEmail(request, conn, applicationId, "REJECTED", adminNotes);
            } else if ("under_review".equals(action) || "dalam_semakan".equals(action)) {
                requireAllowedStatus(action, currentStatus, "NEW", "DILULUSKAN_PENGARAH");
                updateApplicationStatus(conn, applicationId, currentStatus, "UNDER_REVIEW", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "UNDER REVIEW APPLICATION",
                    "Admin " + adminDisplayId + " set permohonan PPP" + String.format("%03d", applicationId) + " ke Dalam Semakan", request.getRemoteAddr());
            } else if ("in_progress".equals(action) || "dalam_proses".equals(action)) {
                requireAllowedStatus(action, currentStatus, "UNDER_REVIEW", "DILULUSKAN_PENGARAH", "IN_PROGRESS");
                if (presentationDate == null || presentationDate.isBlank()
                        || presentationTime == null || presentationTime.isBlank()
                        || presentationVenue == null || presentationVenue.isBlank()) {
                    String message = "Sila isi tarikh, masa, dan tempat pembentangan sebelum set status Dalam Proses.";
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, message, action);
                    } else {
                        request.setAttribute("error", message);
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                boolean rescheduled = "reschedule".equalsIgnoreCase(inviteMode);
                if (!"IN_PROGRESS".equals(currentStatus)) {
                    updateApplicationStatus(conn, applicationId, currentStatus, "IN_PROGRESS", adminNotes, adminUserId, null);
                }
                int invitedUserId = getApplicationUserId(conn, applicationId);
                if (invitedUserId > 0) {
                    DashboardDataService.createPresentationInvite(
                        conn,
                        applicationId,
                        invitedUserId,
                        adminUserId,
                        presentationDate,
                        presentationTime,
                        presentationVenue,
                        presentationMessage,
                        kppInviteEmails,
                        kppInviteMemo,
                        rescheduled,
                        rescheduled ? replaceInviteId : null);
                }
                insertInProgressPresentationNotification(conn, applicationId, adminNotes,
                        presentationDate, presentationTime, presentationVenue, presentationMessage);
                sendInProgressPresentationEmail(request, conn, applicationId,
                    presentationDate, presentationTime, presentationVenue, presentationMessage);
                insertAdminAuditLog(conn, adminUserId, "IN PROGRESS APPLICATION",
                    "Admin " + adminDisplayId + " urus jemputan pembentangan untuk PPP" + String.format("%03d", applicationId)
                        + ("IN_PROGRESS".equals(currentStatus) ? " (status kekal Dalam Proses)" : " dan set ke Dalam Proses"),
                    request.getRemoteAddr());
            } else if ("final_action".equals(action)) {
                requireAllowedStatus(action, currentStatus, "IN_PROGRESS");
                requestDirectorFinalAction(conn, applicationId, adminNotes, adminUserId);
                sendDirectorFinalReviewNotification(request, conn, applicationId);
                insertAdminAuditLog(conn, adminUserId, "REQUEST DIRECTOR FINAL ACTION",
                    "Admin " + adminDisplayId + " hantar permohonan PPP" + String.format("%03d", applicationId) + " kepada Pengarah untuk tindakan akhir", request.getRemoteAddr());
            } else if ("next_step".equals(action)) {
                String nextStatus = resolveNextAdminStatus(currentStatus);
                updateApplicationStatus(conn, applicationId, currentStatus, nextStatus, adminNotes, adminUserId, validUntilStr);
                insertAdminAuditLog(conn, adminUserId, "PROCESS DIRECTOR FINAL RESULT",
                    "Admin " + adminDisplayId + " proses tindakan seterusnya untuk PPP" + String.format("%03d", applicationId) + " kepada status " + nextStatus, request.getRemoteAddr());
                if ("APPROVED".equals(nextStatus) || "REJECTED".equals(nextStatus)) {
                    sendStatusEmail(request, conn, applicationId, nextStatus, adminNotes);
                }
            } else if ("suspend_application".equals(action)) {
                requireAllowedStatus(action, currentStatus, "UNDER_REVIEW", "IN_PROGRESS", "MENUNGGU_SETERUSNYA_GANTUNG");
                String expectedStatus = "MENUNGGU_SETERUSNYA_GANTUNG".equals(currentStatus) ? currentStatus : currentStatus;
                String targetStatus = "MENUNGGU_SETERUSNYA_GANTUNG".equals(currentStatus) ? "SUSPENDED" : "SUSPENDED";
                updateApplicationStatus(conn, applicationId, expectedStatus, targetStatus, adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "SUSPEND APPLICATION",
                        "Admin " + adminDisplayId + " gantung permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("suspend_user".equals(action)) {
                suspendUserByApplication(conn, applicationId, adminNotes);
                insertAdminAuditLog(conn, adminUserId, "SUSPEND USER BY APPLICATION",
                        "Admin " + adminDisplayId + " gantung pengguna melalui permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("archive".equals(action)) {
                if (!canArchiveApplication(conn, applicationId)) {
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                                "Permohonan ini sudah diarkib atau tidak ditemui.", action);
                    } else {
                        request.setAttribute("error", "Permohonan ini sudah diarkib atau tidak ditemui.");
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                archiveApplication(conn, applicationId, adminNotes, adminUserId);
                insertAdminAuditLog(conn, adminUserId, "ARCHIVE APPLICATION",
                    "Admin " + adminDisplayId + " arkib permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("unarchive".equals(action)) {
                if (!isArchived(conn, applicationId)) {
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                                "Permohonan ini belum diarkib.", action);
                    } else {
                        request.setAttribute("error", "Permohonan ini belum diarkib.");
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                unarchiveApplication(conn, applicationId);
                insertAdminAuditLog(conn, adminUserId, "UNARCHIVE APPLICATION",
                    "Admin " + adminDisplayId + " buka arkib permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("resend_director".equals(action)) {
                requireAllowedStatus(action, currentStatus, "MENUNGGU_TINDAKAN_PENGARAH");
                resendDirectorNotification(request, conn, applicationId);
                insertAdminAuditLog(conn, adminUserId, "RESEND DIRECTOR EMAIL",
                    "Admin " + adminDisplayId + " hantar semula email notifikasi pengarah untuk PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else {
                if (ajaxRequest) {
                    writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                            "Tindakan pentadbir tidak sah.", action);
                } else {
                    request.setAttribute("error", "Tindakan pentadbir tidak sah.");
                    renderApplicationPage(conn, request, response, applicationId, adminNotes);
                }
                return;
            }
            if (ajaxRequest) {
                String message = "Kemas kini berjaya.";
                if ("archive".equals(action)) {
                    message = "Berjaya arkib.";
                } else if ("unarchive".equals(action)) {
                    message = "Berjaya dikeluarkan dari arkib.";
                }
                writeJson(response, HttpServletResponse.SC_OK, true, message, action);
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/application?id=" + applicationId + "&updated=1");
            }
        } catch (IllegalStateException e) {
            LOGGER.warning("Admin workflow validation failed: " + e.getMessage());
            if (ajaxRequest) {
                writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, e.getMessage(), action);
            } else {
                request.setAttribute("error", e.getMessage());
                try (Connection refreshConn = DatabaseConfig.getConnection()) {
                    ensureApplicationArchiveTable(refreshConn);
                    DashboardDataService.ensureCertificateColumns(refreshConn);
                    renderApplicationPage(refreshConn, request, response, applicationId, adminNotes);
                } catch (SQLException refreshError) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to update admin application review: " + e.getMessage());
            if (ajaxRequest) {
                writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                        "Gagal mengemas kini permohonan", action);
            } else {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal mengemas kini permohonan");
            }
        }
    }

    // -------------------------------------------------------------------------
    // Director notification (resend)
    // -------------------------------------------------------------------------

    private void resendDirectorNotification(HttpServletRequest request, Connection conn, int applicationId) {
        sendDirectorNotification(request, conn, applicationId, true, false);
    }

    private void sendDirectorFinalReviewNotification(HttpServletRequest request, Connection conn, int applicationId) {
        sendDirectorNotification(request, conn, applicationId, false, true);
    }

    // Hantar notifikasi emel kepada semua pengguna role DIRECTOR.
    // Digunakan untuk hantar semula notifikasi dan juga permintaan tindakan akhir.
    private void sendDirectorNotification(HttpServletRequest request, Connection conn, int applicationId,
            boolean resend, boolean finalReview) {
        try {
            List<Map<String, String>> directors = loadDirectorRecipients(conn);
            if (directors.isEmpty()) {
                LOGGER.info("Director notification skipped: no active directors.");
                return;
            }
            String smtpHost = getContextParam(request, "smtp.host", "");
            if (smtpHost.isBlank()) {
                LOGGER.info("Director notification skipped: SMTP not configured.");
                return;
            }
            int smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls  = Boolean.parseBoolean(getContextParam(request, "smtp.tls",  "true"));
            String smtpUser  = getContextParam(request, "smtp.username", "");
            String smtpPass  = getContextParam(request, "smtp.password", "");
            String smtpFrom  = getContextParam(request, "smtp.from", smtpUser);

            String companyName = "";
            String productName = "";
            String applicantName = "";
            String submittedAt = "";
            String sql = "SELECT a.company_name, a.product_name, a.submitted_at, u.full_name "
                    + "FROM applications a JOIN users u ON u.id = a.user_id WHERE a.id = ? LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, applicationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        companyName = String.valueOf(rs.getString("company_name"));
                        productName = String.valueOf(rs.getString("product_name"));
                        applicantName = String.valueOf(rs.getString("full_name"));
                        submittedAt = String.valueOf(rs.getTimestamp("submitted_at"));
                    }
                }
            }

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            String subject;
            String intro;
            if (finalReview) {
                subject = resend
                        ? "Permohonan Menunggu Tindakan Akhir Pengarah (Hantar Semula)"
                        : "Permohonan Menunggu Tindakan Akhir Pengarah";
                intro = resend
                        ? "Ini adalah <strong>hantar semula</strong> notifikasi permohonan yang memerlukan tindakan akhir Pengarah."
                        : "Terdapat permohonan yang memerlukan tindakan akhir Pengarah.";
            } else {
                subject = "Permohonan Baharu Menunggu Tindakan Pengarah (Hantar Semula)";
                intro = "Ini adalah <strong>hantar semula</strong> notifikasi permohonan yang memerlukan tindakan Pengarah.";
            }
            for (Map<String, String> recipient : directors) {
                String toEmail = recipient.getOrDefault("email", "");
                if (toEmail.isBlank()) continue;
                Integer directorId = parseInteger(recipient.get("id"));
                if (directorId == null) continue;
                String directorName = recipient.getOrDefault("full_name", "Pengarah");
                String accessUrl = ApplicationServlet.buildDirectorAccessUrl(request, directorId, toEmail, applicationId);
                Map<String, String> vars = new LinkedHashMap<>();
                vars.put("director_name", escapeHtml(directorName));
                vars.put("app_ref", escapeHtml(formatApplicationReference(applicationId)));
                vars.put("applicant_name", escapeHtml(applicantName));
                vars.put("company_name", escapeHtml(companyName));
                vars.put("product_name", escapeHtml(productName));
                vars.put("submitted_at", escapeHtml(submittedAt));
                vars.put("review_stage_label", finalReview ? "tindakan akhir" : "tindakan");
                vars.put("action_intro", intro);
                vars.put("dashboard_url", escapeHtml(accessUrl));
                vars.put("dashboard_link_html", buildHtmlLink(accessUrl, "Klik Di Sini"));

                String fallbackBody = "<div style=\"font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:14px;line-height:1.6;color:#183244;\">"
                        + "<p>Tuan/Puan Pengarah " + escapeHtml(directorName) + ",</p>"
                        + "<p><strong>PERMOHONAN UNTUK " + (finalReview ? "TINDAKAN AKHIR" : "TINDAKAN") + " PENGARAH</strong></p>"
                        + "<p>Dengan hormatnya perkara di atas adalah dirujuk.</p>"
                        + "<p>2. " + intro + "</p>"
                        + "<p>3. Butiran permohonan adalah seperti berikut:<br>"
                        + "Pemohon: " + escapeHtml(applicantName) + "<br>"
                        + "Syarikat: " + escapeHtml(companyName) + "<br>"
                        + "Produk: " + escapeHtml(productName) + "<br>"
                        + "Tarikh Hantar: " + escapeHtml(submittedAt) + "</p>"
                        + "<p>4. Sila akses modul Pengarah melalui pautan berikut untuk tindakan lanjut: "
                        + buildHtmlLink(accessUrl, "Klik Di Sini") + "</p>"
                        + "<p style=\"font-size:12px;color:#577084;\">Pautan ini sah selama 7 hari dari tarikh emel dihantar. Jika pautan tidak berfungsi, salin URL ini ke pelayar: "
                        + escapeHtml(accessUrl) + "</p>"
                        + "<p>Sekian, terima kasih.</p>"
                        + "<p>Urusetia<br>Sistem Pendaftaran Produk Air</p>"
                        + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p></div>";
                subject = TemplateService.renderEmailSubject(conn, "DIRECTOR_ACTION_REQUEST", vars, subject);
                String body = TemplateService.renderEmailBody(conn, "DIRECTOR_ACTION_REQUEST", vars, fallbackBody);
                emailUtil.sendHtml(toEmail, subject, body);
            }
        } catch (Exception e) {
            LOGGER.warning("Failed to send director notification for application #" + applicationId + ": " + e.getMessage());
        }
    }

    private List<Map<String, String>> loadDirectorRecipients(Connection conn) throws SQLException {
        List<Map<String, String>> recipients = new ArrayList<>();
        String sql = "SELECT id, full_name, email FROM users "
                + "WHERE role = 'DIRECTOR' AND status = 'ACTIVE' AND email IS NOT NULL AND TRIM(email) <> '' "
                + "ORDER BY id ASC";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("id",        String.valueOf(rs.getInt("id")));
                row.put("full_name", trim(rs.getString("full_name")));
                row.put("email",     trim(rs.getString("email")));
                recipients.add(row);
            }
        }
        return recipients;
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        String ajaxParam = request.getParameter("ajax");
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || "1".equals(ajaxParam)
                || (accept != null && accept.toLowerCase().contains("application/json"));
    }

    private Integer firstValidInteger(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            Integer parsed = parseInteger(value);
            if (parsed != null) {
                return parsed;
            }
        }
        return null;
    }

    private void writeJson(HttpServletResponse response, int statusCode,
            boolean ok, String message, String action) throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json;charset=UTF-8");
        String safeMessage = message == null ? "" : message.replace("\\", "\\\\").replace("\"", "\\\"");
        String safeAction = action == null ? "" : action.replace("\\", "\\\\").replace("\"", "\\\"");
        response.getWriter().write("{\"ok\":" + ok
                + ",\"message\":\"" + safeMessage + "\""
                + ",\"action\":\"" + safeAction + "\"}");
    }

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        return true;
    }

    // Sediakan semua data yang diperlukan oleh admin-application.jsp
    // supaya admin boleh semak dokumen, sejarah audit, dan maklumat jemputan pembentangan.
    private void renderApplicationPage(Connection conn, HttpServletRequest request, HttpServletResponse response,
            int applicationId, String adminNotesOverride) throws SQLException, ServletException, IOException {
        Map<String, Object> application = new HashMap<>(loadApplication(conn, applicationId));
        if (application.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan tidak ditemui");
            return;
        }

        if (adminNotesOverride != null) {
            application.put("admin_notes", adminNotesOverride);
        }

        request.setAttribute("application", application);
        request.setAttribute("applicationDetail", loadApplicationDetail(conn, applicationId));
        request.setAttribute("documents", loadDocuments(conn, applicationId));
        request.setAttribute("kpp_users", loadKppUsers(conn));
        request.setAttribute("latest_presentation_invite", loadLatestPresentationInvite(conn, applicationId));
        request.setAttribute("admin_audit_logs",
            DashboardDataService.loadRecentAdminAuditLogsByKeyword(
                conn,
                "PPP" + String.format("%03d", applicationId),
                20));
        request.getRequestDispatcher("/admin-application.jsp").forward(request, response);
    }

    private List<Map<String, Object>> loadKppUsers(Connection conn) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();

        if (Files.exists(KPP_CSV_PATH)) {
            try {
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

                    String name = parts.get(0) == null ? "" : parts.get(0).trim();
                    String branch = parts.get(1) == null ? "" : parts.get(1).trim();
                    String email = parts.get(2) == null ? "" : parts.get(2).trim();
                    if (name.isBlank() || email.isBlank()) {
                        continue;
                    }

                    Map<String, Object> row = new HashMap<>();
                    row.put("full_name", name);
                    row.put("role", branch.isBlank() ? "KPP" : branch);
                    row.put("email", email);
                    rows.add(row);
                }
            } catch (IOException ex) {
                LOGGER.warning("Failed to read KPP CSV from " + KPP_CSV_PATH + ": " + ex.getMessage());
            }
        }

        if (!rows.isEmpty()) {
            return rows;
        }

        List<Map<String, Object>> contacts = DashboardDataService.loadKppContacts(conn);
        for (Map<String, Object> contact : contacts) {
            String name = contact.get("name") == null ? "" : String.valueOf(contact.get("name")).trim();
            String branch = contact.get("branch") == null ? "" : String.valueOf(contact.get("branch")).trim();
            String email = contact.get("email") == null ? "" : String.valueOf(contact.get("email")).trim();
            if (name.isBlank() || email.isBlank()) {
                continue;
            }

            Map<String, Object> row = new HashMap<>();
            row.put("full_name", name);
            row.put("role", branch.isBlank() ? "KPP" : branch);
            row.put("email", email);
            rows.add(row);
        }
        return rows;
    }

    private Map<String, Object> loadLatestPresentationInvite(Connection conn, int applicationId) throws SQLException {
        List<Map<String, Object>> invites = DashboardDataService.loadPresentationInvitesForAdmin(conn, 200);
        for (Map<String, Object> invite : invites) {
            Object inviteApplicationId = invite.get("application_id");
            if (inviteApplicationId instanceof Number && ((Number) inviteApplicationId).intValue() == applicationId) {
                return invite;
            }
        }
        return null;
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

    private Map<String, Object> loadApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.*, u.full_name, u.email AS user_email, u.status AS user_status, "
                + "aa.archived_at, aa.archive_notes, aa.archived_by "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return Map.of();
                }
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("user_id", rs.getInt("user_id"));
                row.put("product_name", rs.getString("product_name"));
                row.put("product_category", rs.getString("product_category"));
                row.put("product_description", rs.getString("product_description"));
                row.put("company_name", rs.getString("company_name"));
                row.put("company_address", rs.getString("company_address"));
                row.put("contact_number", rs.getString("contact_number"));
                row.put("email", rs.getString("email"));
                row.put("status", rs.getString("status"));
                row.put("director_review_type", rs.getString("director_review_type"));
                row.put("admin_notes", rs.getString("admin_notes"));
                row.put("submitted_at", rs.getTimestamp("submitted_at"));
                row.put("full_name", rs.getString("full_name"));
                row.put("user_email", rs.getString("user_email"));
                row.put("user_status", rs.getString("user_status"));
                row.put("archived_at", rs.getTimestamp("archived_at"));
                row.put("archive_notes", rs.getString("archive_notes"));
                row.put("archived_by", rs.getObject("archived_by"));
                row.put("certificate_number", rs.getString("certificate_number"));
                row.put("issued_at", rs.getDate("issued_at"));
                row.put("valid_until", rs.getDate("valid_until"));
                return row;
            }
        }
    }

    private Map<String, Object> loadApplicationDetail(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT * FROM application_details WHERE application_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return Map.of();
                }
                Map<String, Object> row = new HashMap<>();
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
                return row;
            }
        }
    }

    private List<Map<String, Object>> loadDocuments(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT id, document_type, original_filename, content_type, file_size, created_at FROM application_documents WHERE application_id = ? ORDER BY id ASC";
        List<Map<String, Object>> documents = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("document_type", rs.getString("document_type"));
                    row.put("original_filename", rs.getString("original_filename"));
                    row.put("content_type", rs.getString("content_type"));
                    row.put("file_size", rs.getLong("file_size"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    documents.add(row);
                }
            }
        }
        return documents;
    }

    private Map<String, Object> loadWorkflowState(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT status, director_review_type FROM applications WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalStateException("Permohonan tidak ditemui.");
                }
                Map<String, Object> row = new HashMap<>();
                row.put("status", rs.getString("status"));
                row.put("director_review_type", rs.getString("director_review_type"));
                return row;
            }
        }
    }

    private String normalizeStatus(String status) {
        return status == null ? "" : status.trim().toUpperCase().replace(' ', '_').replace('-', '_');
    }

    private void requireAllowedStatus(String action, String currentStatus, String... allowedStatuses) {
        for (String allowedStatus : allowedStatuses) {
            if (normalizeStatus(allowedStatus).equals(currentStatus)) {
                return;
            }
        }
        throw new IllegalStateException(buildWorkflowErrorMessage(action, currentStatus));
    }

    private String buildWorkflowErrorMessage(String action, String currentStatus) {
        String normalizedAction = action == null ? "" : action.trim().toLowerCase();
        return switch (normalizedAction) {
            case "approve", "under_review", "dalam_semakan" -> "Permohonan ini mesti melalui langkah Semak dahulu dan tidak boleh diulang atau dilangkau.";
            case "in_progress", "dalam_proses" -> "Permohonan mesti berada dalam status Semakan sebelum boleh masuk ke Dalam Tindakan.";
            case "final_action" -> "Permohonan mesti berada dalam status Dalam Tindakan sebelum boleh dihantar untuk Tindakan Akhir Pengarah.";
            case "next_step" -> "Butang Seterusnya hanya boleh digunakan selepas Pengarah memberi tindakan akhir.";
            case "resend_director" -> "Hantar semula email Pengarah hanya dibenarkan ketika status menunggu tindakan Pengarah.";
            default -> "Tindakan ini tidak dibenarkan untuk status semasa: " + currentStatus + ".";
        };
    }

    private String resolveNextAdminStatus(String currentStatus) {
        return switch (normalizeStatus(currentStatus)) {
            case "MENUNGGU_SETERUSNYA_DILULUSKAN" -> "APPROVED";
            case "MENUNGGU_SETERUSNYA_GAGAL" -> "REJECTED";
            case "MENUNGGU_SETERUSNYA_GANTUNG" -> "SUSPENDED";
            case "MENUNGGU_SETERUSNYA_BATAL" -> "ARCHIVED";
            default -> throw new IllegalStateException(buildWorkflowErrorMessage("next_step", currentStatus));
        };
    }

    // Tukar status dari IN PROGRESS ke MENUNGGU TINDAKAN PENGARAH (FINAL)
    // dan rekod notifikasi kepada pemohon bahawa permohonan telah dihantar ke Pengarah.
    private void requestDirectorFinalAction(Connection conn, int applicationId,
            String adminNotes, Integer changedBy) throws SQLException {
        String oldStatus = "IN_PROGRESS";
        String newStatus = "MENUNGGU_TINDAKAN_PENGARAH";
        String sql = "UPDATE applications SET status = ?, director_review_type = 'FINAL', admin_notes = ?, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = ? "
                + "WHERE id = ? AND UPPER(TRIM(status)) = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, newStatus);
            stmt.setString(2, adminNotes);
            if (changedBy == null) {
                stmt.setNull(3, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(3, changedBy);
            }
            stmt.setInt(4, applicationId);
            stmt.setString(5, oldStatus);
            if (stmt.executeUpdate() != 1) {
                throw new IllegalStateException("Status permohonan telah berubah. Sila muat semula halaman dan cuba lagi.");
            }
        }
        DashboardDataService.recordStatusHistory(conn, applicationId, oldStatus, newStatus, changedBy,
                "Dihantar kepada Pengarah untuk tindakan akhir.");
        int userId = getApplicationUserId(conn, applicationId);
        if (userId > 0) {
            String appRef = formatApplicationReference(applicationId);
            String message = TemplateService.renderNotif(
                conn,
                "NOTIF_DIRECTOR_FINAL_REVIEW_PENDING",
                Map.of("app_ref", appRef),
                "Adalah dimaklumkan bahawa permohonan " + appRef
                    + " telah dikemukakan kepada Pengarah untuk tindakan akhir. Sila rujuk dashboard bagi status terkini.");
            DashboardDataService.insertNotification(conn, userId, message, "INFO");
        }
    }

    // Fungsi umum kemas kini status permohonan oleh admin.
    // Termasuk jana no sijil bila lulus dan push notifikasi ikut status baru.
    private void updateApplicationStatus(Connection conn, int applicationId, String expectedCurrentStatus, String status,
            String adminNotes, Integer changedBy, String validUntilStr) throws SQLException {
        String oldStatus = normalizeStatus(expectedCurrentStatus);
        String sql = "UPDATE applications SET status = ?, admin_notes = ?, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = ? WHERE id = ? AND UPPER(TRIM(status)) = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, adminNotes);
            if (changedBy == null) {
                stmt.setNull(3, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(3, changedBy);
            }
            stmt.setInt(4, applicationId);
            stmt.setString(5, oldStatus);
            if (stmt.executeUpdate() != 1) {
                throw new IllegalStateException("Status permohonan telah berubah. Sila muat semula halaman dan cuba lagi.");
            }
        }

        String issuedCertificateNumber = null;
        if ("APPROVED".equals(status)) {
            ensureCertificateNumberSequenceTable(conn);
            String certNumber = generateNextCertificateNumber(conn);
            issuedCertificateNumber = certNumber;
            LocalDate validUntil;
            if (validUntilStr != null && !validUntilStr.isBlank()) {
                try {
                    validUntil = LocalDate.parse(validUntilStr);
                } catch (Exception e) {
                    validUntil = LocalDate.now().plusYears(2);
                }
            } else {
                validUntil = LocalDate.now().plusYears(2);
            }
            String certSql = "UPDATE applications SET certificate_number = ?, issued_at = CURRENT_DATE, valid_until = ? WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(certSql)) {
                ps.setString(1, certNumber);
                ps.setDate(2, Date.valueOf(validUntil));
                ps.setInt(3, applicationId);
                ps.executeUpdate();
            }
        }

        DashboardDataService.recordStatusHistory(conn, applicationId, oldStatus, status, changedBy, adminNotes);

        int userId = getApplicationUserId(conn, applicationId);
        if (userId > 0) {
            String appRef = formatApplicationReference(applicationId);
            String message;
            String type;
            if ("APPROVED".equals(status)) {
                String certRef = issuedCertificateNumber != null
                        ? issuedCertificateNumber
                        : loadCertificateNumber(conn, applicationId);
            Map<String, String> vars = new HashMap<>();
            vars.put("app_ref", appRef);
            vars.put("cert_ref", certRef == null ? "" : certRef);
            message = TemplateService.renderNotif(conn, "NOTIF_APPLICATION_APPROVED", vars,
                "Adalah dimaklumkan bahawa permohonan " + appRef
                    + " telah diluluskan. Perakuan Pendaftaran " + certRef
                    + " telah dikeluarkan. Sila rujuk dashboard untuk maklumat lanjut.");
                type = "SUCCESS";
            } else if ("REJECTED".equals(status)) {
            String notesSection = (adminNotes != null && !adminNotes.isBlank())
                ? " Sebab keputusan: " + adminNotes
                : "";
            Map<String, String> vars = new HashMap<>();
            vars.put("app_ref", appRef);
            vars.put("notes_section", notesSection);
            vars.put("admin_notes", adminNotes == null ? "" : adminNotes);
            message = TemplateService.renderNotif(conn, "NOTIF_APPLICATION_REJECTED", vars,
                "Adalah dimaklumkan bahawa permohonan " + appRef + " telah ditolak."
                    + notesSection + " Sila rujuk dashboard untuk tindakan selanjutnya.");
                type = "ERROR";
            } else if ("SUSPENDED".equals(status)) {
            message = TemplateService.renderNotif(conn, "NOTIF_APPLICATION_SUSPENDED", Map.of("app_ref", appRef),
                "Adalah dimaklumkan bahawa permohonan " + appRef
                    + " telah digantung. Sila rujuk dashboard untuk maklumat lanjut.");
                type = "WARNING";
            } else if ("ARCHIVED".equals(status)) {
            message = TemplateService.renderNotif(conn, "NOTIF_APPLICATION_ARCHIVED", Map.of("app_ref", appRef),
                "Adalah dimaklumkan bahawa permohonan " + appRef
                    + " telah dibatalkan. Sila rujuk dashboard untuk maklumat lanjut.");
                type = "WARNING";
            } else {
            Map<String, String> vars = new HashMap<>();
            vars.put("app_ref", appRef);
            vars.put("status", formatStatusLabel(status));
            message = TemplateService.renderNotif(conn, "NOTIF_APPLICATION_STATUS_GENERIC", vars,
                "Adalah dimaklumkan bahawa status permohonan " + appRef
                    + " telah dikemas kini kepada " + formatStatusLabel(status)
                    + ". Sila rujuk dashboard untuk maklumat lanjut.");
                type = "INFO";
            }
            DashboardDataService.insertNotification(conn, userId, message, type);
        }
    }

    private void ensureCertificateNumberSequenceTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS certificate_number_sequences ("
                + "sequence_year INT PRIMARY KEY, "
                + "last_sequence INT NOT NULL DEFAULT -1, "
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.executeUpdate();
        }
    }

    private String generateNextCertificateNumber(Connection conn) throws SQLException {
        int year = LocalDate.now().getYear();

        String ensureYearSql = "INSERT INTO certificate_number_sequences (sequence_year, last_sequence) "
                + "VALUES (?, -1) "
                + "ON DUPLICATE KEY UPDATE sequence_year = sequence_year";
        try (PreparedStatement stmt = conn.prepareStatement(ensureYearSql)) {
            stmt.setInt(1, year);
            stmt.executeUpdate();
        }

        String incrementSql = "UPDATE certificate_number_sequences "
                + "SET last_sequence = LAST_INSERT_ID(last_sequence + 1), updated_at = CURRENT_TIMESTAMP "
                + "WHERE sequence_year = ?";
        try (PreparedStatement stmt = conn.prepareStatement(incrementSql)) {
            stmt.setInt(1, year);
            stmt.executeUpdate();
        }

        int runningNo = 0;
        try (PreparedStatement stmt = conn.prepareStatement("SELECT LAST_INSERT_ID()")) {
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    runningNo = rs.getInt(1);
                }
            }
        }

        return String.format("JANS.%d.%03d", year, runningNo);
    }

    private String loadCertificateNumber(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT certificate_number FROM applications WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("certificate_number");
                }
            }
        }
        return "";
    }

    private int getApplicationUserId(Connection conn, int applicationId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement("SELECT user_id FROM applications WHERE id = ?")) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("user_id") : 0;
            }
        }
    }

    private void insertInProgressPresentationNotification(Connection conn, int applicationId,
            String adminNotes, String presentationDate, String presentationTime,
            String presentationVenue, String presentationMessage) throws SQLException {
        int userId = getApplicationUserId(conn, applicationId);
        if (userId <= 0) {
            return;
        }

        String appRef = formatApplicationReference(applicationId);
        Map<String, String> vars = new HashMap<>();
        vars.put("app_ref", appRef);
        vars.put("presentation_date", presentationDate == null ? "" : presentationDate);
        vars.put("presentation_time", presentationTime == null ? "" : presentationTime);
        vars.put("presentation_venue", presentationVenue == null ? "" : presentationVenue);

        String generatedMessage = TemplateService.renderNotif(
            conn,
            "NOTIF_PRESENTATION_APPLICANT",
            vars,
            "Adalah dimaklumkan bahawa sesi pembentangan bagi permohonan " + appRef + " telah dijadualkan seperti berikut:"
                + "\nTarikh: " + presentationDate
                + "\nMasa: " + presentationTime
                + "\nTempat: " + presentationVenue
                + "\nSila hadir mengikut ketetapan yang dinyatakan.");

        String finalMessage = (presentationMessage == null || presentationMessage.isBlank())
                ? generatedMessage
                : presentationMessage;

        finalMessage = finalMessage
            .replace("<", "")
            .replace(">", "")
            .trim();

        DashboardDataService.insertNotification(conn, userId, finalMessage, "PRESENTATION");
    }

    private String formatStatusLabel(String status) {
        if (status == null || status.isBlank()) {
            return "Tidak Dinyatakan";
        }
        return switch (normalizeStatus(status)) {
            case "NEW" -> "Baharu";
            case "UNDER_REVIEW" -> "Dalam Semakan";
            case "IN_PROGRESS" -> "Dalam Proses";
            case "MENUNGGU_TINDAKAN_PENGARAH" -> "Menunggu Tindakan Pengarah";
            case "DILULUSKAN_PENGARAH" -> "Diluluskan Pengarah";
            case "MENUNGGU_SETERUSNYA_DILULUSKAN" -> "Menunggu Tindakan Akhir Admin";
            case "APPROVED" -> "Diluluskan";
            case "REJECTED" -> "Ditolak";
            case "SUSPENDED" -> "Digantung";
            case "ARCHIVED" -> "Dibatalkan";
            case "KUERI" -> "Kuiri";
            default -> status.replace('_', ' ');
        };
    }

    private void suspendUserByApplication(Connection conn, int applicationId, String adminNotes) throws SQLException {
        String sql = "UPDATE users u JOIN applications a ON a.user_id = u.id "
                + "SET u.status = 'SUSPENDED', a.status = 'SUSPENDED', a.admin_notes = ?, a.reviewed_at = CURRENT_TIMESTAMP "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, adminNotes);
            stmt.setInt(2, applicationId);
            stmt.executeUpdate();
        }
    }

    private void archiveApplication(Connection conn, int applicationId, String adminNotes, Integer adminUserId) throws SQLException {
        String sql = "INSERT INTO application_archives (application_id, archived_by, archive_notes, archived_at) "
                + "VALUES (?, ?, ?, CURRENT_TIMESTAMP) "
                + "ON DUPLICATE KEY UPDATE archived_by = VALUES(archived_by), archive_notes = VALUES(archive_notes), archived_at = CURRENT_TIMESTAMP";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            if (adminUserId == null) {
                stmt.setNull(2, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(2, adminUserId);
            }
            stmt.setString(3, adminNotes);
            stmt.executeUpdate();
        }
    }

    private void unarchiveApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "DELETE FROM application_archives WHERE application_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.executeUpdate();
        }
    }

    private boolean isArchived(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT 1 FROM application_archives WHERE application_id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean canArchiveApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, aa.application_id AS archived_ref "
                + "FROM applications a "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                return rs.getObject("archived_ref") == null;
            }
        }
    }

    private void ensureApplicationArchiveTable(Connection conn) throws SQLException {
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

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private Long parseLong(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String trim(String value) {
        return value != null ? value.trim() : null;
    }

    // -------------------------------------------------------------------------
    // Audit logging
    // -------------------------------------------------------------------------

    private void insertAdminAuditLog(Connection conn, Integer adminId, String action,
            String details, String ip) {
        if (adminId == null) return;
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
            LOGGER.warning("Failed to write audit log [" + action + "]: " + e.getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // Email notifications to applicant on status change
    // -------------------------------------------------------------------------

    private void sendStatusEmail(HttpServletRequest request, Connection conn,
            int applicationId, String newStatus, String adminNotes) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) return; // SMTP not configured

        try {
            // Fetch applicant email and application details for template rendering.
            String emailAddr = null;
            String fullName  = null;
            String product   = null;
            String certRef   = null;
            String submittedDate = "";
            String applicationType = "BAHARU";
            String sql = "SELECT u.email, u.full_name, a.product_name, a.certificate_number, "
                    + "DATE_FORMAT(a.submitted_at, '%d/%m/%Y') AS submitted_date, "
                    + "COALESCE(ad.application_type, 'BAHARU') AS application_type "
                    + "FROM applications a "
                    + "JOIN users u ON u.id = a.user_id "
                    + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                    + "WHERE a.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, applicationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        emailAddr = rs.getString("email");
                        fullName  = rs.getString("full_name");
                        product   = rs.getString("product_name");
                        certRef   = rs.getString("certificate_number");
                        submittedDate = rs.getString("submitted_date");
                        applicationType = rs.getString("application_type");
                    }
                }
            }

            if (emailAddr == null || emailAddr.isBlank()) return;

            int    smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls  = Boolean.parseBoolean(getContextParam(request, "smtp.tls",  "true"));
            String smtpUser  = getContextParam(request, "smtp.username", "");
            String smtpPass  = getContextParam(request, "smtp.password", "");
            String smtpFrom  = getContextParam(request, "smtp.from", smtpUser);

            String templateKey;
            String fallbackSubject;
            String fallbackBody;
            String appRef = formatApplicationReference(applicationId);
            String normalizedType = normalizeApplicationTypeLabel(applicationType);
            if ("APPROVED".equals(newStatus)) {
                templateKey = "APPLICATION_APPROVED";
                fallbackSubject = "PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR (" + normalizedType + ")";
                fallbackBody = "<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR (" + escapeHtml(normalizedType) + ")</strong></p>"
                        + "<p>Dengan hormatnya saya merujuk surat tuan/puan rujukan " + escapeHtml(appRef)
                        + " bertarikh " + escapeHtml(submittedDate) + " mengenai perkara di atas.</p>"
                        + "<p>Sukacita dimaklumkan bahawa permohonan ini adalah diluluskan dan didaftarkan untuk kegunaan Jabatan tertakluk kepada syarat serta ketetapan yang sedang berkuat kuasa.</p>"
                        + (certRef != null && !certRef.isBlank() ? "<p>No. Perakuan Pendaftaran: <strong>" + escapeHtml(certRef) + "</strong></p>" : "")
                        + "<p>Tuan/puan boleh log masuk ke sistem untuk melihat dan mencetak perakuan pendaftaran yang berkaitan.</p>"
                        + "<p>Sekian, terima kasih.</p>"
                        + "<p>Saya yang menjalankan amanah,</p>"
                        + "<p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p>"
                        + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>";
            } else if ("REJECTED".equals(newStatus)) {
                templateKey = "APPLICATION_REJECTED";
                fallbackSubject = "PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR (" + normalizedType + ")";
                fallbackBody = "<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR (" + escapeHtml(normalizedType) + ")</strong></p>"
                        + "<p>Dengan hormatnya saya merujuk surat tuan/puan rujukan " + escapeHtml(appRef)
                        + " bertarikh " + escapeHtml(submittedDate) + " mengenai perkara di atas.</p>"
                        + "<p>Setelah semakan dibuat, pihak Jabatan memutuskan bahawa permohonan ini adalah ditolak dan tidak akan diproses ke peringkat seterusnya.</p>"
                        + (adminNotes != null && !adminNotes.isBlank() ? "<p>Catatan: " + escapeHtml(adminNotes) + "</p>" : "")
                        + "<p>Sekian, terima kasih.</p>"
                        + "<p>Saya yang menjalankan amanah,</p>"
                        + "<p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p>"
                        + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>";
            } else {
                return; // No email for other statuses
            }

            Map<String, String> vars = new LinkedHashMap<>();
            vars.put("full_name", escapeHtml(fullName));
            vars.put("applicant_name", escapeHtml(fullName));
            vars.put("product_name", escapeHtml(product));
            vars.put("app_ref", escapeHtml(appRef));
            vars.put("no_rujukan_surat", escapeHtml(appRef));
            vars.put("tarikh_surat", escapeHtml(submittedDate));
            vars.put("application_type_label", escapeHtml(normalizedType));
            vars.put("cert_ref", escapeHtml(certRef));
            vars.put("admin_notes", escapeHtml(adminNotes));
            vars.put("status_label_lower", "REJECTED".equals(newStatus) ? "ditolak" : "diluluskan");

            String subject = TemplateService.renderEmailSubject(conn, templateKey, vars, fallbackSubject);
            String bodyContent = TemplateService.renderEmailBody(conn, templateKey, vars, fallbackBody);

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            boolean sent = emailUtil.sendHtml(emailAddr, subject, bodyContent);
            if (sent) {
                LOGGER.info("Status email sent to " + emailAddr + " for application PPP" + String.format("%03d", applicationId));
            }
        } catch (Exception e) {
            // Email failure should not block the admin action
            LOGGER.warning("Failed to send status email for application PPP" + String.format("%03d", applicationId) + ": " + e.getMessage());
        }
    }

    private void sendInProgressPresentationEmail(HttpServletRequest request, Connection conn,
            int applicationId, String presentationDate, String presentationTime,
            String presentationVenue, String presentationMessage) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) return; // SMTP not configured

        try {
            String emailAddr = null;
            String fullName = null;
            String product = null;
            String sql = "SELECT u.email, u.full_name, a.product_name "
                    + "FROM applications a JOIN users u ON u.id = a.user_id WHERE a.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, applicationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        emailAddr = rs.getString("email");
                        fullName = rs.getString("full_name");
                        product = rs.getString("product_name");
                    }
                }
            }

            if (emailAddr == null || emailAddr.isBlank()) return;

            int smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls = Boolean.parseBoolean(getContextParam(request, "smtp.tls", "true"));
            String smtpUser = getContextParam(request, "smtp.username", "");
            String smtpPass = getContextParam(request, "smtp.password", "");
            String smtpFrom = getContextParam(request, "smtp.from", smtpUser);

            String generatedMessage = "Pemohon dimaklumkan untuk bersedia dan menghadiri sesi Pembentangan Produk Air yang didaftarkan."
                    + "\nTarikh: " + presentationDate
                    + "\nMasa: " + presentationTime
                    + "\nTempat: " + presentationVenue;
            String finalMessage = (presentationMessage == null || presentationMessage.isBlank())
                    ? generatedMessage
                    : presentationMessage;

                String appRef = formatApplicationReference(applicationId);
                Map<String, String> vars = new LinkedHashMap<>();
                vars.put("full_name", escapeHtml(fullName));
                vars.put("app_ref", escapeHtml(appRef));
                vars.put("no_rujukan_surat", escapeHtml(appRef));
                vars.put("product_name", escapeHtml(product));
                vars.put("presentation_date", escapeHtml(presentationDate));
                vars.put("presentation_time", escapeHtml(presentationTime));
                vars.put("presentation_venue", escapeHtml(presentationVenue));
                vars.put("presentation_message", escapeHtml(finalMessage));
                vars.put("presentation_message_html", buildPresentationMessageHtml(finalMessage));

                String fallbackSubject = "UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR BAGI " + appRef;
                String fallbackBody = "<p>Tuan/Puan " + escapeHtml(fullName) + ",</p>"
                    + "<p><strong>UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR BAGI " + escapeHtml(appRef) + "</strong></p>"
                    + "<p>Dengan hormatnya perkara di atas adalah dirujuk.</p>"
                    + "<p>2. Sukacita dimaklumkan bahawa permohonan bagi produk <strong>" + escapeHtml(product)
                    + "</strong> telah dijadualkan untuk sesi pembentangan pada ketetapan berikut:</p>"
                    + "<p>Tarikh : " + escapeHtml(presentationDate) + "<br>Masa : " + escapeHtml(presentationTime)
                    + "<br>Tempat : " + escapeHtml(presentationVenue) + "</p>"
                    + "<p>3. Maklumat tambahan berkaitan sesi pembentangan adalah seperti berikut:</p>"
                    + buildPresentationMessageHtml(finalMessage)
                    + "<p>4. Tuan/puan adalah dimohon untuk memastikan kehadiran mengikut ketetapan yang dinyatakan.</p>"
                    + "<p>Sekian, terima kasih.</p>"
                    + "<p>Saya yang menjalankan amanah,</p>"
                    + "<p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p>"
                    + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>";
                String subject = TemplateService.renderEmailSubject(conn, "PRESENTATION_APPLICANT", vars, fallbackSubject);
                String bodyContent = TemplateService.renderEmailBody(conn, "PRESENTATION_APPLICANT", vars, fallbackBody);

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            boolean sent = emailUtil.sendHtml(emailAddr, subject, bodyContent);
            if (sent) {
                LOGGER.info("In-progress presentation email sent to " + emailAddr
                        + " for application PPP" + String.format("%03d", applicationId));
            }
        } catch (Exception e) {
            // Email failure should not block admin action
            LOGGER.warning("Failed to send in-progress email for application PPP"
                    + String.format("%03d", applicationId) + ": " + e.getMessage());
        }
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private String buildHtmlLink(String url, String label) {
        if (url == null || url.isBlank()) {
            return "";
        }
        String safeUrl = escapeHtml(url);
        String safeLabel = escapeHtml(label == null || label.isBlank() ? url : label);
        return "<a href=\"" + safeUrl + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + safeLabel + "</a>";
    }

    private String buildPresentationMessageHtml(String message) {
        return "<div style=\"white-space:pre-wrap;margin:0;padding:12px;border:1px solid #d7dbe0;border-radius:8px;background:#f8fafc;\">"
                + escapeHtml(message)
                + "</div>";
    }

    private String formatApplicationReference(int applicationId) {
        return "PPP" + String.format("%03d", applicationId);
    }

    private String normalizeApplicationTypeLabel(String rawValue) {
        if (rawValue == null || rawValue.isBlank()) {
            return "BAHARU";
        }
        String normalized = rawValue.trim().toUpperCase(Locale.ROOT);
        if ("PEMBAHARUAN".equals(normalized) || "PEMBAHARUAN SEMULA".equals(normalized)) {
            return "PEMBAHARUAN";
        }
        return "BAHARU";
    }

    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

}


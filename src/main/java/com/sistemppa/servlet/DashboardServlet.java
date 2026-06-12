package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.util.EmailUtil;
import com.sistemppa.util.UserDisplayIdUtil;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class DashboardServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());
    private static final String ANNOUNCEMENT_IMAGE_ENDPOINT = "/announcement-images/";
    private static final int ADMIN_APPLICATION_LIMIT = 50;
    private static final int DASHBOARD_PRODUCT_LIMIT = 8;
    private static final int DASHBOARD_ANNOUNCEMENT_LIMIT = 20;
    private static final int HOMEPAGE_ANNOUNCEMENT_LIMIT = 5;
    private static final long ANNOUNCEMENT_MAX_IMAGE_SIZE_BYTES = 10L * 1024L * 1024L;
        private static final String[] KSPP_QUESTIONS = new String[] {
            "Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?",
            "Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal/pemilik produk masih sah?",
            "Adakah dokumen jaminan produk masih sah?",
            "Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?",
            "Adakah mudah dihubungi pada bila-bila masa?",
            "Adakah jadual penghantaran produk ke lokasi dipatuhi?",
            "Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?",
            "Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?",
            "Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?",
            "Adakah amalan pelaksanaan kerja mengurangkan kesan/impak negatif terhadap alam sekitar dipatuhi?",
            "Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?",
            "Adakah pemasangan produk dieselia/dipantau sehingga selesai?",
            "Adakah pengujian dan pentauliahan produk diasakna sehingga selesai?",
            "Adakah produk yang rosak diganti ataupun dibaiki dengan segera?",
            "Adakah Manual Operasi diberikan?",
            "Adakah latihan operasi dan senggara produk diberikan?",
            "Adakah produk yang dibekalkan memenuhi spesifikasi yang dititikrafkan, berfungsi dengan baik dan tidak ada kecacatan?",
            "Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)",
            "Adakah produk mempunyai rekod prestasi yang tidak memuaskan/rosak dalam tempoh tanggungan kecacatan?",
            "Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan."
        };

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer userId = (Integer) session.getAttribute("user_id");
        String role = (String) session.getAttribute("role");

        try (Connection conn = DatabaseConfig.getConnection()) {
            if ("ADMIN".equals(role)) {
                Long downloadId = parseLong(request.getParameter("kpp_download_id"));
                if (downloadId != null) {
                    handleKppSubmissionDownload(conn, downloadId, response);
                    return;
                }

                if ("1".equals(request.getParameter("announcement_saved"))) {
                    request.setAttribute("announcement_success", "Pengumuman berjaya disimpan.");
                }
                if ("1".equals(request.getParameter("announcement_deleted"))) {
                    request.setAttribute("announcement_success", "Pengumuman berjaya dihapus.");
                }
                loadAdminDashboard(conn, request);
                request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                return;
            }

            loadUserDashboard(conn, userId, request);
            request.getRequestDispatcher("/user-dashboard.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String requestContentType = request.getContentType();
        if (requestContentType != null
                && requestContentType.toLowerCase(java.util.Locale.ROOT).contains("application/json")) {
            JsonObject requestBody = parseJsonRequestBody(request);
            if ("send_kpp_emails".equalsIgnoreCase(getJsonString(requestBody, "action"))) {
                handleKppEmailSend(request, response, requestBody);
                return;
            }
        }

        String action = trim(request.getParameter("announcement_action"));
        String kppAction = trim(request.getParameter("kpp_submission_action"));
        String maintenanceAction = trim(request.getParameter("maintenance_action"));
        Integer userId = (Integer) session.getAttribute("user_id");

        String title = trim(request.getParameter("announcement_title"));
        String content = trim(request.getParameter("announcement_content"));
        String existingImageUrl = trim(request.getParameter("announcement_existing_image_url"));
        boolean isActive = "on".equalsIgnoreCase(request.getParameter("announcement_active"));

        if (maintenanceAction != null && !maintenanceAction.isBlank()) {
            boolean maintenanceEnabled;
            if ("enable".equalsIgnoreCase(maintenanceAction)) {
                maintenanceEnabled = true;
            } else if ("disable".equalsIgnoreCase(maintenanceAction)) {
                maintenanceEnabled = false;
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard?maintenance=unchanged");
                return;
            }

            request.getServletContext().setAttribute("maintenanceMode", maintenanceEnabled);
            String maintenanceQuery = maintenanceEnabled ? "enabled" : "disabled";
            response.sendRedirect(request.getContextPath() + "/dashboard?maintenance=" + maintenanceQuery);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            if (kppAction != null && !kppAction.isBlank()) {
                Long submissionId = parseLong(request.getParameter("kpp_submission_id"));
                String kppSearch = trim(request.getParameter("kpp_q"));
                boolean showArchived = "1".equals(request.getParameter("kpp_show_archived"));
                String redirectBase = request.getContextPath() + "/dashboard";
                StringBuilder redirectQueryBuilder = new StringBuilder();
                if (kppSearch != null && !kppSearch.isBlank()) {
                    redirectQueryBuilder.append("kpp_q=")
                            .append(java.net.URLEncoder.encode(kppSearch, StandardCharsets.UTF_8));
                }
                if (showArchived) {
                    if (redirectQueryBuilder.length() > 0) {
                        redirectQueryBuilder.append("&");
                    }
                    redirectQueryBuilder.append("kpp_show_archived=1");
                }
                String redirectQuery = redirectQueryBuilder.length() == 0 ? "" : "?" + redirectQueryBuilder;

                if (submissionId == null) {
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }

                if ("archive".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.archiveKppGuestSubmission(conn, submissionId);
                    insertAdminAuditLog(conn, userId, "ARCHIVE_KPP_SUBMISSION",
                            "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " arkib borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }
                if ("unarchive".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.unarchiveKppGuestSubmission(conn, submissionId);
                    insertAdminAuditLog(conn, userId, "UNARCHIVE_KPP_SUBMISSION",
                            "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " keluarkan arkib borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }
                if ("delete".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.deleteKppGuestSubmission(conn, submissionId);
                    insertAdminAuditLog(conn, userId, "DELETE_KPP_SUBMISSION",
                            "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " padam borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }

                response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                return;
            }

            if (action == null || action.isBlank()) {
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            if ("create_announcement".equals(action)) {
                if (title == null || title.isBlank() || content == null || content.isBlank()) {
                    request.setAttribute("announcement_error", "Tajuk dan kandungan pengumuman wajib diisi.");
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }

                String imageUrl;
                try {
                    imageUrl = storeAnnouncementImage(request, null);
                } catch (IllegalStateException | ServletException | IOException ex) {
                    LOGGER.warning("Announcement image upload failed: " + ex.getMessage());
                    request.setAttribute("announcement_error", resolveUploadErrorMessage(ex));
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.createAnnouncement(conn, title, content, imageUrl, isActive, userId);
                insertAdminAuditLog(conn, userId, "CREATE_ANNOUNCEMENT",
                    "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " cipta pengumuman: " + title,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_saved=1#announcementPanel");
                return;
            }

            if ("update_announcement".equals(action)) {
                Integer announcementId = parseInteger(request.getParameter("announcement_id"));
                if (announcementId == null) {
                    request.setAttribute("announcement_error", "ID pengumuman tidak sah.");
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }

                if (title == null || title.isBlank() || content == null || content.isBlank()) {
                    request.setAttribute("announcement_error", "Tajuk dan kandungan pengumuman wajib diisi.");
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    request.setAttribute("announcement_edit_id", announcementId);
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }

                String imageUrl;
                try {
                    imageUrl = storeAnnouncementImage(request, existingImageUrl);
                } catch (IllegalStateException | ServletException | IOException ex) {
                    LOGGER.warning("Announcement image update failed: " + ex.getMessage());
                    request.setAttribute("announcement_error", resolveUploadErrorMessage(ex));
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    request.setAttribute("announcement_edit_id", announcementId);
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.updateAnnouncement(conn, announcementId, title, content, imageUrl, isActive, userId);
                insertAdminAuditLog(conn, userId, "UPDATE_ANNOUNCEMENT",
                    "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " kemas kini pengumuman #" + announcementId + ": " + title,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_saved=1#announcementPanel");
                return;
            }

            if ("delete_announcement".equals(action)) {
                Integer announcementId = parseInteger(request.getParameter("announcement_id"));
                if (announcementId == null) {
                    request.setAttribute("announcement_error", "ID pengumuman tidak sah.");
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.deleteAnnouncement(conn, announcementId);
                insertAdminAuditLog(conn, userId, "DELETE_ANNOUNCEMENT",
                    "Admin " + UserDisplayIdUtil.format(userId, "ADMIN") + " padam pengumuman #" + announcementId,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_deleted=1#announcementPanel");
                return;
            }

            request.setAttribute("announcement_error", "Tindakan pengumuman tidak sah.");
            loadAdminDashboard(conn, request);
            request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    private void loadAdminDashboard(Connection conn, HttpServletRequest request) throws SQLException {
        String search = trim(request.getParameter("q"));
        String status = toStatusOptionValue(trim(request.getParameter("status")));
        String dateFrom = trim(request.getParameter("date_from"));
        String dateTo = trim(request.getParameter("date_to"));
        String kppSearch = trim(request.getParameter("kpp_q"));
        boolean includeArchivedKpp = "1".equals(request.getParameter("kpp_show_archived"));

        Map<String, Integer> stats = DashboardDataService.loadAdminStats(conn);
        for (Map.Entry<String, Integer> entry : stats.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        request.setAttribute("search_query", search == null ? "" : search);
        request.setAttribute("selected_status", status == null ? "" : status);
        request.setAttribute("date_from", dateFrom == null ? "" : dateFrom);
        request.setAttribute("date_to", dateTo == null ? "" : dateTo);
        request.setAttribute("pending_applications",
                DashboardDataService.loadApplications(conn, search, status, dateFrom, dateTo, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("filtered_application_count",
                DashboardDataService.countApplications(conn, search, status, dateFrom, dateTo));
        request.setAttribute("registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, false, 0));
        request.setAttribute("new_registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, true, 0));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("kpp_search_query", kppSearch == null ? "" : kppSearch);
        request.setAttribute("kpp_show_archived", includeArchivedKpp);
        request.setAttribute("kpp_guest_submissions",
            DashboardDataService.loadKppGuestSubmissions(conn, 50, kppSearch, includeArchivedKpp));
        request.setAttribute("kpp_contacts", DashboardDataService.loadKppContacts(conn));
        request.setAttribute("admin_audit_logs",
            DashboardDataService.loadRecentAdminAuditLogs(conn, 15));

        List<Map<String, Object>> announcements = DashboardDataService.loadAllAnnouncements(conn, DASHBOARD_ANNOUNCEMENT_LIMIT);
        request.setAttribute("announcements", announcements);

        Integer editId = parseInteger(request.getParameter("announcement_id"));
        if (editId != null) {
            Map<String, Object> editing = DashboardDataService.loadAnnouncementById(conn, editId);
            if (!editing.isEmpty()) {
                request.setAttribute("announcement_editing", editing);
            }
        }

        if (request.getAttribute("announcement_form_title") == null) {
            request.setAttribute("announcement_form_title", "");
        }
        if (request.getAttribute("announcement_form_content") == null) {
            request.setAttribute("announcement_form_content", "");
        }
        if (request.getAttribute("announcement_form_active") == null) {
            request.setAttribute("announcement_form_active", Boolean.TRUE);
        }
        if (request.getAttribute("announcement_form_image_url") == null) {
            request.setAttribute("announcement_form_image_url", "");
        }
    }

    private void loadUserDashboard(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        Map<String, Object> user = DashboardDataService.loadUserSummary(conn, userId);
        for (Map.Entry<String, Object> entry : user.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        int totalApplications = DashboardDataService.countUserApplications(conn, userId);
        int pageSize = 10;
        int page = 1;
        try {
            String pageParam = request.getParameter("appPage");
            if (pageParam != null && !pageParam.isBlank()) {
                page = Math.max(1, Integer.parseInt(pageParam.trim()));
            }
        } catch (NumberFormatException ignored) { }
        int totalPages = (int) Math.ceil((double) totalApplications / pageSize);
        if (totalPages < 1) totalPages = 1;
        if (page > totalPages) page = totalPages;

        request.setAttribute("application_count", totalApplications);
        request.setAttribute("pending_count", DashboardDataService.countPendingUserApplications(conn, userId));
        request.setAttribute("applications", DashboardDataService.loadUserApplicationsPaged(conn, userId, page, pageSize));
        request.setAttribute("current_page", page);
        request.setAttribute("total_pages", totalPages);
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("product_count", DashboardDataService.countProducts(conn, null, null));
        request.setAttribute("account_status", user.get("status"));
        request.setAttribute("last_login", request.getSession(false) != null ? request.getSession(false).getAttribute("login_time") : null);
        request.setAttribute("unread_notification_count", DashboardDataService.countUnreadNotifications(conn, userId));
        Map<String, Object> presentationPopup = DashboardDataService.loadLatestUnreadNotificationByType(conn, userId, "PRESENTATION");
        request.setAttribute("presentation_popup", presentationPopup);
        request.setAttribute("notifications", DashboardDataService.loadUserNotifications(conn, userId, 10));
        DashboardDataService.markAllNotificationsRead(conn, userId);
        request.setAttribute("announcements",
            DashboardDataService.loadActiveAnnouncements(conn, HOMEPAGE_ANNOUNCEMENT_LIMIT));
        request.setAttribute("status_history",
            DashboardDataService.loadUserApplicationStatusHistory(conn, userId));
    }

    private void handleKppEmailSend(HttpServletRequest request, HttpServletResponse response, JsonObject requestBody)
            throws IOException {
        response.setContentType("application/json;charset=UTF-8");

        JsonArray emails = requestBody != null && requestBody.has("emails") && requestBody.get("emails").isJsonArray()
                ? requestBody.getAsJsonArray("emails")
                : new JsonArray();
        if (emails.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(jsonMessage(false, "Tiada email KPP untuk dihantar.", 0, 0));
            return;
        }

        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonMessage(false, "SMTP belum dikonfigurasi. Sila isi tetapan smtp.host dan butiran berkaitan dalam web.xml.", 0, emails.size()));
            return;
        }

        int smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
        boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
        boolean smtpTls = Boolean.parseBoolean(getContextParam(request, "smtp.tls", "true"));
        String smtpUser = getContextParam(request, "smtp.username", "");
        String smtpPass = getContextParam(request, "smtp.password", "");
        String smtpFrom = getContextParam(request, "smtp.from", smtpUser);

        if (isPlaceholderSmtp(smtpHost, smtpUser, smtpPass, smtpFrom)
            || (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank()))) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonMessage(false,
                "SMTP belum dikonfigurasi dengan betul. Sila semak smtp.host/smtp.username/smtp.password/smtp.from dalam web.xml.",
                0,
                emails.size()));
            return;
        }

        EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
        int sentCount = 0;
        int failedCount = 0;

        for (JsonElement emailElement : emails) {
            if (emailElement == null || !emailElement.isJsonObject()) {
                failedCount++;
                continue;
            }

            JsonObject emailObject = emailElement.getAsJsonObject();
            String to = getJsonString(emailObject, "to");
            String subject = getJsonString(emailObject, "subject");
            String body = getJsonString(emailObject, "body");

            if (to.isBlank() || subject.isBlank() || body.isBlank()) {
                failedCount++;
                continue;
            }

            boolean sent = emailUtil.sendHtml(to, subject, toHtmlEmailBody(body));
            if (sent) {
                sentCount++;
            } else {
                failedCount++;
            }
        }

        boolean success = sentCount > 0 && failedCount == 0;
        if (sentCount == 0) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            String failureMessage = "Semua email KPP gagal dihantar.";
            if (smtpHost.toLowerCase(java.util.Locale.ROOT).contains("office365")
                    || smtpHost.toLowerCase(java.util.Locale.ROOT).contains("outlook")) {
                failureMessage = "Semua email KPP gagal dihantar. Untuk Outlook/Microsoft 365, pastikan SMTP AUTH diaktifkan pada mailbox dan kelayakan smtp.username/smtp.password adalah betul.";
            }
            response.getWriter().write(jsonMessage(false, failureMessage, sentCount, failedCount));
            return;
        }

        String message = failedCount == 0
                ? ("Berjaya menghantar " + sentCount + " email KPP.")
                : ("Berjaya menghantar " + sentCount + " email KPP. " + failedCount + " email gagal dihantar.");

        HttpSession session = request.getSession(false);
        Integer adminId = session == null ? null : (Integer) session.getAttribute("user_id");
        try (Connection conn = DatabaseConfig.getConnection()) {
            insertAdminAuditLog(conn, adminId, "SEND_KPP_EMAIL",
                    "Admin " + UserDisplayIdUtil.format(adminId == null ? 0 : adminId, "ADMIN")
                            + " hantar email KPP. Berjaya: " + sentCount + ", gagal: " + failedCount,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.warning("Failed to write SEND_KPP_EMAIL audit log: " + e.getMessage());
        }

        response.getWriter().write(jsonMessage(success, message, sentCount, failedCount));
    }

    private void insertAdminAuditLog(Connection conn, Integer adminId, String action,
            String details, String ip) {
        if (adminId == null) {
            return;
        }
        try {
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

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private JsonObject parseJsonRequestBody(HttpServletRequest request) throws IOException {
        String body = request.getReader().lines().collect(java.util.stream.Collectors.joining());
        if (body == null || body.isBlank()) {
            return new JsonObject();
        }

        try {
            JsonElement root = JsonParser.parseString(body);
            if (root != null && root.isJsonObject()) {
                return root.getAsJsonObject();
            }
        } catch (Exception ignored) {
            // Fall through to empty object.
        }
        return new JsonObject();
    }

    private String getJsonString(JsonObject object, String key) {
        if (object == null || key == null || key.isBlank() || !object.has(key)) {
            return "";
        }

        JsonElement element = object.get(key);
        if (element == null || element.isJsonNull()) {
            return "";
        }

        String value = element.isJsonPrimitive() ? element.getAsString() : element.toString();
        return value == null ? "" : value.trim();
    }

    private String toHtmlEmailBody(String plainText) {
        String normalized = plainText == null ? "" : plainText;
        normalized = normalized.replace("\r\n", "\n").replace("\r", "\n");

        Pattern urlPattern = Pattern.compile("(https?://\\S+)", Pattern.CASE_INSENSITIVE);
        Matcher matcher = urlPattern.matcher(normalized);
        Map<String, String> links = new LinkedHashMap<>();
        StringBuffer marked = new StringBuffer();
        int index = 0;
        while (matcher.find()) {
            String rawUrl = matcher.group(1);
            String cleanedUrl = trimTrailingUrlPunctuation(rawUrl);
            String suffix = rawUrl.substring(cleanedUrl.length());
            String key = "__SPPA_LINK_" + index++ + "__";
            links.put(key, cleanedUrl);
            matcher.appendReplacement(marked, Matcher.quoteReplacement(key + suffix));
        }
        matcher.appendTail(marked);

        String safe = escapeHtml(marked.toString()).replace("\n", "<br>");
        for (Map.Entry<String, String> entry : links.entrySet()) {
            String url = entry.getValue();
            String escapedUrl = escapeHtml(url);
            String anchor = "<a href=\"" + escapedUrl + "\" target=\"_blank\" rel=\"noopener noreferrer\">"
                    + escapedUrl
                    + "</a>";
            safe = safe.replace(entry.getKey(), anchor);
        }

        return "<div style=\"font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:14px;line-height:1.6;color:#183244;\">"
                + safe
                + "</div>";
    }

    private String trimTrailingUrlPunctuation(String url) {
        if (url == null) {
            return "";
        }
        int end = url.length();
        while (end > 0) {
            char c = url.charAt(end - 1);
            if (c == '.' || c == ',' || c == ';' || c == ')' || c == ']' || c == '!' || c == '?') {
                end--;
                continue;
            }
            break;
        }
        return end <= 0 ? url : url.substring(0, end);
    }

    private String jsonMessage(boolean success, String message, int sentCount, int failedCount) {
        JsonObject result = new JsonObject();
        result.addProperty("success", success);
        result.addProperty("message", message == null ? "" : message);
        result.addProperty("sentCount", sentCount);
        result.addProperty("failedCount", failedCount);
        return result.toString();
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private String escapeHtml(String text) {
        if (text == null) {
            return "";
        }
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private boolean isPlaceholderSmtp(String smtpHost, String smtpUser, String smtpPass, String smtpFrom) {
        String host = smtpHost == null ? "" : smtpHost.trim().toLowerCase(java.util.Locale.ROOT);
        String user = smtpUser == null ? "" : smtpUser.trim().toLowerCase(java.util.Locale.ROOT);
        String pass = smtpPass == null ? "" : smtpPass.trim().toLowerCase(java.util.Locale.ROOT);
        String from = smtpFrom == null ? "" : smtpFrom.trim().toLowerCase(java.util.Locale.ROOT);

        return host.contains("example")
                || user.contains("your-email")
                || pass.contains("your-app-password")
            || pass.contains("change_me")
                || from.contains("your-email");
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

    private String toStatusOptionValue(String status) {
        if (status == null || status.isBlank()) {
            return "";
        }
        String normalized = status.trim().toUpperCase(java.util.Locale.ROOT).replace(' ', '_');
        if ("APPROVED".equals(normalized) || "DILULUSKAN".equals(normalized)) {
            return "DILULUSKAN";
        }
        if ("REJECTED".equals(normalized) || "DITOLAK".equals(normalized)) {
            return "DITOLAK";
        }
        if ("SUSPENDED".equals(normalized) || "DIGANTUNG".equals(normalized)) {
            return "DIGANTUNG";
        }
        if ("DRAFT".equals(normalized) || "DRAF".equals(normalized)) {
            return "DRAF";
        }
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized)) {
            return "DIARKIB";
        }
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized)) {
            return "DALAM_SEMAKAN";
        }
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized)) {
            return "DALAM_PROSES";
        }
        return normalized;
    }

    private void handleKppSubmissionDownload(Connection conn, long submissionId, HttpServletResponse response)
            throws SQLException, IOException {
        Map<String, Object> row = DashboardDataService.loadKppGuestSubmissionById(conn, submissionId);
        if (row == null || row.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Borang KPP tidak ditemui.");
            return;
        }

        String actionType = safePdfValue(row.get("action_type"));
        String filePrefix;
        if ("KSPP".equalsIgnoreCase(actionType)) {
            filePrefix = "BORANG-KSPP";
        } else if ("UJPPP".equalsIgnoreCase(actionType)) {
            filePrefix = "BORANG-UJPPP";
        } else {
            filePrefix = "BORANG-KSPP-UJPPP";
        }
        String fileName = filePrefix + "-" + submissionId + "-" + System.currentTimeMillis() + ".pdf";
        byte[] pdfBytes;
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            writeKppSubmissionPdf(row, output);
            pdfBytes = output.toByteArray();
        } catch (DocumentException e) {
            LOGGER.severe("Failed to generate KPP submission PDF: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal menjana PDF borang KPP.");
            return;
        }

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
        response.setContentLength(pdfBytes.length);
        response.getOutputStream().write(pdfBytes);
    }

    private void writeKppSubmissionPdf(Map<String, Object> row, ByteArrayOutputStream output)
            throws DocumentException, IOException {
        Document document = new Document(PageSize.A4, 36, 36, 36, 36);
        PdfWriter.getInstance(document, output);
        document.open();

        BaseFont baseFont = BaseFont.createFont("Helvetica", BaseFont.CP1252, false);
        Font titleFont = new Font(baseFont, 15, Font.BOLD);
        Font borangFont = new Font(baseFont, 12, Font.BOLD | Font.UNDERLINE);
        Font sectionFont = new Font(baseFont, 11, Font.BOLD);
        Font labelFont = new Font(baseFont, 9, Font.BOLD);
        Font bodyFont = new Font(baseFont, 9, Font.NORMAL);

        String actionType = safePdfValue(row.get("action_type"));
        boolean showKspp = "KSPP".equalsIgnoreCase(actionType) || "KSPP_UJPPP".equalsIgnoreCase(actionType);
        boolean showUjppp = "UJPPP".equalsIgnoreCase(actionType) || "KSPP_UJPPP".equalsIgnoreCase(actionType);
        String payload = String.valueOf(row.get("form_payload") == null ? "" : row.get("form_payload"));
        JsonObject payloadObject = parsePayloadObject(payload);

        String borangTitle;
        if (showKspp && showUjppp) {
            borangTitle = "BORANG KSPP / BORANG UJPPP";
        } else if (showKspp) {
            borangTitle = "BORANG KSPP";
        } else if (showUjppp) {
            borangTitle = "BORANG UJPPP";
        } else {
            borangTitle = "BORANG KPP";
        }
        document.addTitle(borangTitle);
        document.add(new Paragraph(borangTitle, titleFont));
        document.add(new Paragraph(" ", bodyFont));

        Map<String, String> respondentFields = new LinkedHashMap<>();
        respondentFields.put("Nama Penuh", getPayloadValue(payloadObject, "f_respondent_name"));
        respondentFields.put("Cawangan / Jabatan Air Daerah", getPayloadValue(payloadObject, "f_respondent_branch"));
        respondentFields.put("Jawatan Hakiki & Gred", getPayloadValue(payloadObject, "f_respondent_position_grade"));
        respondentFields.put("Gelaran Jawatan", getPayloadValue(payloadObject, "f_respondent_title"));
        respondentFields.put("No. Telefon", getPayloadValue(payloadObject, "f_phone"));
        respondentFields.put("Emel Rasmi Kerajaan", getPayloadValue(payloadObject, "f_respondent_official_email"));
        respondentFields.put("Tempoh Berkhidmat", getPayloadValue(payloadObject, "f_respondent_service_period"));
        addSectionTable(document, "Bahagian A: Maklumat Responden", respondentFields, sectionFont, labelFont, bodyFont);

        if (showKspp) {
            document.add(new Paragraph("BORANG KSPP", borangFont));
            document.add(new Paragraph(" ", bodyFont));

            Map<String, String> ksppB = new LinkedHashMap<>();
            ksppB.put("Nama Produk", getPayloadValue(payloadObject, "f_kspp_product_name"));
            ksppB.put("Jenama", getPayloadValue(payloadObject, "f_kspp_brand"));
            ksppB.put("Perihal Produk (Model/Kelas/Saiz)", getPayloadValue(payloadObject, "f_kspp_product_desc"));
            ksppB.put("Tarikh Mula & Siap", getPayloadValue(payloadObject, "f_kspp_start_end_date"));
            ksppB.put("% Siap", getPayloadValue(payloadObject, "f_kspp_completion_percent"));
            addSectionTable(document,
                    "Bahagian B: Maklumat Produk",
                    ksppB,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ksppC = new LinkedHashMap<>();
            ksppC.put("Nama Pembekal", getPayloadValue(payloadObject, "f_kspp_supplier_name"));
            ksppC.put("Nama Produk", getPayloadValue(payloadObject, "f_kspp_supplier_product_name"));
            ksppC.put("Jenama", getPayloadValue(payloadObject, "f_kspp_supplier_brand"));
            ksppC.put("Perihal Produk (Model/Kelas/Saiz/dll)", getPayloadValue(payloadObject, "f_kspp_supplier_product_desc"));
            addSectionTable(document,
                    "Bahagian C: Maklumat Pembekal dan Produk",
                    ksppC,
                    sectionFont,
                    labelFont,
                    bodyFont);

            addKsppQuestionSection(document, payloadObject, sectionFont, labelFont, bodyFont);

            Map<String, String> ksppE = new LinkedHashMap<>();
            ksppE.put("Keputusan Ulasan", getPayloadValue(payloadObject, "f_kspp_review_decision"));
            ksppE.put("Tarikh", getPayloadValue(payloadObject, "f_kspp_review_date"));
            ksppE.put("Ulasan", getPayloadValue(payloadObject, "f_kspp_review_note"));
            ksppE.put("Nama", getPayloadValue(payloadObject, "f_kspp_sign_name"));
            addSectionTable(document,
                    "Bahagian E: Ulasan Terhadap Pembaharuan Perakuan Pendaftaran Pembekal dan Produk Bekalan Air",
                    ksppE,
                    sectionFont,
                    labelFont,
                    bodyFont);
        }

        if (showUjppp) {
            if (showKspp) {
                // KSPP_UJPPP: add UJPPP title before its sections
                Paragraph ujpppBorangTitle = new Paragraph("BORANG UJPPP", borangFont);
                ujpppBorangTitle.setAlignment(Element.ALIGN_CENTER);
                document.add(ujpppBorangTitle);
                document.add(new Paragraph(" ", bodyFont));
            }
            document.add(new Paragraph("BORANG UJPPP", borangFont));
            document.add(new Paragraph(" ", bodyFont));

            Map<String, String> ujpppA = new LinkedHashMap<>();
            ujpppA.put("Jenis Permohonan (Baharu / Pembaharuan)", getPayloadValue(payloadObject, "f_ujppp_application_type"));
            ujpppA.put("Nama Syarikat Pembekal, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_supplier_company_info"));
            ujpppA.put("Nama Syarikat Pembuat / Pengilang, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_manufacturer_company_info"));
            ujpppA.put("Nama Syarikat Prinsipal / Pemilik Produk, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_principal_company_info"));
            addSectionTable(document,
                    "Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal",
                    ujpppA,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ujpppB = new LinkedHashMap<>();
            ujpppB.put("Kategori", getPayloadValue(payloadObject, "f_ujppp_category"));
            ujpppB.put("Nama Produk", getPayloadValue(payloadObject, "f_ujppp_product_name"));
            ujpppB.put("Jenama", getPayloadValue(payloadObject, "f_ujppp_brand"));
            ujpppB.put("Piawaian / Standard", getPayloadValue(payloadObject, "f_ujppp_standard"));
            ujpppB.put("Badan Persijilan & No. Lesen Persijilan Barangan (Sah sehingga)", getPayloadValue(payloadObject, "f_ujppp_certification_body"));
            ujpppB.put("Badan Persijilan & No. Laporan Pengujian (Tarikh dikeluarkan)", getPayloadValue(payloadObject, "f_ujppp_test_report"));
            ujpppB.put("Perihal Produk (Model / Siri / Deskripsi)", getPayloadValue(payloadObject, "f_ujppp_product_desc"));
            ujpppB.put("Tempoh Jaminan Produk (Tahun)", getPayloadValue(payloadObject, "f_ujppp_warranty_year"));
            addSectionTable(document,
                    "Bahagian B: Maklumat Produk",
                    ujpppB,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ujpppC = new LinkedHashMap<>();
            ujpppC.put("Tarikh", getPayloadValue(payloadObject, "f_ujppp_review_date"));
            ujpppC.put("Syor (diterima/ditolak/digantung/dibatal)", getPayloadValue(payloadObject, "f_ujppp_review_recommendation"));
            addSectionTable(document,
                    "Bahagian C: Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Selaku Pengguna Produk",
                    ujpppC,
                    sectionFont,
                    labelFont,
                    bodyFont);
        }

        if (!showKspp && !showUjppp) {
            List<String> payloadLines = extractPayloadLines(payload);
            if (payloadLines.isEmpty()) {
                document.add(new Paragraph("Tiada kandungan borang.", bodyFont));
            } else {
                document.add(new Paragraph("Butiran Borang", sectionFont));
                document.add(new Paragraph(" ", bodyFont));
                for (String line : payloadLines) {
                    document.add(new Paragraph(line, bodyFont));
                }
            }
        }

        document.close();
    }

    private void addKsppQuestionSection(Document document,
                                        JsonObject payloadObject,
                                        Font sectionFont,
                                        Font labelFont,
                                        Font bodyFont) throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100f);
        table.setWidths(new float[]{0.5f, 4f, 2f});
        table.setSpacingBefore(8f);

        // Section title row spanning all 3 columns
        PdfPCell titleCell = new PdfPCell(new Phrase("BAHAGIAN D : PRESTASI PEMBEKAL DAN PRODUK", sectionFont));
        titleCell.setColspan(3);
        titleCell.setPadding(6f);
        titleCell.setBackgroundColor(new java.awt.Color(220, 230, 241));
        table.addCell(titleCell);

        // Nota row
        PdfPCell notaCell = new PdfPCell(new Phrase("Nota : # Sila nyatakan (Ya / Tidak / Tidak Berkenaan)", bodyFont));
        notaCell.setColspan(3);
        notaCell.setPadding(5f);
        table.addCell(notaCell);

        // Column headers
        PdfPCell noHeader = new PdfPCell(new Phrase("NO", labelFont));
        noHeader.setPadding(5f);
        noHeader.setHorizontalAlignment(Element.ALIGN_CENTER);
        noHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(noHeader);

        PdfPCell perkaraHeader = new PdfPCell(new Phrase("PERKARA", labelFont));
        perkaraHeader.setPadding(5f);
        perkaraHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(perkaraHeader);

        PdfPCell catatanHeader = new PdfPCell(new Phrase("# CATATAN", labelFont));
        catatanHeader.setPadding(5f);
        catatanHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(catatanHeader);

        for (int i = 1; i <= KSPP_QUESTIONS.length; i++) {
            String answer = getPayloadValue(payloadObject, "f_kspp_q" + i);
            String note = getPayloadValue(payloadObject, "f_kspp_q" + i + "_note");

            PdfPCell noCell = new PdfPCell(new Phrase(String.valueOf(i), bodyFont));
            noCell.setPadding(5f);
            noCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(noCell);

            PdfPCell perkaraCell = new PdfPCell(new Phrase(KSPP_QUESTIONS[i - 1], bodyFont));
            perkaraCell.setPadding(5f);
            table.addCell(perkaraCell);

            String catatanText = (answer != null && !answer.isEmpty() ? answer : "-");
            if (note != null && !note.isEmpty()) {
                catatanText += "\n" + note;
            }
            PdfPCell catatanCell = new PdfPCell(new Phrase(catatanText, bodyFont));
            catatanCell.setPadding(5f);
            table.addCell(catatanCell);
        }

        document.add(table);
        document.add(new Paragraph(" ", bodyFont));
    }

    private void addSectionTable(Document document,
                                 String sectionTitle,
                                 Map<String, String> fields,
                                 Font sectionFont,
                                 Font labelFont,
                                 Font bodyFont) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100f);
        table.setWidths(new float[]{2f, 3f});
        table.setSpacingBefore(8f);

        // Section title as header row spanning both columns
        PdfPCell titleCell = new PdfPCell(new Phrase(sectionTitle.toUpperCase(), sectionFont));
        titleCell.setColspan(2);
        titleCell.setPadding(6f);
        titleCell.setBackgroundColor(new java.awt.Color(220, 230, 241));
        table.addCell(titleCell);

        for (Map.Entry<String, String> entry : fields.entrySet()) {
            PdfPCell labelCell = new PdfPCell(new Phrase(entry.getKey(), labelFont));
            labelCell.setPadding(6f);
            table.addCell(labelCell);

            PdfPCell valueCell = new PdfPCell(new Phrase(safePdfValue(entry.getValue()), bodyFont));
            valueCell.setPadding(6f);
            table.addCell(valueCell);
        }

        document.add(table);
        document.add(new Paragraph(" ", bodyFont));
    }

    private JsonObject parsePayloadObject(String payload) {
        if (payload == null || payload.isBlank()) {
            return new JsonObject();
        }

        try {
            JsonElement root = JsonParser.parseString(payload);
            if (root != null && root.isJsonObject()) {
                return root.getAsJsonObject();
            }
        } catch (Exception ignored) {
            // Fall back to empty object; fallback block will still print raw payload when needed.
        }

        return new JsonObject();
    }

    private String getPayloadValue(JsonObject payloadObject, String key) {
        if (payloadObject == null || key == null || key.isBlank() || !payloadObject.has(key)) {
            return "-";
        }

        JsonElement element = payloadObject.get(key);
        if (element == null || element.isJsonNull()) {
            return "-";
        }

        if (element.isJsonPrimitive()) {
            String value = element.getAsString();
            return value == null || value.trim().isEmpty() ? "-" : value.trim();
        }

        String value = element.toString();
        return value == null || value.trim().isEmpty() ? "-" : value.trim();
    }

    private List<String> extractPayloadLines(String payload) {
        List<String> lines = new ArrayList<>();
        if (payload == null || payload.isBlank()) {
            return lines;
        }

        try {
            JsonElement root = JsonParser.parseString(payload);
            flattenJsonPayload(root, "", lines);
        } catch (Exception ex) {
            lines.add(payload);
        }
        return lines;
    }

    private void flattenJsonPayload(JsonElement element, String path, List<String> lines) {
        if (element == null || element.isJsonNull()) {
            return;
        }

        if (element.isJsonPrimitive()) {
            String label = path == null || path.isBlank() ? "Nilai" : prettifyPath(path);
            lines.add(label + ": " + element.getAsString());
            return;
        }

        if (element.isJsonArray()) {
            JsonArray array = element.getAsJsonArray();
            if (array.isEmpty()) {
                if (path != null && !path.isBlank()) {
                    lines.add(prettifyPath(path) + ": -");
                }
                return;
            }
            for (int i = 0; i < array.size(); i++) {
                String nextPath = (path == null || path.isBlank()) ? "Item " + (i + 1) : path + " > Item " + (i + 1);
                flattenJsonPayload(array.get(i), nextPath, lines);
            }
            return;
        }

        JsonObject object = element.getAsJsonObject();
        for (Map.Entry<String, JsonElement> entry : object.entrySet()) {
            String nextPath = (path == null || path.isBlank()) ? entry.getKey() : path + " > " + entry.getKey();
            flattenJsonPayload(entry.getValue(), nextPath, lines);
        }
    }

    private String prettifyPath(String path) {
        if (path == null || path.isBlank()) {
            return "";
        }
        String normalized = path.replace('_', ' ');
        String[] parts = normalized.split(" > ");
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < parts.length; i++) {
            String part = parts[i].trim();
            if (part.isEmpty()) {
                continue;
            }
            if (builder.length() > 0) {
                builder.append(" > ");
            }
            builder.append(Character.toUpperCase(part.charAt(0)));
            if (part.length() > 1) {
                builder.append(part.substring(1));
            }
        }
        return builder.toString();
    }

    private String safePdfValue(Object value) {
        if (value == null) {
            return "-";
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? "-" : text;
    }

    private String storeAnnouncementImage(HttpServletRequest request, String existingImageUrl) throws IOException, ServletException {
        Part imagePart = request.getPart("announcement_image");
        if (imagePart == null || imagePart.getSize() <= 0) {
            return normalizeAnnouncementImageUrl(existingImageUrl);
        }

        if (imagePart.getSize() > ANNOUNCEMENT_MAX_IMAGE_SIZE_BYTES) {
            throw new ServletException("Saiz gambar terlalu besar. Maksimum 10MB.");
        }

        String submitted = imagePart.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return existingImageUrl;
        }

        String original = Paths.get(submitted).getFileName().toString();
        String extension = "";
        int dot = original.lastIndexOf('.');
        if (dot > -1 && dot < original.length() - 1) {
            extension = original.substring(dot).toLowerCase();
        }

        if (!(".png".equals(extension) || ".jpg".equals(extension) || ".jpeg".equals(extension) || ".webp".equals(extension))) {
            throw new ServletException("Format gambar tidak disokong. Guna PNG, JPG, JPEG, atau WEBP.");
        }

        Path uploadDir = resolveAnnouncementUploadDir();
        Files.createDirectories(uploadDir);

        String fileName = "ann-" + UUID.randomUUID() + extension;
        Path destination = uploadDir.resolve(fileName);
        try (InputStream input = imagePart.getInputStream()) {
            Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
        }

        return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
    }

    private String resolveUploadErrorMessage(Exception exception) {
        String message = exception.getMessage();
        if (message != null) {
            String lower = message.toLowerCase();
            if (lower.contains("size") || lower.contains("large") || lower.contains("exceed") || lower.contains("lebih besar")) {
                return "Saiz gambar terlalu besar. Had maksimum ialah 10MB.";
            }
            if (lower.contains("format gambar tidak disokong")) {
                return message;
            }
        }
        return "Gagal muat naik gambar. Gunakan format PNG/JPG/JPEG/WEBP dan pastikan saiz tidak melebihi 10MB.";
    }

    private Path resolveAnnouncementUploadDir() throws ServletException {
        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null && !catalinaBase.isBlank()) {
            return Paths.get(catalinaBase, "uploads", "sistemppa", "announcements");
        }

        String userDir = System.getProperty("user.dir");
        if (userDir != null && !userDir.isBlank()) {
            return Paths.get(userDir, "runtime", "uploads", "sistemppa", "announcements");
        }

        throw new ServletException("Path upload gambar tidak tersedia.");
    }

    private String normalizeAnnouncementImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return imageUrl;
        }

        String normalized = imageUrl.trim().replace('\\', '/');
        if (normalized.startsWith("http://") || normalized.startsWith("https://") || normalized.startsWith("data:")) {
            return normalized;
        }

        if (normalized.contains(ANNOUNCEMENT_IMAGE_ENDPOINT)) {
            int index = normalized.indexOf(ANNOUNCEMENT_IMAGE_ENDPOINT);
            return normalized.substring(index);
        }

        int uploadManagedIndex = normalized.toLowerCase(java.util.Locale.ROOT).indexOf("/uploads/sistemppa/announcements/");
        if (uploadManagedIndex >= 0) {
            String fileName = normalized.substring(uploadManagedIndex + "/uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int uploadRelativeIndex = normalized.toLowerCase(java.util.Locale.ROOT).indexOf("uploads/sistemppa/announcements/");
        if (uploadRelativeIndex >= 0) {
            String fileName = normalized.substring(uploadRelativeIndex + "uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int legacyIndex = normalized.indexOf("/assets/images/announcements/");
        if (legacyIndex >= 0) {
            String fileName = normalized.substring(legacyIndex + "/assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int relativeLegacyIndex = normalized.indexOf("assets/images/announcements/");
        if (relativeLegacyIndex >= 0) {
            String fileName = normalized.substring(relativeLegacyIndex + "assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        if (normalized.startsWith("/")) {
            return normalized;
        }

        return "/" + normalized;
    }
}

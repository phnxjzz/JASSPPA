package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;

@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class DashboardServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());
    private static final String ANNOUNCEMENT_IMAGE_ENDPOINT = "/announcement-images/";
    private static final int ADMIN_APPLICATION_LIMIT = 50;
    private static final int DASHBOARD_PRODUCT_LIMIT = 8;
    private static final int DASHBOARD_ANNOUNCEMENT_LIMIT = 20;
    private static final int HOMEPAGE_ANNOUNCEMENT_LIMIT = 5;
    private static final long ANNOUNCEMENT_MAX_IMAGE_SIZE_BYTES = 10L * 1024L * 1024L;

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

        String action = trim(request.getParameter("announcement_action"));
        Integer userId = (Integer) session.getAttribute("user_id");

        if (action == null || action.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String title = trim(request.getParameter("announcement_title"));
        String content = trim(request.getParameter("announcement_content"));
        String existingImageUrl = trim(request.getParameter("announcement_existing_image_url"));
        boolean isActive = "on".equalsIgnoreCase(request.getParameter("announcement_active"));

        try (Connection conn = DatabaseConfig.getConnection()) {
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
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_saved=1");
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
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_saved=1");
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
                response.sendRedirect(request.getContextPath() + "/dashboard?announcement_deleted=1");
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
        String status = trim(request.getParameter("status"));

        Map<String, Integer> stats = DashboardDataService.loadAdminStats(conn);
        for (Map.Entry<String, Integer> entry : stats.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        request.setAttribute("search_query", search == null ? "" : search);
        request.setAttribute("selected_status", status == null ? "" : status);
        request.setAttribute("pending_applications",
                DashboardDataService.loadApplications(conn, search, status, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("filtered_application_count",
                DashboardDataService.countApplications(conn, search, status));
        request.setAttribute("registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, false, 0));
        request.setAttribute("new_registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, true, 0));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));

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

        request.setAttribute("application_count", DashboardDataService.countUserApplications(conn, userId));
        request.setAttribute("applications", DashboardDataService.loadUserApplications(conn, userId));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("product_count", DashboardDataService.countProducts(conn, null, null));
        request.setAttribute("account_status", user.get("status"));
        request.setAttribute("announcements",
            DashboardDataService.loadActiveAnnouncements(conn, HOMEPAGE_ANNOUNCEMENT_LIMIT));
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
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

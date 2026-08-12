package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas ApplicationServlet.
 * Dipanggil melalui URL:  /applications/* (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.service.TemplateService;
import com.sistemppa.util.EmailUtil;
import com.sistemppa.util.PublicUrlResolver;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletContext;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.time.Instant;
import java.net.URLDecoder;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Base64;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.logging.Logger;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 120 * 1024 * 1024)
public class ApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ApplicationServlet.class.getName());
    private static final Pattern EDIT_PATH_PATTERN = Pattern.compile("^/(\\d+)/edit$");
    private static final String RENEW_FROM_PARAM = "renewFrom";
    private static final long DOCUMENT_MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024L;
    private static final String APPLICATION_TYPE_KEMASKINI = "KEMASKINI";
    private static final String APPLICATION_TYPE_BAHARU = "BAHARU";
    private static final String APPLICATION_TYPE_PEMBAHARUAN = "PEMBAHARUAN";
    private static final long DIRECTOR_LINK_VALIDITY_SECONDS = 30L * 24L * 60L * 60L;
    private static final String SESSION_SUBMISSION_TOKEN_MAP = "submission_token_map";
    private static final int MAX_SUBMISSION_TOKENS = 20;
        private static final String ACTIVE_APPLICATION_STATUS_SQL = "'DRAFT', 'NEW', 'DIRECTOR_REVIEW', 'UNDER_REVIEW', 'IN_PROGRESS', "
            + "'MENUNGGU_TINDAKAN_PENGARAH', 'MENUNGGU_SETERUSNYA_DILULUSKAN', 'MENUNGGU_SETERUSNYA_GAGAL', "
            + "'MENUNGGU_SETERUSNYA_GANTUNG', 'MENUNGGU_SETERUSNYA_BATAL', 'DILULUSKAN_PENGARAH', 'KUERI'";
    private static final java.util.concurrent.ConcurrentHashMap<String, Object> APPLICATION_SUBMISSION_LOCKS = new java.util.concurrent.ConcurrentHashMap<>();

    private String directorLinkSecret;

    @Override
    public void init() throws ServletException {
        String envSecret = System.getenv("DIRECTOR_LINK_SECRET");
        if (envSecret != null && !envSecret.isBlank()) {
            directorLinkSecret = envSecret.trim();
            return;
        }
        String contextSecret = getServletContext().getInitParameter("director.link.secret");
        if (contextSecret != null && !contextSecret.isBlank()) {
            directorLinkSecret = contextSecret.trim();
            return;
        }
        directorLinkSecret = "SPPA_DIRECTOR_LINK_SECRET_CHANGE_ME";
        LOGGER.warning("DIRECTOR_LINK_SECRET not configured. Using fallback secret; set DIRECTOR_LINK_SECRET env var in production.");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Pintu masuk GET untuk modul permohonan.
        // Dipanggil dari route /applications/* dan akan decide sama ada:
        // 1) buka borang baru, 2) buka borang edit, atau 3) papar detail permohonan.
        HttpSession session = requireUserSession(request, response);
        if (session == null) {
            return;
        }

        String pathInfo = request.getPathInfo(); // e.g. "/new" or "/6"
        if (pathInfo == null || "/new".equals(pathInfo)) {
            Integer renewalSourceId = parseInteger(request.getParameter(RENEW_FROM_PARAM));
            if (renewalSourceId != null) {
                showRenewalApplicationForm(request, response, session, renewalSourceId);
                return;
            }
            Integer userId = (Integer) session.getAttribute("user_id");
            try (Connection conn = DatabaseConfig.getConnection()) {
                request.setAttribute("approvedApplications", fetchApprovedApplicationsForUser(conn, userId));
            } catch (SQLException e) {
                LOGGER.warning("Failed to load approved applications for renewal dropdown: " + e.getMessage());
                request.setAttribute("approvedApplications", Collections.emptyList());
            }
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.setAttribute("submission_token", createFormSubmissionToken(request));
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        } else if (isEditPath(pathInfo)) {
            Integer applicationId = extractEditApplicationId(pathInfo);
            if (applicationId == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            showEditApplicationForm(request, response, session, applicationId);
        } else {
            try {
                int applicationId = Integer.parseInt(pathInfo.substring(1));
                showUserApplication(request, response, session, applicationId);
            } catch (NumberFormatException e) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        }
    }

    private void showUserApplication(HttpServletRequest request, HttpServletResponse response,
            HttpSession session, int applicationId) throws ServletException, IOException {
        Integer userId = (Integer) session.getAttribute("user_id");
        try (Connection conn = DatabaseConfig.getConnection()) {
            String sql = "SELECT a.*, ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                    + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                    + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                    + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                    + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                    + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
                    + "ad.declaration_name, ad.declaration_position "
                    + "FROM applications a LEFT JOIN application_details ad ON ad.application_id = a.id "
                    + "WHERE a.id = ? AND a.user_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, applicationId);
                stmt.setInt(2, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    Map<String, Object> app = new HashMap<>();
                    app.put("id", rs.getInt("id"));
                    app.put("product_name", rs.getString("product_name"));
                    app.put("product_category", rs.getString("product_category"));
                    app.put("product_description", rs.getString("product_description"));
                    app.put("company_name", rs.getString("company_name"));
                    app.put("company_address", rs.getString("company_address"));
                    app.put("contact_number", rs.getString("contact_number"));
                    app.put("email", rs.getString("email"));
                    app.put("status", rs.getString("status"));
                    app.put("admin_notes", rs.getString("admin_notes"));
                    app.put("submitted_at", rs.getTimestamp("submitted_at"));
                    app.put("certificate_number", rs.getString("certificate_number"));
                    app.put("issued_at", rs.getDate("issued_at"));
                    app.put("valid_until", rs.getDate("valid_until"));
                    app.put("application_type", rs.getString("application_type"));
                    app.put("supplier_name", rs.getString("supplier_name"));
                    app.put("supplier_address", rs.getString("supplier_address"));
                    app.put("supplier_phone", rs.getString("supplier_phone"));
                    app.put("manufacturer_name", rs.getString("manufacturer_name"));
                    app.put("manufacturer_address", rs.getString("manufacturer_address"));
                    app.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    app.put("principal_name", rs.getString("principal_name"));
                    app.put("principal_address", rs.getString("principal_address"));
                    app.put("principal_phone", rs.getString("principal_phone"));
                    app.put("standard_name", rs.getString("standard_name"));
                    app.put("certification_license", rs.getString("certification_license"));
                    app.put("certification_valid_until", rs.getDate("certification_valid_until"));
                    app.put("test_report_reference", rs.getString("test_report_reference"));
                    app.put("test_report_date", rs.getDate("test_report_date"));
                    app.put("warranty_years", rs.getBigDecimal("warranty_years"));
                    app.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    app.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    app.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    app.put("declaration_name", rs.getString("declaration_name"));
                    app.put("declaration_position", rs.getString("declaration_position"));
                    request.setAttribute("application", app);
                }
            }

            List<Map<String, Object>> documents = new ArrayList<>();
            String docSql = "SELECT id, document_type, original_filename, content_type, file_size FROM application_documents WHERE application_id = ? ORDER BY id ASC";
            try (PreparedStatement stmt = conn.prepareStatement(docSql)) {
                stmt.setInt(1, applicationId);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> doc = new HashMap<>();
                        doc.put("id", rs.getInt("id"));
                        doc.put("document_type", rs.getString("document_type"));
                        doc.put("original_filename", rs.getString("original_filename"));
                        doc.put("content_type", rs.getString("content_type"));
                        doc.put("file_size", rs.getLong("file_size"));
                        documents.add(doc);
                    }
                }
            }
            request.setAttribute("documents", documents);
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/view-application.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load application #" + applicationId + ": " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Pintu masuk POST untuk simpan/hantar permohonan.
        // Flow utama:
        // - jika path edit => update permohonan sedia ada
        // - selain itu => cipta permohonan baru + trigger notifikasi pengarah jika perlu
        HttpSession session = requireUserSession(request, response);
        if (session == null) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        Integer userId = (Integer) session.getAttribute("user_id");
        String pathInfo = request.getPathInfo();

        if (isEditPath(pathInfo)) {
            Integer applicationId = extractEditApplicationId(pathInfo);
            if (applicationId == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            processApplicationUpdate(request, response, session, userId, applicationId);
            return;
        }

        String applicationType = getParamUpper(request, "application_type");
        String supplierName = getParamUpper(request, "supplier_name");
        String productName = getPrimaryParamUpper(request, "product_name");
        String productCategory = getPrimaryParamUpper(request, "product_category");
        Integer renewalSourceId = parseInteger(request.getParameter("renew_from_application_id"));

        if (!isSupportedApplicationType(applicationType)) {
            prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
            request.setAttribute("error", "Jenis permohonan tidak sah.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        if (APPLICATION_TYPE_PEMBAHARUAN.equalsIgnoreCase(applicationType) && renewalSourceId == null) {
            prepareCreateFormStateFromRequest(request, null, userId, null);
            request.setAttribute("error", "Sila pilih produk diluluskan untuk pembaharuan.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        if (supplierName.isEmpty() || productName.isEmpty() || productCategory.isEmpty() || applicationType.isEmpty()) {
            prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
            request.setAttribute("error", "Sila lengkapkan bahagian wajib borang PPP1.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        try (Connection validationConn = DatabaseConfig.getConnection()) {
            Integer validationApplicationId = null;
            if (renewalSourceId != null && APPLICATION_TYPE_PEMBAHARUAN.equalsIgnoreCase(applicationType)) {
                Map<String, Object> renewalSource = loadRenewalSourceApplication(validationConn, renewalSourceId, userId);
                if (renewalSource == null || renewalSource.isEmpty()) {
                    prepareCreateFormStateFromRequest(request, null, userId, validationConn);
                    request.setAttribute("error", "Permohonan asal untuk pembaharuan tidak sah atau tidak ditemui.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                    return;
                }
                validationApplicationId = renewalSourceId;
            }
            List<String> missingMandatoryDocs = findMissingMandatoryDocuments(request, applicationType, validationConn, validationApplicationId);
            if (!missingMandatoryDocs.isEmpty()) {
                prepareCreateFormStateFromRequest(request, renewalSourceId, userId, validationConn);
                request.setAttribute("error", "Tidak Berjaya Sila Lengkapkan Dokumen yang diperlukan!");
                request.setAttribute("missingMandatoryDocuments", missingMandatoryDocs);
                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                return;
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to validate mandatory documents: " + e.getMessage());
            prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
            request.setAttribute("error", "Ralat semasa menyemak dokumen. Sila cuba lagi.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        String submissionToken = trim(request.getParameter("submission_token"));
        HttpSession existingSession = request.getSession(false);
        if (submissionToken != null && !submissionToken.isBlank() && existingSession != null) {
            Integer submittedId = getExistingSubmissionApplicationId(existingSession, submissionToken);
            if (submittedId != null) {
                if (submittedId > 0) {
                    response.sendRedirect(request.getContextPath() + "/applications/new?success=1&id=" + submittedId);
                } else {
                    response.sendRedirect(request.getContextPath() + "/applications/new?duplicate=1");
                }
                return;
            }
            markSubmissionStarted(existingSession, submissionToken);
        }

        String submissionLockKey = buildSubmissionLockKey(userId, request, renewalSourceId);
        Object submissionLock = acquireSubmissionLock(submissionLockKey);
        try {
            synchronized (submissionLock) {
                try (Connection limitConn = DatabaseConfig.getConnection();
                     PreparedStatement limitPs = limitConn.prepareStatement(
                         "SELECT COUNT(*) FROM applications WHERE user_id = ? AND status IN (" + ACTIVE_APPLICATION_STATUS_SQL + ")")) {
                    limitPs.setInt(1, userId);
                    try (ResultSet limitRs = limitPs.executeQuery()) {
                        if (limitRs.next() && limitRs.getInt(1) >= 3) {
                            prepareCreateFormStateFromRequest(request, renewalSourceId, userId, limitConn);
                            request.setAttribute("error", "Anda telah mencapai had maksimum 3 permohonan aktif. Sila tunggu sehingga permohonan sedia ada diselesaikan sebelum membuat permohonan baharu.");
                            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                            return;
                        }
                    }
                } catch (SQLException e) {
                    LOGGER.severe("Failed to check application limit: " + e.getMessage());
                    prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
                    request.setAttribute("error", "Ralat semasa memeriksa had permohonan. Sila cuba lagi.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                    return;
                }

                try (Connection conn = DatabaseConfig.getConnection()) {
                    ensureOnlineApplicationSchema(conn);
                    conn.setAutoCommit(false);
                    boolean committed = false;
                    try {
                        if (renewalSourceId != null && APPLICATION_TYPE_PEMBAHARUAN.equalsIgnoreCase(applicationType)) {
                            Map<String, Object> renewalSource = loadRenewalSourceApplication(conn, renewalSourceId, userId);
                            if (renewalSource == null || renewalSource.isEmpty()) {
                                prepareCreateFormStateFromRequest(request, null, userId, conn);
                                request.setAttribute("error", "Permohonan asal untuk pembaharuan tidak sah atau tidak ditemui.");
                                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                                return;
                            }
                        }
                        List<String> oversizedDocuments = findOversizedDocuments(request);
                        if (!oversizedDocuments.isEmpty()) {
                            prepareCreateFormStateFromRequest(request, renewalSourceId, userId, conn);
                            request.setAttribute("error", "Saiz dokumen terlalu besar. Had maksimum ialah 10MB setiap dokumen.");
                            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                            return;
                        }
                        Integer duplicateApplicationId = findDuplicateActiveApplicationId(conn, userId, request);
                        if (duplicateApplicationId != null) {
                            conn.rollback();
                            if (submissionToken != null && !submissionToken.isBlank() && existingSession != null) {
                                markSubmissionCompleted(existingSession, submissionToken, duplicateApplicationId);
                            }
                            response.sendRedirect(request.getContextPath() + "/applications/new?duplicate=1&id=" + duplicateApplicationId);
                            return;
                        }

                        int applicationId = insertApplication(conn, userId, request);
                        insertApplicationDetails(conn, applicationId, request);
                        boolean isKemaskini = APPLICATION_TYPE_KEMASKINI.equalsIgnoreCase(applicationType);
                        String initialStatus = isKemaskini ? "NEW" : "MENUNGGU_TINDAKAN_PENGARAH";
                        DashboardDataService.recordStatusHistory(conn, applicationId, null, initialStatus, userId, null);
                        if (renewalSourceId != null && APPLICATION_TYPE_PEMBAHARUAN.equalsIgnoreCase(applicationType)) {
                            cloneSourceDocuments(conn, renewalSourceId, applicationId);
                        }
                        saveUploadedDocuments(conn, applicationId, request, false);
                        insertAuditLog(conn, userId, request.getRemoteAddr(), applicationId);
                        conn.commit();
                        committed = true;
                        if (!isKemaskini) {
                            sendDirectorReviewNotification(request, conn, applicationId);
                        }
                        if (submissionToken != null && !submissionToken.isBlank() && existingSession != null) {
                            markSubmissionCompleted(existingSession, submissionToken, applicationId);
                        }
                        response.sendRedirect(request.getContextPath() + "/applications/new?success=1&id=" + applicationId);
                    } finally {
                        if (!committed) {
                            if (submissionToken != null && !submissionToken.isBlank() && existingSession != null) {
                                removeSubmissionToken(existingSession, submissionToken);
                            }
                            try { conn.rollback(); } catch (SQLException rb) {
                                LOGGER.severe("Rollback failed: " + rb.getMessage());
                            }
                        }
                    }
                } catch (SQLException e) {
                    LOGGER.severe("Failed to save application: " + e.getMessage());
                    prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
                    request.setAttribute("error", "Permohonan tidak berjaya disimpan. Sila cuba lagi.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                } catch (IllegalStateException e) {
                    LOGGER.warning("File upload exceeded allowed size: " + e.getMessage());
                    prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
                    request.setAttribute("error", "Saiz dokumen terlalu besar. Had maksimum ialah 10MB setiap dokumen.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                } catch (IOException | ServletException e) {
                    LOGGER.severe("IO/Servlet error saving application: " + e.getMessage());
                    prepareCreateFormStateFromRequest(request, renewalSourceId, userId, null);
                    request.setAttribute("error", "Ralat sistem semasa menghantar permohonan. Sila cuba lagi.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                }
            }
        } finally {
            releaseSubmissionLock(submissionLockKey, submissionLock);
        }
    }

    private HttpSession requireUserSession(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }
        return session;
    }

    private String createFormSubmissionToken(HttpServletRequest request) {
        String token = UUID.randomUUID().toString();
        request.setAttribute("submission_token", token);
        return token;
    }

    private synchronized Map<String, Integer> getSubmissionTokenMap(HttpSession session) {
        @SuppressWarnings("unchecked")
        Map<String, Integer> tokenMap = (Map<String, Integer>) session.getAttribute(SESSION_SUBMISSION_TOKEN_MAP);
        if (tokenMap == null) {
            tokenMap = new java.util.LinkedHashMap<String, Integer>() {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, Integer> eldest) {
                    return size() > MAX_SUBMISSION_TOKENS;
                }
            };
            session.setAttribute(SESSION_SUBMISSION_TOKEN_MAP, tokenMap);
        }
        return tokenMap;
    }

    private Integer getExistingSubmissionApplicationId(HttpSession session, String token) {
        if (session == null || token == null || token.isBlank()) {
            return null;
        }
        Map<String, Integer> tokenMap = getSubmissionTokenMap(session);
        synchronized (tokenMap) {
            return tokenMap.get(token);
        }
    }

    private void markSubmissionStarted(HttpSession session, String token) {
        if (session == null || token == null || token.isBlank()) {
            return;
        }
        Map<String, Integer> tokenMap = getSubmissionTokenMap(session);
        synchronized (tokenMap) {
            tokenMap.put(token, -1);
        }
    }

    private void markSubmissionCompleted(HttpSession session, String token, int applicationId) {
        if (session == null || token == null || token.isBlank()) {
            return;
        }
        Map<String, Integer> tokenMap = getSubmissionTokenMap(session);
        synchronized (tokenMap) {
            tokenMap.put(token, applicationId);
        }
    }

    private void removeSubmissionToken(HttpSession session, String token) {
        if (session == null || token == null || token.isBlank()) {
            return;
        }
        Map<String, Integer> tokenMap = getSubmissionTokenMap(session);
        synchronized (tokenMap) {
            tokenMap.remove(token);
        }
    }

    private String buildSubmissionLockKey(Integer userId, HttpServletRequest request, Integer renewalSourceId) {
        return String.valueOf(userId) + "|"
                + getParamUpper(request, "application_type") + "|"
                + getParamUpper(request, "supplier_name") + "|"
                + getPrimaryParamUpper(request, "product_name") + "|"
                + getPrimaryParamUpper(request, "product_category") + "|"
                + String.valueOf(renewalSourceId == null ? 0 : renewalSourceId);
    }

    private Object acquireSubmissionLock(String key) {
        return APPLICATION_SUBMISSION_LOCKS.computeIfAbsent(key, ignored -> new Object());
    }

    private void releaseSubmissionLock(String key, Object lock) {
        if (key == null || lock == null) {
            return;
        }
        APPLICATION_SUBMISSION_LOCKS.remove(key, lock);
    }

    private int insertApplication(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        // KEMASKINI goes straight to admin (status NEW).
        // BAHARU and PEMBAHARUAN go to director first (MENUNGGU_TINDAKAN_PENGARAH).
        String applicationType = getParamUpper(request, "application_type");
        boolean isKemaskini = APPLICATION_TYPE_KEMASKINI.equalsIgnoreCase(applicationType);
        String initialStatus = isKemaskini ? "NEW" : "MENUNGGU_TINDAKAN_PENGARAH";
        String directorReviewType = isKemaskini ? null : "INITIAL";

        String sql = "INSERT INTO applications (user_id, product_name, product_category, product_description, company_name, company_address, contact_number, email, status, director_review_type, submitted_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, userId);
            stmt.setString(2, getPrimaryParamUpper(request, "product_name"));
            stmt.setString(3, getPrimaryParamUpper(request, "product_category"));
            stmt.setString(4, buildApplicationSummary(request));
            stmt.setString(5, getParamUpper(request, "supplier_name"));
            stmt.setString(6, getParamUpper(request, "supplier_address"));
            stmt.setString(7, getParamUpper(request, "supplier_phone"));
            stmt.setString(8, trim(request.getParameter("supplier_email")));
            stmt.setString(9, initialStatus);
            if (directorReviewType == null) {
                stmt.setNull(10, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(10, directorReviewType);
            }
            stmt.setTimestamp(11, Timestamp.valueOf(LocalDateTime.now()));
            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }

        throw new SQLException("Application ID not generated.");
    }

    private Integer findDuplicateActiveApplicationId(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        String sql = "SELECT a.id FROM applications a "
                + "JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.user_id = ? "
                + "AND a.status IN (" + ACTIVE_APPLICATION_STATUS_SQL + ") "
                + "AND UPPER(TRIM(a.product_name)) = UPPER(TRIM(?)) "
                + "AND UPPER(TRIM(a.product_category)) = UPPER(TRIM(?)) "
                + "AND UPPER(TRIM(a.company_name)) = UPPER(TRIM(?)) "
                + "AND UPPER(TRIM(ad.application_type)) = UPPER(TRIM(?)) "
                + "ORDER BY a.id DESC LIMIT 1";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, getPrimaryParamUpper(request, "product_name"));
            stmt.setString(3, getPrimaryParamUpper(request, "product_category"));
            stmt.setString(4, getParamUpper(request, "supplier_name"));
            stmt.setString(5, getParamUpper(request, "application_type"));
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("id");
                }
            }
        }

        return null;
    }

    private void insertApplicationDetails(Connection conn, int applicationId, HttpServletRequest request) throws SQLException {
        String sql = "INSERT INTO application_details (application_id, application_type, supplier_name, supplier_address, supplier_phone, manufacturer_name, manufacturer_address, manufacturer_phone, principal_name, principal_address, principal_phone, standard_name, certification_license, certification_valid_until, test_report_reference, test_report_date, warranty_years, sabah_rep_name, sabah_rep_address, sabah_rep_phone, declaration_name, declaration_position) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.setString(2, getParamUpper(request, "application_type"));
            stmt.setString(3, getParamUpper(request, "supplier_name"));
            stmt.setString(4, getParamUpper(request, "supplier_address"));
            stmt.setString(5, getParamUpper(request, "supplier_phone"));
            stmt.setString(6, getParamUpper(request, "manufacturer_name"));
            stmt.setString(7, getParamUpper(request, "manufacturer_address"));
            stmt.setString(8, getParamUpper(request, "manufacturer_phone"));
            stmt.setString(9, getParamUpper(request, "principal_name"));
            stmt.setString(10, getParamUpper(request, "principal_address"));
            stmt.setString(11, getParamUpper(request, "principal_phone"));
            stmt.setString(12, getPrimaryParamUpper(request, "standard_name"));
            stmt.setString(13, getPrimaryParamUpper(request, "certification_license"));
            stmt.setDate(14, parseDate(getPrimaryParam(request, "certification_valid_until")));
            stmt.setString(15, getPrimaryParamUpper(request, "test_report_reference"));
            stmt.setDate(16, parseDate(getPrimaryParam(request, "test_report_date")));
            stmt.setBigDecimal(17, parseDecimal(getPrimaryParam(request, "warranty_years")));
            stmt.setString(18, getParamUpper(request, "sabah_rep_name"));
            stmt.setString(19, getParamUpper(request, "sabah_rep_address"));
            stmt.setString(20, getParamUpper(request, "sabah_rep_phone"));
            stmt.setString(21, getParamUpper(request, "declaration_name"));
            stmt.setString(22, getParamUpper(request, "declaration_position"));
            stmt.executeUpdate();
        }
    }

    private void updateApplicationDetails(Connection conn, int applicationId, HttpServletRequest request) throws SQLException {
        String sql = "UPDATE application_details SET application_type = ?, supplier_name = ?, supplier_address = ?, supplier_phone = ?, "
                + "manufacturer_name = ?, manufacturer_address = ?, manufacturer_phone = ?, "
                + "principal_name = ?, principal_address = ?, principal_phone = ?, "
                + "standard_name = ?, certification_license = ?, certification_valid_until = ?, "
                + "test_report_reference = ?, test_report_date = ?, warranty_years = ?, "
                + "sabah_rep_name = ?, sabah_rep_address = ?, sabah_rep_phone = ?, "
                + "declaration_name = ?, declaration_position = ? "
                + "WHERE application_id = ?";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, getParamUpper(request, "application_type"));
            stmt.setString(2, getParamUpper(request, "supplier_name"));
            stmt.setString(3, getParamUpper(request, "supplier_address"));
            stmt.setString(4, getParamUpper(request, "supplier_phone"));
            stmt.setString(5, getParamUpper(request, "manufacturer_name"));
            stmt.setString(6, getParamUpper(request, "manufacturer_address"));
            stmt.setString(7, getParamUpper(request, "manufacturer_phone"));
            stmt.setString(8, getParamUpper(request, "principal_name"));
            stmt.setString(9, getParamUpper(request, "principal_address"));
            stmt.setString(10, getParamUpper(request, "principal_phone"));
            stmt.setString(11, getPrimaryParamUpper(request, "standard_name"));
            stmt.setString(12, getPrimaryParamUpper(request, "certification_license"));
            stmt.setDate(13, parseDate(getPrimaryParam(request, "certification_valid_until")));
            stmt.setString(14, getPrimaryParamUpper(request, "test_report_reference"));
            stmt.setDate(15, parseDate(getPrimaryParam(request, "test_report_date")));
            stmt.setBigDecimal(16, parseDecimal(getPrimaryParam(request, "warranty_years")));
            stmt.setString(17, getParamUpper(request, "sabah_rep_name"));
            stmt.setString(18, getParamUpper(request, "sabah_rep_address"));
            stmt.setString(19, getParamUpper(request, "sabah_rep_phone"));
            stmt.setString(20, getParamUpper(request, "declaration_name"));
            stmt.setString(21, getParamUpper(request, "declaration_position"));
            stmt.setInt(22, applicationId);
            int affected = stmt.executeUpdate();
            if (affected == 0) {
                insertApplicationDetails(conn, applicationId, request);
            }
        }
    }

    private void updateApplicationRecord(Connection conn, int applicationId, int userId, HttpServletRequest request) throws SQLException {
        String sql = "UPDATE applications SET product_name = ?, product_category = ?, product_description = ?, company_name = ?, "
                + "company_address = ?, contact_number = ?, email = ?, status = 'NEW', submitted_at = CURRENT_TIMESTAMP, "
                + "admin_notes = NULL, reviewed_at = NULL, reviewed_by = NULL, certificate_number = NULL, issued_at = NULL, valid_until = NULL "
                + "WHERE id = ? AND user_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, getPrimaryParamUpper(request, "product_name"));
            stmt.setString(2, getPrimaryParamUpper(request, "product_category"));
            stmt.setString(3, buildApplicationSummary(request));
            stmt.setString(4, getParamUpper(request, "supplier_name"));
            stmt.setString(5, getParamUpper(request, "supplier_address"));
            stmt.setString(6, getParamUpper(request, "supplier_phone"));
            stmt.setString(7, trim(request.getParameter("supplier_email")));
            stmt.setInt(8, applicationId);
            stmt.setInt(9, userId);
            stmt.executeUpdate();
        }
    }

    private void saveUploadedDocuments(Connection conn, int applicationId, HttpServletRequest request, boolean replaceExisting)
            throws SQLException, IOException, ServletException {
        Path baseDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")), "uploads", "sistemppa", String.valueOf(applicationId));
        Files.createDirectories(baseDir);

        String sql = "INSERT INTO application_documents (application_id, document_type, original_filename, stored_filename, stored_path, content_type, file_size) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (Map.Entry<String, String> entry : buildRequiredDocuments().entrySet()) {
                Part part = request.getPart(entry.getKey());
                if (part == null || part.getSize() == 0) {
                    continue;
                }

                if (part.getSize() > DOCUMENT_MAX_FILE_SIZE_BYTES) {
                    throw new ServletException("Saiz dokumen terlalu besar. Had maksimum ialah 10MB setiap dokumen.");
                }

                if (replaceExisting) {
                    try (PreparedStatement deleteStmt = conn.prepareStatement(
                            "DELETE FROM application_documents WHERE application_id = ? AND document_type = ?")) {
                        deleteStmt.setInt(1, applicationId);
                        deleteStmt.setString(2, entry.getKey());
                        deleteStmt.executeUpdate();
                    }
                }

                String originalName = extractSubmittedFileName(part);
                String safeName = UUID.randomUUID() + "-" + originalName.replaceAll("[^a-zA-Z0-9._-]", "_");
                Path storedFile = baseDir.resolve(safeName);
                Files.copy(part.getInputStream(), storedFile, StandardCopyOption.REPLACE_EXISTING);

                stmt.setInt(1, applicationId);
                stmt.setString(2, entry.getKey());
                stmt.setString(3, originalName);
                stmt.setString(4, safeName);
                stmt.setString(5, storedFile.toString());
                stmt.setString(6, part.getContentType());
                stmt.setLong(7, part.getSize());
                stmt.addBatch();
            }
            stmt.executeBatch();
        }
    }

    private List<String> findOversizedDocuments(HttpServletRequest request) throws ServletException, IOException {
        List<String> oversized = new ArrayList<>();
        for (Map.Entry<String, String> entry : buildRequiredDocuments().entrySet()) {
            Part part = request.getPart(entry.getKey());
            if (part != null && part.getSize() > DOCUMENT_MAX_FILE_SIZE_BYTES) {
                oversized.add(entry.getKey());
            }
        }
        return oversized;
    }

    private void cloneSourceDocuments(Connection conn, int sourceApplicationId, int targetApplicationId)
            throws SQLException, IOException {
        Path targetDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")),
                "uploads", "sistemppa", String.valueOf(targetApplicationId));
        Files.createDirectories(targetDir);

        String selectSql = "SELECT document_type, original_filename, stored_filename, stored_path, content_type, file_size "
                + "FROM application_documents WHERE application_id = ?";
        String insertSql = "INSERT INTO application_documents (application_id, document_type, original_filename, stored_filename, stored_path, content_type, file_size) VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement selectStmt = conn.prepareStatement(selectSql);
             PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
            selectStmt.setInt(1, sourceApplicationId);
            try (ResultSet rs = selectStmt.executeQuery()) {
                while (rs.next()) {
                    String docType = rs.getString("document_type");
                    if ("renewal_certificate".equals(docType)) {
                        continue;
                    }
                    Path sourcePath = Path.of(rs.getString("stored_path"));
                    if (!Files.exists(sourcePath)) {
                        continue;
                    }
                    String originalName = rs.getString("original_filename");
                    String safeName = UUID.randomUUID() + "-" + originalName.replaceAll("[^a-zA-Z0-9._-]", "_");
                    Path targetPath = targetDir.resolve(safeName);
                    Files.copy(sourcePath, targetPath, StandardCopyOption.REPLACE_EXISTING);

                    insertStmt.setInt(1, targetApplicationId);
                    insertStmt.setString(2, docType);
                    insertStmt.setString(3, originalName);
                    insertStmt.setString(4, safeName);
                    insertStmt.setString(5, targetPath.toString());
                    insertStmt.setString(6, rs.getString("content_type"));
                    insertStmt.setLong(7, rs.getLong("file_size"));
                    insertStmt.addBatch();
                }
            }
            insertStmt.executeBatch();
        }
    }

    private void processApplicationUpdate(HttpServletRequest request, HttpServletResponse response,
            HttpSession session, Integer userId, int applicationId) throws ServletException, IOException {
        String applicationType = getParamUpper(request, "application_type");
        String supplierName = getParamUpper(request, "supplier_name");
        String productName = getPrimaryParamUpper(request, "product_name");
        String productCategory = getPrimaryParamUpper(request, "product_category");

        try (Connection conn = DatabaseConfig.getConnection()) {
            String currentStatus = getUserApplicationStatus(conn, applicationId, userId);
            if (currentStatus == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            if (!isEditableByApplicant(currentStatus)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            if (!isSupportedApplicationType(applicationType)) {
                prepareEditFormStateFromRequest(request, applicationId, conn);
                request.setAttribute("error", "Jenis permohonan tidak sah.");
                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                return;
            }

            if (supplierName.isEmpty() || productName.isEmpty() || productCategory.isEmpty() || applicationType.isEmpty()) {
                prepareEditFormStateFromRequest(request, applicationId, conn);
                request.setAttribute("error", "Sila lengkapkan bahagian wajib borang PPP1.");
                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                return;
            }

            List<String> missingMandatoryDocs = findMissingMandatoryDocuments(request, applicationType, conn, applicationId);
            if (!missingMandatoryDocs.isEmpty()) {
                prepareEditFormStateFromRequest(request, applicationId, conn);
                request.setAttribute("error", "Tidak Berjaya Sila Lengkapkan Dokumen yang diperlukan!");
                request.setAttribute("missingMandatoryDocuments", missingMandatoryDocs);
                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                return;
            }

            conn.setAutoCommit(false);
            boolean committed = false;
            try {
                updateApplicationRecord(conn, applicationId, userId, request);
                updateApplicationDetails(conn, applicationId, request);
                saveUploadedDocuments(conn, applicationId, request, true);

                DashboardDataService.ensureAuditLogTable(conn);
                try (PreparedStatement stmt = conn.prepareStatement(
                        "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)")) {
                    stmt.setInt(1, userId);
                    stmt.setString(2, "UPDATE APPLICATION");
                    stmt.setString(3, "Pemohon mengemaskini permohonan. ID: " + applicationId + " (Status asal: " + currentStatus + ")");
                    stmt.setString(4, request.getRemoteAddr());
                    stmt.executeUpdate();
                }

                conn.commit();
                committed = true;
                sendDirectorReviewNotification(request, conn, applicationId);
                response.sendRedirect(request.getContextPath() + "/applications/" + applicationId + "?updated=1");
            } finally {
                if (!committed) {
                    try {
                        conn.rollback();
                    } catch (SQLException rollbackEx) {
                        LOGGER.severe("Rollback failed for update application #" + applicationId + ": " + rollbackEx.getMessage());
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to update application #" + applicationId + ": " + e.getMessage());
            request.setAttribute("application", buildApplicationFromRequest(request));
            request.setAttribute("error", "Permohonan tidak berjaya dikemaskini. Sila cuba lagi.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.setAttribute("editMode", true);
            request.setAttribute("formAction", request.getContextPath() + "/applications/" + applicationId + "/edit");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        }
    }

    private void prepareEditFormStateFromRequest(HttpServletRequest request, int applicationId, Connection conn) throws SQLException {
        request.setAttribute("application", buildApplicationFromRequest(request));
        request.setAttribute("existingDocumentKeys", fetchExistingDocumentKeys(conn, applicationId));
        request.setAttribute("requiredDocuments", buildRequiredDocuments());
        request.setAttribute("editMode", true);
        request.setAttribute("formAction", request.getContextPath() + "/applications/" + applicationId + "/edit");
    }

    private void prepareCreateFormStateFromRequest(HttpServletRequest request, Integer renewalSourceId, Integer userId, Connection conn) {
        request.setAttribute("application", buildApplicationFromRequest(request));
        request.setAttribute("requiredDocuments", buildRequiredDocuments());
        request.setAttribute("submission_token", createFormSubmissionToken(request));
        if (userId != null) {
            try {
                List<Map<String, Object>> approvedApplications;
                if (conn != null) {
                    approvedApplications = fetchApprovedApplicationsForUser(conn, userId);
                } else {
                    try (Connection localConn = DatabaseConfig.getConnection()) {
                        approvedApplications = fetchApprovedApplicationsForUser(localConn, userId);
                    }
                }
                request.setAttribute("approvedApplications", approvedApplications);
            } catch (SQLException e) {
                LOGGER.warning("Failed to prepare approved applications for create form state: " + e.getMessage());
                request.setAttribute("approvedApplications", Collections.emptyList());
            }
        }
        if (renewalSourceId != null) {
            request.setAttribute("renewalMode", true);
            request.setAttribute("renewalSourceApplicationId", renewalSourceId);
            if (conn != null) {
                try {
                    request.setAttribute("existingDocumentKeys", fetchExistingDocumentKeys(conn, renewalSourceId));
                } catch (SQLException e) {
                    LOGGER.warning("Failed to load existing renewal documents for application #" + renewalSourceId + ": " + e.getMessage());
                }
            }
        }
    }

    private Map<String, Object> buildApplicationFromRequest(HttpServletRequest request) {
        Map<String, Object> app = new HashMap<>();
        app.put("application_type", getParamUpper(request, "application_type"));
        app.put("supplier_name", getParamUpper(request, "supplier_name"));
        app.put("supplier_email", trim(request.getParameter("supplier_email")));
        app.put("supplier_phone", getParamUpper(request, "supplier_phone"));
        app.put("supplier_address", getParamUpper(request, "supplier_address"));
        app.put("manufacturer_name", getParamUpper(request, "manufacturer_name"));
        app.put("manufacturer_address", getParamUpper(request, "manufacturer_address"));
        app.put("manufacturer_phone", getParamUpper(request, "manufacturer_phone"));
        app.put("principal_name", getParamUpper(request, "principal_name"));
        app.put("principal_address", getParamUpper(request, "principal_address"));
        app.put("principal_phone", getParamUpper(request, "principal_phone"));
        app.put("product_name", getPrimaryParamUpper(request, "product_name"));
        app.put("product_category", getPrimaryParamUpper(request, "product_category"));
        app.put("brand", getPrimaryParamUpper(request, "brand"));
        app.put("standard_name", getPrimaryParamUpper(request, "standard_name"));
        app.put("certification_license", getPrimaryParamUpper(request, "certification_license"));
        app.put("certification_valid_until", getPrimaryParam(request, "certification_valid_until"));
        app.put("test_report_reference", getPrimaryParamUpper(request, "test_report_reference"));
        app.put("test_report_date", getPrimaryParam(request, "test_report_date"));
        app.put("warranty_years", getPrimaryParam(request, "warranty_years"));
        app.put("product_model", getPrimaryParamUpper(request, "product_model"));
        app.put("product_series", getPrimaryParamUpper(request, "product_series"));
        app.put("product_description", getPrimaryParamUpper(request, "product_description"));
        app.put("sabah_rep_name", getParamUpper(request, "sabah_rep_name"));
        app.put("sabah_rep_address", getParamUpper(request, "sabah_rep_address"));
        app.put("sabah_rep_phone", getParamUpper(request, "sabah_rep_phone"));
        app.put("declaration_name", getParamUpper(request, "declaration_name"));
        app.put("declaration_position", getParamUpper(request, "declaration_position"));
        return app;
    }

    private Set<String> fetchExistingDocumentKeys(Connection conn, int applicationId) throws SQLException {
        Set<String> existingDocKeys = new java.util.LinkedHashSet<>();
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT DISTINCT document_type FROM application_documents WHERE application_id = ?")) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    existingDocKeys.add(rs.getString("document_type"));
                }
            }
        }
        return existingDocKeys;
    }

    private String getUserApplicationStatus(Connection conn, int applicationId, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT status FROM applications WHERE id = ? AND user_id = ?")) {
            stmt.setInt(1, applicationId);
            stmt.setInt(2, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("status");
                }
                return null;
            }
        }
    }

    private boolean isEditableByApplicant(String status) {
        String normalized = status == null ? "" : status.trim().toUpperCase();
        return "DRAFT".equals(normalized)
                || "NEW".equals(normalized)
                || "UNDER_REVIEW".equals(normalized)
                || "IN_PROGRESS".equals(normalized)
                || "REJECTED".equals(normalized);
    }

    private boolean hasExistingDocument(Connection conn, int applicationId, String docType) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT 1 FROM application_documents WHERE application_id = ? AND document_type = ? LIMIT 1")) {
            stmt.setInt(1, applicationId);
            stmt.setString(2, docType);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void showRenewalApplicationForm(HttpServletRequest request, HttpServletResponse response,
            HttpSession session, int sourceApplicationId) throws ServletException, IOException {
        Integer userId = (Integer) session.getAttribute("user_id");
        try (Connection conn = DatabaseConfig.getConnection()) {
            request.setAttribute("approvedApplications", fetchApprovedApplicationsForUser(conn, userId));
            Map<String, Object> app = loadRenewalSourceApplication(conn, sourceApplicationId, userId);
            if (app == null || app.isEmpty()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan asal yang diluluskan tidak ditemui");
                return;
            }

            app.put("application_type", "PEMBAHARUAN");
            request.setAttribute("application", app);
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.setAttribute("existingDocumentKeys", fetchExistingDocumentKeys(conn, sourceApplicationId));
            request.setAttribute("renewalMode", true);
            request.setAttribute("renewalSourceApplicationId", sourceApplicationId);
            request.setAttribute("submission_token", createFormSubmissionToken(request));
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load renewal form source application #" + sourceApplicationId + ": " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private Map<String, Object> loadRenewalSourceApplication(Connection conn, int applicationId, int userId) throws SQLException {
        String sql = "SELECT a.*, ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
                + "ad.declaration_name, ad.declaration_position "
                + "FROM applications a LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ? AND a.user_id = ? AND a.status = 'APPROVED'";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.setInt(2, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> app = new HashMap<>();
                String productSummary = rs.getString("product_description");
                app.put("id", rs.getInt("id"));
                app.put("application_type", rs.getString("application_type"));
                app.put("supplier_name", firstNonBlank(rs.getString("supplier_name"), rs.getString("company_name")));
                app.put("supplier_email", rs.getString("email"));
                app.put("supplier_phone", firstNonBlank(rs.getString("supplier_phone"), rs.getString("contact_number")));
                app.put("supplier_address", firstNonBlank(rs.getString("supplier_address"), rs.getString("company_address")));
                app.put("manufacturer_name", rs.getString("manufacturer_name"));
                app.put("manufacturer_address", rs.getString("manufacturer_address"));
                app.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                app.put("principal_name", rs.getString("principal_name"));
                app.put("principal_address", rs.getString("principal_address"));
                app.put("principal_phone", rs.getString("principal_phone"));
                app.put("product_name", rs.getString("product_name"));
                app.put("product_category", rs.getString("product_category"));
                app.put("brand", extractFieldFromSummary(productSummary, "Jenama:"));
                app.put("standard_name", firstNonBlank(rs.getString("standard_name"), extractFieldFromSummary(productSummary, "Standard:")));
                app.put("certification_license", firstNonBlank(rs.getString("certification_license"), extractFieldFromSummary(productSummary, "No. Lesen Persijilan:")));
                app.put("certification_valid_until", firstNonBlank(
                        rs.getDate("certification_valid_until") == null ? "" : rs.getDate("certification_valid_until").toString(),
                        extractFieldFromSummary(productSummary, "Sah Sehingga:")));
                app.put("test_report_reference", firstNonBlank(rs.getString("test_report_reference"), extractFieldFromSummary(productSummary, "No. Laporan Ujian:")));
                app.put("test_report_date", firstNonBlank(
                        rs.getDate("test_report_date") == null ? "" : rs.getDate("test_report_date").toString(),
                        extractFieldFromSummary(productSummary, "Tarikh Laporan Ujian:")));
                app.put("warranty_years", firstNonBlank(
                        rs.getBigDecimal("warranty_years") == null ? "" : rs.getBigDecimal("warranty_years").toPlainString(),
                        extractFieldFromSummary(productSummary, "Tempoh Jaminan:")));
                String summaryPerihal = extractFieldFromSummary(productSummary, "Perihal Produk:");
                String summaryClass = extractFieldFromSummary(productSummary, "Class Produk:");
                String summarySize = extractFieldFromSummary(productSummary, "Saiz Produk:");
                app.put("product_model", extractFieldFromSummary(productSummary, "Model:"));
                app.put("product_series", extractFieldFromSummary(productSummary, "Siri:"));
                app.put("product_description", composeDescriptionWithClassAndSize(summaryPerihal, summaryClass, summarySize));
                app.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                app.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                app.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                app.put("declaration_name", rs.getString("declaration_name"));
                app.put("declaration_position", rs.getString("declaration_position"));
                return app;
            }
        }
    }

    private void showEditApplicationForm(HttpServletRequest request, HttpServletResponse response,
            HttpSession session, int applicationId) throws ServletException, IOException {
        Integer userId = (Integer) session.getAttribute("user_id");
        try (Connection conn = DatabaseConfig.getConnection()) {
            request.setAttribute("approvedApplications", fetchApprovedApplicationsForUser(conn, userId));
            String status = getUserApplicationStatus(conn, applicationId, userId);
            if (status == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            if (!isEditableByApplicant(status)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            String sql = "SELECT a.*, ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                    + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                    + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                    + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                    + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                    + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, "
                    + "ad.declaration_name, ad.declaration_position "
                    + "FROM applications a LEFT JOIN application_details ad ON ad.application_id = a.id "
                    + "WHERE a.id = ? AND a.user_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, applicationId);
                stmt.setInt(2, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                    Map<String, Object> app = new HashMap<>();
                        String productSummary = rs.getString("product_description");
                    app.put("id", rs.getInt("id"));
                    app.put("application_type", rs.getString("application_type"));
                        app.put("supplier_name", firstNonBlank(rs.getString("supplier_name"), rs.getString("company_name")));
                    app.put("supplier_email", rs.getString("email"));
                        app.put("supplier_phone", firstNonBlank(rs.getString("supplier_phone"), rs.getString("contact_number")));
                        app.put("supplier_address", firstNonBlank(rs.getString("supplier_address"), rs.getString("company_address")));
                    app.put("manufacturer_name", rs.getString("manufacturer_name"));
                    app.put("manufacturer_address", rs.getString("manufacturer_address"));
                    app.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    app.put("principal_name", rs.getString("principal_name"));
                    app.put("principal_address", rs.getString("principal_address"));
                    app.put("principal_phone", rs.getString("principal_phone"));
                    app.put("product_name", rs.getString("product_name"));
                    app.put("product_category", rs.getString("product_category"));
                        app.put("brand", extractFieldFromSummary(productSummary, "Jenama:"));
                        app.put("standard_name", firstNonBlank(rs.getString("standard_name"), extractFieldFromSummary(productSummary, "Standard:")));
                        app.put("certification_license", firstNonBlank(rs.getString("certification_license"), extractFieldFromSummary(productSummary, "No. Lesen Persijilan:")));
                        app.put("certification_valid_until", firstNonBlank(
                            rs.getDate("certification_valid_until") == null ? "" : rs.getDate("certification_valid_until").toString(),
                            extractFieldFromSummary(productSummary, "Sah Sehingga:")));
                        app.put("test_report_reference", firstNonBlank(rs.getString("test_report_reference"), extractFieldFromSummary(productSummary, "No. Laporan Ujian:")));
                        app.put("test_report_date", firstNonBlank(
                            rs.getDate("test_report_date") == null ? "" : rs.getDate("test_report_date").toString(),
                            extractFieldFromSummary(productSummary, "Tarikh Laporan Ujian:")));
                        app.put("warranty_years", firstNonBlank(
                            rs.getBigDecimal("warranty_years") == null ? "" : rs.getBigDecimal("warranty_years").toPlainString(),
                            extractFieldFromSummary(productSummary, "Tempoh Jaminan:")));
                        String summaryPerihal = extractFieldFromSummary(productSummary, "Perihal Produk:");
                        String summaryClass = extractFieldFromSummary(productSummary, "Class Produk:");
                        String summarySize = extractFieldFromSummary(productSummary, "Saiz Produk:");
                        app.put("product_model", extractFieldFromSummary(productSummary, "Model:"));
                        app.put("product_series", extractFieldFromSummary(productSummary, "Siri:"));
                        app.put("product_description", composeDescriptionWithClassAndSize(summaryPerihal, summaryClass, summarySize));
                    app.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    app.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    app.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    app.put("declaration_name", rs.getString("declaration_name"));
                    app.put("declaration_position", rs.getString("declaration_position"));
                    request.setAttribute("application", app);
                }
            }

            request.setAttribute("existingDocumentKeys", fetchExistingDocumentKeys(conn, applicationId));
            request.setAttribute("editMode", true);
            request.setAttribute("formAction", request.getContextPath() + "/applications/" + applicationId + "/edit");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.setAttribute("submission_token", createFormSubmissionToken(request));
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load edit form for application #" + applicationId + ": " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private String extractFieldFromSummary(String summary, String fieldLabel) {
        if (summary == null || summary.isBlank() || fieldLabel == null || fieldLabel.isBlank()) {
            return "";
        }
        int idx = summary.indexOf(fieldLabel);
        if (idx < 0) {
            return "";
        }
        int start = idx + fieldLabel.length();
        String remainder = summary.substring(start).trim();
        int separator = remainder.indexOf("|");
        if (separator >= 0) {
            String extracted = remainder.substring(0, separator).trim();
            return "-".equals(extracted) ? "" : extracted;
        }
        String extracted = remainder.trim();
        return "-".equals(extracted) ? "" : extracted;
    }

    private List<Map<String, Object>> fetchApprovedApplicationsForUser(Connection conn, int userId) throws SQLException {
        List<Map<String, Object>> approvedApps = new ArrayList<>();
        String sql = "SELECT a.id, a.product_name, a.product_category, a.product_description, a.company_name, a.company_address, a.contact_number, a.email, "
                + "ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone "
                + "FROM applications a LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.user_id = ? AND a.status = 'APPROVED' ORDER BY a.submitted_at DESC, a.id DESC";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    String productSummary = rs.getString("product_description");
                    Map<String, Object> app = new HashMap<>();
                    app.put("id", rs.getInt("id"));
                    app.put("product_name", rs.getString("product_name"));
                    app.put("product_category", rs.getString("product_category"));
                    app.put("supplier_name", firstNonBlank(rs.getString("supplier_name"), rs.getString("company_name")));
                    app.put("supplier_email", rs.getString("email"));
                    app.put("supplier_phone", firstNonBlank(rs.getString("supplier_phone"), rs.getString("contact_number")));
                    app.put("supplier_address", firstNonBlank(rs.getString("supplier_address"), rs.getString("company_address")));
                    app.put("manufacturer_name", rs.getString("manufacturer_name"));
                    app.put("manufacturer_address", rs.getString("manufacturer_address"));
                    app.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                    app.put("principal_name", rs.getString("principal_name"));
                    app.put("principal_address", rs.getString("principal_address"));
                    app.put("principal_phone", rs.getString("principal_phone"));
                    app.put("brand", extractFieldFromSummary(productSummary, "Jenama:"));
                    app.put("standard_name", firstNonBlank(rs.getString("standard_name"), extractFieldFromSummary(productSummary, "Standard:")));
                    app.put("certification_license", firstNonBlank(rs.getString("certification_license"), extractFieldFromSummary(productSummary, "No. Lesen Persijilan:")));
                    app.put("certification_valid_until", firstNonBlank(
                            rs.getDate("certification_valid_until") == null ? "" : rs.getDate("certification_valid_until").toString(),
                            extractFieldFromSummary(productSummary, "Sah Sehingga:")));
                    app.put("test_report_reference", firstNonBlank(rs.getString("test_report_reference"), extractFieldFromSummary(productSummary, "No. Laporan Ujian:")));
                    app.put("test_report_date", firstNonBlank(
                            rs.getDate("test_report_date") == null ? "" : rs.getDate("test_report_date").toString(),
                            extractFieldFromSummary(productSummary, "Tarikh Laporan Ujian:")));
                    app.put("warranty_years", firstNonBlank(
                            rs.getBigDecimal("warranty_years") == null ? "" : rs.getBigDecimal("warranty_years").toPlainString(),
                            extractFieldFromSummary(productSummary, "Tempoh Jaminan:")));
                    String summaryPerihal = extractFieldFromSummary(productSummary, "Perihal Produk:");
                    String summaryClass = extractFieldFromSummary(productSummary, "Class Produk:");
                    String summarySize = extractFieldFromSummary(productSummary, "Saiz Produk:");
                    app.put("product_model", extractFieldFromSummary(productSummary, "Model:"));
                    app.put("product_series", extractFieldFromSummary(productSummary, "Siri:"));
                    app.put("product_description", composeDescriptionWithClassAndSize(summaryPerihal, summaryClass, summarySize));
                    app.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                    app.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                    app.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                    approvedApps.add(app);
                }
            }
        }
        return approvedApps;
    }

    private String firstNonBlank(String... values) {
        if (values == null) {
            return "";
        }
        for (String value : values) {
            if (value != null && !value.trim().isEmpty()) {
                return value.trim();
            }
        }
        return "";
    }

    private static Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private boolean isSupportedApplicationType(String applicationType) {
        String normalized = trim(applicationType).toUpperCase(Locale.ROOT);
        return APPLICATION_TYPE_KEMASKINI.equals(normalized)
                || APPLICATION_TYPE_BAHARU.equals(normalized)
                || APPLICATION_TYPE_PEMBAHARUAN.equals(normalized);
    }

    private boolean isEditPath(String pathInfo) {
        if (pathInfo == null || pathInfo.isBlank()) {
            return false;
        }
        return EDIT_PATH_PATTERN.matcher(pathInfo).matches();
    }

    private Integer extractEditApplicationId(String pathInfo) {
        if (pathInfo == null) {
            return null;
        }
        Matcher matcher = EDIT_PATH_PATTERN.matcher(pathInfo);
        if (!matcher.matches()) {
            return null;
        }
        try {
            return Integer.parseInt(matcher.group(1));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private void insertAuditLog(Connection conn, Integer userId, String ipAddress, int applicationId) throws SQLException {
        DashboardDataService.ensureAuditLogTable(conn);
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, "CREATE APPLICATION");
            stmt.setString(3, "Permohonan online PPP1 dihantar. ID: " + applicationId);
            stmt.setString(4, ipAddress);
            stmt.executeUpdate();
        }
    }

    private void ensureOnlineApplicationSchema(Connection conn) throws SQLException {
        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS application_details ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY,"
                    + "application_id INT NOT NULL,"
                    + "application_type ENUM('KEMASKINI','BAHARU','PEMBAHARUAN') NOT NULL,"
                    + "supplier_name VARCHAR(255) NOT NULL,"
                    + "supplier_address TEXT NOT NULL,"
                    + "supplier_phone VARCHAR(50),"
                    + "manufacturer_name VARCHAR(255),"
                    + "manufacturer_address TEXT,"
                    + "manufacturer_phone VARCHAR(50),"
                    + "principal_name VARCHAR(255),"
                    + "principal_address TEXT,"
                    + "principal_phone VARCHAR(50),"
                    + "standard_name VARCHAR(255),"
                    + "certification_license VARCHAR(255),"
                    + "certification_valid_until DATE,"
                    + "test_report_reference VARCHAR(255),"
                    + "test_report_date DATE,"
                    + "warranty_years DECIMAL(5,2),"
                    + "sabah_rep_name VARCHAR(255),"
                    + "sabah_rep_address TEXT,"
                    + "sabah_rep_phone VARCHAR(50),"
                    + "declaration_name VARCHAR(255),"
                    + "declaration_position VARCHAR(255),"
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                    + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                    + "UNIQUE KEY uniq_application_detail (application_id),"
                    + "FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE)"
            );
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS application_documents ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY,"
                    + "application_id INT NOT NULL,"
                    + "document_type VARCHAR(100) NOT NULL,"
                    + "original_filename VARCHAR(255) NOT NULL,"
                    + "stored_filename VARCHAR(255) NOT NULL,"
                    + "stored_path TEXT NOT NULL,"
                    + "content_type VARCHAR(100),"
                    + "file_size BIGINT NOT NULL DEFAULT 0,"
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                    + "INDEX idx_application_id (application_id),"
                    + "INDEX idx_document_type (document_type),"
                    + "FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE)"
            );

            // Ensure workflow statuses are accepted by legacy ENUM schema.
            stmt.executeUpdate("ALTER TABLE applications MODIFY COLUMN status ENUM('DRAFT','NEW','DIRECTOR_REVIEW','UNDER_REVIEW','IN_PROGRESS','MENUNGGU_TINDAKAN_PENGARAH','MENUNGGU_SETERUSNYA_DILULUSKAN','MENUNGGU_SETERUSNYA_GAGAL','MENUNGGU_SETERUSNYA_GANTUNG','MENUNGGU_SETERUSNYA_BATAL','DILULUSKAN_PENGARAH','APPROVED','REJECTED','SUSPENDED','ARCHIVED','KUERI') NOT NULL DEFAULT 'NEW'");
            stmt.executeUpdate("ALTER TABLE application_details MODIFY COLUMN application_type ENUM('KEMASKINI','BAHARU','PEMBAHARUAN') NOT NULL");
        }
    }

    private Map<String, String> buildRequiredDocuments() {
        Map<String, String> docs = new LinkedHashMap<>();
        docs.put("official_application_letter", "Surat permohonan rasmi kepada Pengarah JANS");
        docs.put("principal_appointment_letter", "Surat pelantikan pembekal dari prinsipal/pemilik produk");
        docs.put("renewal_certificate", "Salinan sijil/perakuan sedia ada (wajib untuk kemaskini dan pembaharuan)");
        docs.put("certification_license_file", "Lesen persijilan produk (SIRIM/IKRAM/dll)");
        docs.put("specification_document", "Dokumen Spesifikasi");
        docs.put("test_report_file", "Laporan pengujian yang masih sah");
        docs.put("brochure_catalogue", "Brosur atau katalog produk");
        docs.put("price_list", "Senarai harga semasa");
        docs.put("product_benefit_summary", "Penerangan fungsi, faedah dan kelebihan produk");
        docs.put("project_reference", "Senarai rujukan projek / rekod prestasi produk");
        docs.put("recommendation_letter", "Surat pengesahan atau rekomendasi pengguna, jika ada");
        docs.put("sop_document", "SOP pengendalian dan penyimpanan produk");
        docs.put("performance_monitoring_program", "Program pemantauan prestasi produk / track record 5 tahun");
        return docs;
    }

    private Set<String> buildMandatoryDocuments(String applicationType) {
        Set<String> mandatoryDocs = new java.util.LinkedHashSet<>();
        mandatoryDocs.add("official_application_letter");
        mandatoryDocs.add("principal_appointment_letter");
        mandatoryDocs.add("certification_license_file");
        mandatoryDocs.add("test_report_file");
        mandatoryDocs.add("brochure_catalogue");
        mandatoryDocs.add("price_list");
        mandatoryDocs.add("product_benefit_summary");
        mandatoryDocs.add("project_reference");
        mandatoryDocs.add("specification_document");
        mandatoryDocs.add("sop_document");
        mandatoryDocs.add("performance_monitoring_program");

        if (APPLICATION_TYPE_PEMBAHARUAN.equalsIgnoreCase(trim(applicationType))
                || APPLICATION_TYPE_KEMASKINI.equalsIgnoreCase(trim(applicationType))) {
            mandatoryDocs.add("renewal_certificate");
        }
        return mandatoryDocs;
    }

    private List<String> findMissingMandatoryDocuments(HttpServletRequest request, String applicationType,
            Connection conn, Integer applicationId)
            throws IOException, ServletException, SQLException {
        Map<String, String> allDocs = buildRequiredDocuments();
        Set<String> mandatoryDocKeys = buildMandatoryDocuments(applicationType);
        List<String> missing = new ArrayList<>();

        for (String docKey : mandatoryDocKeys) {
            Part part = request.getPart(docKey);
            boolean hasNewUpload = part != null && part.getSize() > 0;
            if (hasNewUpload) {
                continue;
            }
            boolean hasExisting = conn != null && applicationId != null && hasExistingDocument(conn, applicationId, docKey);
            if (!hasExisting) {
                missing.add(allDocs.getOrDefault(docKey, docKey));
            }
        }

        if (missing.isEmpty()) {
            return Collections.emptyList();
        }
        return missing;
    }

    private String buildApplicationSummary(HttpServletRequest request) {
        List<String> productNames = getParamListUpper(request, "product_name");
        List<String> productCategories = getParamListUpper(request, "product_category");
        List<String> brands = getParamListUpper(request, "brand");
        List<String> standards = getParamListUpper(request, "standard_name");
        List<String> certificationLicenses = getParamListUpper(request, "certification_license");
        List<String> certificationValidUntil = getParamList(request, "certification_valid_until");
        List<String> testReportReferences = getParamListUpper(request, "test_report_reference");
        List<String> testReportDates = getParamList(request, "test_report_date");
        List<String> warrantyYears = getParamList(request, "warranty_years");
        List<String> productModels = getParamListUpper(request, "product_model");
        List<String> productSeries = getParamListUpper(request, "product_series");
        List<String> productDescriptions = getParamListUpper(request, "product_description");

        int productCount = productNames.size();
        productCount = Math.max(productCount, productCategories.size());
        productCount = Math.max(productCount, brands.size());
        productCount = Math.max(productCount, standards.size());
        productCount = Math.max(productCount, certificationLicenses.size());
        productCount = Math.max(productCount, certificationValidUntil.size());
        productCount = Math.max(productCount, testReportReferences.size());
        productCount = Math.max(productCount, testReportDates.size());
        productCount = Math.max(productCount, warrantyYears.size());
        productCount = Math.max(productCount, productModels.size());
        productCount = Math.max(productCount, productSeries.size());
        productCount = Math.max(productCount, productDescriptions.size());
        StringBuilder productLines = new StringBuilder();
        for (int i = 0; i < productCount; i++) {
            String name = getValueAt(productNames, i);
            String category = getValueAt(productCategories, i);
            String brand = getValueAt(brands, i);
            String standard = getValueAt(standards, i);
            String certificationLicense = getValueAt(certificationLicenses, i);
            String certificationUntil = getValueAt(certificationValidUntil, i);
            String testReportReference = getValueAt(testReportReferences, i);
            String testReportDate = getValueAt(testReportDates, i);
            String warranty = getValueAt(warrantyYears, i);
            String model = getValueAt(productModels, i);
            String series = getValueAt(productSeries, i);
            String description = getValueAt(productDescriptions, i);
            if (name.isEmpty() && category.isEmpty() && brand.isEmpty() && standard.isEmpty()
                    && certificationLicense.isEmpty() && certificationUntil.isEmpty()
                    && testReportReference.isEmpty() && testReportDate.isEmpty()
                    && warranty.isEmpty() && model.isEmpty() && series.isEmpty() && description.isEmpty()) {
                continue;
            }
            if (productLines.length() > 0) {
                productLines.append("\n");
            }
            productLines.append("Produk ").append(i + 1).append(": ")
                    .append(name.isEmpty() ? "-" : name)
                    .append(" | Kategori: ").append(category.isEmpty() ? "-" : category)
                    .append(" | Jenama: ").append(brand.isEmpty() ? "-" : brand)
                    .append(" | Standard: ").append(standard.isEmpty() ? "-" : standard)
                    .append(" | No. Lesen Persijilan: ").append(certificationLicense.isEmpty() ? "-" : certificationLicense)
                    .append(" | Sah Sehingga: ").append(certificationUntil.isEmpty() ? "-" : certificationUntil)
                    .append(" | No. Laporan Ujian: ").append(testReportReference.isEmpty() ? "-" : testReportReference)
                    .append(" | Tarikh Laporan Ujian: ").append(testReportDate.isEmpty() ? "-" : testReportDate)
                    .append(" | Tempoh Jaminan: ").append(warranty.isEmpty() ? "-" : warranty)
                    .append(" | Model: ").append(model.isEmpty() ? "-" : model)
                    .append(" | Siri: ").append(series.isEmpty() ? "-" : series)
                    .append(" | Perihal Produk: ").append(description.isEmpty() ? "-" : description);
        }

        return "Jenis Permohonan: " + getParamUpper(request, "application_type")
                + "\nSenarai Produk:\n" + (productLines.length() == 0 ? "-" : productLines);
    }

    private String composeDescriptionWithClassAndSize(String description, String productClass, String productSize) {
        String safeDescription = description == null ? "" : description.trim();
        String safeClass = productClass == null ? "" : productClass.trim();
        String safeSize = productSize == null ? "" : productSize.trim();

        List<String> segments = new ArrayList<>();
        if (!safeDescription.isEmpty()) {
            segments.add(safeDescription);
        }
        if (!safeClass.isEmpty()) {
            segments.add("Class: " + safeClass);
        }
        if (!safeSize.isEmpty()) {
            segments.add("Saiz: " + safeSize);
        }
        return String.join(" | ", segments);
    }

    private String extractSubmittedFileName(Part part) {
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return "document.pdf";
        }
        return Path.of(submitted).getFileName().toString();
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private void sendDirectorReviewNotification(HttpServletRequest request, Connection conn, int applicationId) {
        // Fungsi ini hantar emel notifikasi kepada semua pengguna role DIRECTOR yang aktif.
        // Ia dipanggil selepas permohonan berjaya dihantar ke status menunggu tindakan Pengarah.
        // Penting: jika SMTP tak lengkap atau tiada pengarah aktif, fungsi akan skip secara selamat.
        try {
            ensureSmtpSettingsTable(conn);
            Map<String, String> smtpSettings = loadSmtpSettings(conn);

            String smtpHost = coalesceSmtpValue(smtpSettings.get("smtp_host"), getContextParam(request, "smtp.host", ""));
            int smtpPort = parsePositiveIntOrDefault(
                    coalesceSmtpValue(smtpSettings.get("smtp_port"), getContextParam(request, "smtp.port", "587")),
                    587);
            boolean smtpAuth = parseBoolean(
                    coalesceSmtpValue(smtpSettings.get("smtp_auth"), getContextParam(request, "smtp.auth", "true")),
                    true);
            boolean smtpTls = parseBoolean(
                    coalesceSmtpValue(smtpSettings.get("smtp_tls"), getContextParam(request, "smtp.tls", "true")),
                    true);
            String smtpUser = coalesceSmtpValue(smtpSettings.get("smtp_username"), getContextParam(request, "smtp.username", ""));
            String smtpPass = coalesceSmtpValue(smtpSettings.get("smtp_password"), getContextParam(request, "smtp.password", ""));
            String smtpFrom = coalesceSmtpValue(smtpSettings.get("smtp_from"), getContextParam(request, "smtp.from", smtpUser));

            if (smtpHost.isBlank()) {
                LOGGER.info("Director notification skipped: SMTP host not configured.");
                return;
            }
            if (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank())) {
                LOGGER.info("Director notification skipped: SMTP auth credentials incomplete.");
                return;
            }
            if (smtpFrom.isBlank()) {
                smtpFrom = smtpUser;
            }

            Map<String, Object> applicationData = loadApplicationForDirectorEmail(conn, applicationId);
            if (applicationData.isEmpty()) {
                return;
            }

            List<Map<String, String>> directorRecipients = loadDirectorRecipients(conn);
            if (directorRecipients.isEmpty()) {
                LOGGER.info("Director notification skipped: no active director recipients.");
                return;
            }

            String companyName = String.valueOf(applicationData.getOrDefault("company_name", "-")).trim();
            String productName = String.valueOf(applicationData.getOrDefault("product_name", "-")).trim();
            String applicantName = String.valueOf(applicationData.getOrDefault("full_name", "-")).trim();
            String submittedAt = String.valueOf(applicationData.getOrDefault("submitted_at", "-")).trim();

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            String appRef = String.format("PPP%03d", applicationId);

            for (Map<String, String> recipient : directorRecipients) {
                String toEmail = recipient.getOrDefault("email", "");
                if (toEmail.isBlank()) {
                    continue;
                }
                Integer directorId = parseInteger(recipient.get("id"));
                if (directorId == null) {
                    LOGGER.warning("Director notification skipped: recipient id missing for email " + toEmail);
                    continue;
                }
                String accessUrl = buildDirectorAccessUrl(request, directorId, toEmail, applicationId);
                String directorName = recipient.getOrDefault("full_name", "Pengarah");
                Map<String, String> vars = new LinkedHashMap<>();
                vars.put("director_name", escapeHtml(directorName));
                vars.put("app_ref", escapeHtml(appRef));
                vars.put("applicant_name", escapeHtml(applicantName));
                vars.put("company_name", escapeHtml(companyName));
                vars.put("product_name", escapeHtml(productName));
                vars.put("submitted_at", escapeHtml(submittedAt));
                vars.put("review_stage_label", "tindakan");
                vars.put("action_intro", "Terdapat permohonan baharu yang memerlukan tindakan Pengarah.");
                vars.put("dashboard_url", escapeHtml(accessUrl));
                vars.put("dashboard_link_html", buildHtmlLink(accessUrl, "Klik Di Sini"));

                String fallbackSubject = "Permohonan Baharu Menunggu Tindakan Pengarah";
                String fallbackBody = "<div style=\"font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:14px;line-height:1.6;color:#183244;\">"
                    + "<p>Tuan/Puan Pengarah " + escapeHtml(directorName) + ",</p>"
                    + "<p><strong>PERMOHONAN UNTUK TINDAKAN PENGARAH</strong></p>"
                    + "<p>Dengan hormatnya perkara di atas adalah dirujuk.</p>"
                    + "<p>2. Adalah dimaklumkan bahawa terdapat permohonan baharu yang memerlukan tindakan Pengarah bagi rujukan <strong>"
                    + escapeHtml(appRef) + "</strong>.</p>"
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
                    + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>"
                    + "</div>";
                String subject = TemplateService.renderEmailSubject(conn, "DIRECTOR_ACTION_REQUEST", vars, fallbackSubject);
                String body = TemplateService.renderEmailBody(conn, "DIRECTOR_ACTION_REQUEST", vars, fallbackBody);
                emailUtil.sendHtml(toEmail, subject, body);
            }
        } catch (Exception ex) {
            LOGGER.warning("Failed to send director review notification for application #" + applicationId + ": " + ex.getMessage());
        }
    }

    private Map<String, Object> loadApplicationForDirectorEmail(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.company_name, a.product_name, DATE_FORMAT(a.submitted_at, '%d/%m/%Y') AS submitted_date, u.full_name "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return Collections.emptyMap();
                }
                Map<String, Object> row = new HashMap<>();
                row.put("company_name", rs.getString("company_name"));
                row.put("product_name", rs.getString("product_name"));
                row.put("submitted_at", rs.getString("submitted_date"));
                row.put("full_name", rs.getString("full_name"));
                return row;
            }
        }
    }

    private String buildHtmlLink(String url, String label) {
        if (url == null || url.isBlank()) {
            return "";
        }
        String safeUrl = escapeHtml(url);
        String safeLabel = escapeHtml(label == null || label.isBlank() ? url : label);
        return "<a href=\"" + safeUrl + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + safeLabel + "</a>";
    }

    private List<Map<String, String>> loadDirectorRecipients(Connection conn) throws SQLException {
        List<Map<String, String>> recipients = new ArrayList<>();
        String sql = "SELECT id, full_name, email FROM users "
                + "WHERE role = 'DIRECTOR' AND status = 'ACTIVE' AND email IS NOT NULL AND TRIM(email) <> '' "
                + "ORDER BY id ASC";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("id", String.valueOf(rs.getInt("id")));
                row.put("full_name", trim(rs.getString("full_name")));
                row.put("email", trim(rs.getString("email")));
                recipients.add(row);
            }
        }
        return recipients;
    }

    public static String buildDirectorAccessUrl(HttpServletRequest request, Integer directorId, String directorEmail, int applicationId) {
        // Jana pautan khas sekali-klik untuk Pengarah.
        // Pautan ini bawa token bertandatangan (id user + email + app id + expiry)
        // supaya pengarah boleh terus buka rekod tanpa perlu cari manual dalam dashboard.
        String normalizedEmail = directorEmail == null ? "" : directorEmail.trim().toLowerCase(Locale.ROOT);
        long expiresAt = Instant.now().getEpochSecond() + DIRECTOR_LINK_VALIDITY_SECONDS;
        String payload = directorId + "|" + normalizedEmail + "|" + applicationId + "|" + expiresAt;
        String signature = signDirectorPayload(payload, resolveDirectorLinkSecret(request.getServletContext()));
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(payload.getBytes(StandardCharsets.UTF_8))
                + "." + signature;
        String base = resolvePublicAppBaseUrl(request);
        return base + "/director/access?token=" + java.net.URLEncoder.encode(token, StandardCharsets.UTF_8);
    }

    public static DirectorAccessTokenPayload validateDirectorAccessToken(String token, ServletContext servletContext) {
        if (token == null || token.isBlank()) {
            LOGGER.warning("[DirectorToken] Token null or blank");
            return null;
        }

        String normalizedToken = normalizeDirectorToken(token);
        LOGGER.info("[DirectorToken] Normalized: " + normalizedToken);
        String[] parts = splitDirectorToken(normalizedToken);
        if (parts.length != 2) {
            LOGGER.warning("[DirectorToken] Split failed, parts=" + parts.length + " token=" + normalizedToken);
            return null;
        }

        String payloadEncoded = parts[0];
        String signature = trim(parts[1]);
        if (payloadEncoded == null || payloadEncoded.isBlank() || signature == null || signature.isBlank()) {
            LOGGER.warning("[DirectorToken] Empty payload or signature after split");
            return null;
        }

        String payloadRaw = decodeDirectorPayload(payloadEncoded);
        if (payloadRaw == null || payloadRaw.isBlank()) {
            LOGGER.warning("[DirectorToken] Failed to decode payload: " + payloadEncoded);
            return null;
        }
        LOGGER.info("[DirectorToken] Decoded payload: " + payloadRaw);

        String secret = resolveDirectorLinkSecret(servletContext);
        String expectedSignature = signDirectorPayload(payloadRaw, secret);
        if (!constantTimeEquals(signature.toLowerCase(Locale.ROOT), expectedSignature.toLowerCase(Locale.ROOT))) {
            LOGGER.warning("[DirectorToken] Signature mismatch. Got=" + signature + " Expected=" + expectedSignature);
            return null;
        }

        String[] payloadParts = payloadRaw.split("\\|");
        if (payloadParts.length != 4) {
            return null;
        }

        Integer userId = parseInteger(payloadParts[0]);
        Integer applicationIdValue = parseInteger(payloadParts[2]);
        int applicationId = applicationIdValue == null ? -1 : applicationIdValue;
        long expiresAt;
        try {
            expiresAt = Long.parseLong(payloadParts[3]);
        } catch (NumberFormatException ex) {
            return null;
        }

        long now = Instant.now().getEpochSecond();
        if (userId == null || applicationId <= 0) {
            LOGGER.warning("[DirectorToken] Invalid userId or applicationId in payload: " + payloadRaw);
            return null;
        }
        if (expiresAt < now) {
            LOGGER.warning("[DirectorToken] Token EXPIRED. expiresAt=" + expiresAt + " now=" + now + " (expired " + (now - expiresAt) + "s ago)");
            return null;
        }

        String email = trim(payloadParts[1]).toLowerCase(Locale.ROOT);
        return new DirectorAccessTokenPayload(userId, email, applicationId, expiresAt);
    }

    private static String normalizeDirectorToken(String token) {
        String value = trim(token);
        if (value == null || value.isBlank()) {
            return "";
        }

        if (value.startsWith("token=")) {
            value = value.substring("token=".length());
        }
        if (value.startsWith("amp;token=")) {
            value = value.substring("amp;token=".length());
        }

        // Some clients/proxies may double-encode query params.
        for (int i = 0; i < 2; i++) {
            if (value.indexOf('%') < 0) {
                break;
            }
            try {
                String decoded = URLDecoder.decode(value, StandardCharsets.UTF_8);
                if (decoded.equals(value)) {
                    break;
                }
                value = decoded;
            } catch (IllegalArgumentException ex) {
                break;
            }
        }

        return trim(value);
    }

    private static String[] splitDirectorToken(String token) {
        if (token == null || token.isBlank()) {
            return new String[0];
        }
        if (token.contains(".")) {
            return token.split("\\.", 2);
        }
        // Legacy fallback: payload and signature separated by colon.
        if (token.contains(":")) {
            return token.split(":", 2);
        }
        return new String[0];
    }

    private static String decodeDirectorPayload(String payloadEncoded) {
        if (payloadEncoded == null || payloadEncoded.isBlank()) {
            return null;
        }

        if (payloadEncoded.contains("|")) {
            return payloadEncoded;
        }

        String candidate = payloadEncoded.trim();
        try {
            return new String(Base64.getUrlDecoder().decode(candidate), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ignored) {
            // try legacy base64 variants below
        }

        String plusCandidate = candidate.replace(' ', '+');
        try {
            return new String(Base64.getDecoder().decode(plusCandidate), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ignored) {
            // try normalized url/base64 alphabet conversion
        }

        String normalized = candidate.replace('-', '+').replace('_', '/').replace(' ', '+');
        int mod = normalized.length() % 4;
        if (mod > 0) {
            normalized += "=".repeat(4 - mod);
        }
        try {
            return new String(Base64.getDecoder().decode(normalized), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ignored) {
            return null;
        }
    }

    private static String signDirectorPayload(String payload, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] digest = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                String part = Integer.toHexString(b & 0xff);
                if (part.length() == 1) {
                    hex.append('0');
                }
                hex.append(part);
            }
            return hex.toString();
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("Unable to sign director access payload", ex);
        }
    }

    private static String resolveDirectorLinkSecret(ServletContext servletContext) {
        String envSecret = System.getenv("DIRECTOR_LINK_SECRET");
        if (envSecret != null && !envSecret.isBlank()) {
            return envSecret.trim();
        }
        String contextSecret = servletContext.getInitParameter("director.link.secret");
        if (contextSecret != null && !contextSecret.isBlank()) {
            return contextSecret.trim();
        }
        return "SPPA_DIRECTOR_LINK_SECRET_CHANGE_ME";
    }

    private static boolean constantTimeEquals(String a, String b) {
        byte[] left = (a == null ? "" : a).getBytes(StandardCharsets.UTF_8);
        byte[] right = (b == null ? "" : b).getBytes(StandardCharsets.UTF_8);
        if (left.length != right.length) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < left.length; i++) {
            result |= left[i] ^ right[i];
        }
        return result == 0;
    }

    public static record DirectorAccessTokenPayload(int userId, String email, int applicationId, long expiresAt) {}

    private static String resolvePublicAppBaseUrl(HttpServletRequest request) {
        return PublicUrlResolver.resolveBaseUrl(request, getContextParam(request, "app.base.url", ""));
    }

    private String buildRequestBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String serverName = request.getServerName();
        int port = request.getServerPort();
        String contextPath = request.getContextPath();
        boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                || ("https".equalsIgnoreCase(scheme) && port == 443);
        return normalizeBaseUrl(scheme + "://" + serverName + (defaultPort ? "" : ":" + port) + contextPath);
    }

    private static String normalizeBaseUrl(String baseUrl) {
        String value = trim(baseUrl);
        while (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        return value;
    }

    private boolean isLocalHostUrl(String url) {
        String value = trim(url).toLowerCase(Locale.ROOT);
        return value.startsWith("http://localhost")
                || value.startsWith("https://localhost")
                || value.startsWith("http://127.0.0.1")
                || value.startsWith("https://127.0.0.1")
                || value.startsWith("http://0.0.0.0")
                || value.startsWith("https://0.0.0.0")
                || value.startsWith("http://[::1]")
                || value.startsWith("https://[::1]");
    }

    private boolean isLocalHostName(String hostName) {
        String value = trim(hostName).toLowerCase(Locale.ROOT);
        return "localhost".equals(value)
                || "127.0.0.1".equals(value)
                || "0.0.0.0".equals(value)
                || "::1".equals(value)
                || "[::1]".equals(value);
    }

    private Map<String, String> loadSmtpSettings(Connection conn) throws SQLException {
        Map<String, String> settings = new LinkedHashMap<>();
        String sql = "SELECT setting_key, setting_value FROM smtp_settings WHERE enabled = 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                String key = rs.getString("setting_key");
                String value = rs.getString("setting_value");
                if (key != null && !key.isBlank()) {
                    settings.put(key.trim(), value == null ? "" : value.trim());
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

    private static String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        return value.trim();
    }

    private String coalesceSmtpValue(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null ? "" : fallback.trim();
    }

    private boolean parseBoolean(String raw, boolean defaultValue) {
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        String normalized = raw.trim().toLowerCase(java.util.Locale.ROOT);
        if ("true".equals(normalized) || "1".equals(normalized) || "yes".equals(normalized) || "on".equals(normalized)) {
            return true;
        }
        if ("false".equals(normalized) || "0".equals(normalized) || "no".equals(normalized) || "off".equals(normalized)) {
            return false;
        }
        return defaultValue;
    }

    private int parsePositiveIntOrDefault(String raw, int defaultValue) {
        Integer parsed = parseInteger(raw);
        if (parsed == null || parsed <= 0) {
            return defaultValue;
        }
        return parsed;
    }

    private String escapeHtml(String text) {
        if (text == null) {
            return "";
        }
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String toUpperInfo(String value) {
        String cleaned = trim(value);
        return cleaned.isEmpty() ? cleaned : cleaned.toUpperCase(Locale.ROOT);
    }

    private String getParamUpper(HttpServletRequest request, String paramName) {
        return toUpperInfo(request.getParameter(paramName));
    }

    private String getPrimaryParam(HttpServletRequest request, String baseName) {
        List<String> values = getParamList(request, baseName);
        if (!values.isEmpty()) {
            return values.get(0);
        }
        return "";
    }

    private String getPrimaryParamUpper(HttpServletRequest request, String baseName) {
        return toUpperInfo(getPrimaryParam(request, baseName));
    }

    private List<String> getParamList(HttpServletRequest request, String baseName) {
        List<String> values = new ArrayList<>();
        String[] arrayValues = request.getParameterValues(baseName + "[]");
        if (arrayValues != null) {
            for (String raw : arrayValues) {
                String cleaned = trim(raw);
                if (!cleaned.isEmpty()) {
                    values.add(cleaned);
                }
            }
            return values;
        }

        String singleValue = trim(request.getParameter(baseName));
        if (!singleValue.isEmpty()) {
            values.add(singleValue);
        }
        return values;
    }

    private List<String> getParamListUpper(HttpServletRequest request, String baseName) {
        List<String> values = getParamList(request, baseName);
        List<String> upperValues = new ArrayList<>(values.size());
        for (String value : values) {
            upperValues.add(toUpperInfo(value));
        }
        return upperValues;
    }

    private String getValueAt(List<String> values, int index) {
        if (index < 0 || index >= values.size()) {
            return "";
        }
        return values.get(index);
    }

    private Date parseDate(String value) {
        String trimmed = trim(value);
        if (trimmed.isEmpty()) {
            return null;
        }
        return Date.valueOf(trimmed);
    }

    private java.math.BigDecimal parseDecimal(String value) {
        String trimmed = trim(value);
        if (trimmed.isEmpty()) {
            return null;
        }
        return new java.math.BigDecimal(trimmed);
    }
}


package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
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
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.logging.Logger;

@MultipartConfig(maxFileSize = 15 * 1024 * 1024, maxRequestSize = 120 * 1024 * 1024)
public class ApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ApplicationServlet.class.getName());
    private static final Pattern EDIT_PATH_PATTERN = Pattern.compile("^/(\\d+)/edit$");
    private static final String RENEW_FROM_PARAM = "renewFrom";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
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
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
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

        String applicationType = trim(request.getParameter("application_type"));
        String supplierName = trim(request.getParameter("supplier_name"));
        String productName = getPrimaryParam(request, "product_name");
        String productCategory = getPrimaryParam(request, "product_category");
        Integer renewalSourceId = parseInteger(request.getParameter("renew_from_application_id"));

        if (supplierName.isEmpty() || productName.isEmpty() || productCategory.isEmpty() || applicationType.isEmpty()) {
            prepareCreateFormStateFromRequest(request, renewalSourceId, null);
            request.setAttribute("error", "Sila lengkapkan bahagian wajib borang PPP1.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        try (Connection validationConn = DatabaseConfig.getConnection()) {
            Integer validationApplicationId = null;
            if (renewalSourceId != null && "PEMBAHARUAN".equalsIgnoreCase(applicationType)) {
                Map<String, Object> renewalSource = loadRenewalSourceApplication(validationConn, renewalSourceId, userId);
                if (renewalSource == null || renewalSource.isEmpty()) {
                    prepareCreateFormStateFromRequest(request, null, validationConn);
                    request.setAttribute("error", "Permohonan asal untuk pembaharuan tidak sah atau tidak ditemui.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                    return;
                }
                validationApplicationId = renewalSourceId;
            }
            List<String> missingMandatoryDocs = findMissingMandatoryDocuments(request, applicationType, validationConn, validationApplicationId);
            if (!missingMandatoryDocs.isEmpty()) {
                prepareCreateFormStateFromRequest(request, renewalSourceId, validationConn);
                request.setAttribute("error", "Tidak Berjaya Sila Lengkapkan Dokumen yang diperlukan!");
                request.setAttribute("missingMandatoryDocuments", missingMandatoryDocs);
                request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                return;
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to validate mandatory documents: " + e.getMessage());
            prepareCreateFormStateFromRequest(request, renewalSourceId, null);
            request.setAttribute("error", "Ralat semasa menyemak dokumen. Sila cuba lagi.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        // Check active application limit (max 3 PENDING or DRAFT)
        try (Connection limitConn = DatabaseConfig.getConnection();
             PreparedStatement limitPs = limitConn.prepareStatement(
                 "SELECT COUNT(*) FROM applications WHERE user_id = ? AND status IN ('NEW', 'UNDER_REVIEW', 'IN_PROGRESS', 'DRAFT')")) {
            limitPs.setInt(1, userId);
            try (ResultSet limitRs = limitPs.executeQuery()) {
                if (limitRs.next() && limitRs.getInt(1) >= 3) {
                    prepareCreateFormStateFromRequest(request, renewalSourceId, limitConn);
                    request.setAttribute("error", "Anda telah mencapai had maksimum 3 permohonan aktif (NEW/DRAFT). Sila tunggu sehingga permohonan sedia ada diselesaikan sebelum membuat permohonan baharu.");
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                    return;
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to check application limit: " + e.getMessage());
            prepareCreateFormStateFromRequest(request, renewalSourceId, null);
            request.setAttribute("error", "Ralat semasa memeriksa had permohonan. Sila cuba lagi.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureOnlineApplicationSchema(conn);
            conn.setAutoCommit(false);
            boolean committed = false;
            try {
                if (renewalSourceId != null && "PEMBAHARUAN".equalsIgnoreCase(applicationType)) {
                    Map<String, Object> renewalSource = loadRenewalSourceApplication(conn, renewalSourceId, userId);
                    if (renewalSource == null || renewalSource.isEmpty()) {
                        prepareCreateFormStateFromRequest(request, null, conn);
                        request.setAttribute("error", "Permohonan asal untuk pembaharuan tidak sah atau tidak ditemui.");
                        request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                        return;
                    }
                }
                int applicationId = insertApplication(conn, userId, request);
                insertApplicationDetails(conn, applicationId, request);
                if (renewalSourceId != null && "PEMBAHARUAN".equalsIgnoreCase(applicationType)) {
                    cloneSourceDocuments(conn, renewalSourceId, applicationId);
                }
                saveUploadedDocuments(conn, applicationId, request, false);
                insertAuditLog(conn, userId, request.getRemoteAddr(), applicationId);
                conn.commit();
                committed = true;
                response.sendRedirect(request.getContextPath() + "/applications/new?success=1&id=" + applicationId);
            } finally {
                if (!committed) {
                    try { conn.rollback(); } catch (SQLException rb) {
                        LOGGER.severe("Rollback failed: " + rb.getMessage());
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to save application: " + e.getMessage());
            prepareCreateFormStateFromRequest(request, renewalSourceId, null);
            request.setAttribute("error", "Permohonan tidak berjaya disimpan. Sila cuba lagi.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        } catch (IOException | ServletException e) {
            LOGGER.severe("IO/Servlet error saving application: " + e.getMessage());
            prepareCreateFormStateFromRequest(request, renewalSourceId, null);
            request.setAttribute("error", "Ralat sistem semasa menghantar permohonan. Sila cuba lagi.");
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
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

    private int insertApplication(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        String sql = "INSERT INTO applications (user_id, product_name, product_category, product_description, company_name, company_address, contact_number, email, status, submitted_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'NEW', ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, userId);
            stmt.setString(2, getPrimaryParam(request, "product_name"));
            stmt.setString(3, getPrimaryParam(request, "product_category"));
            stmt.setString(4, buildApplicationSummary(request));
            stmt.setString(5, trim(request.getParameter("supplier_name")));
            stmt.setString(6, trim(request.getParameter("supplier_address")));
            stmt.setString(7, trim(request.getParameter("supplier_phone")));
            stmt.setString(8, trim(request.getParameter("supplier_email")));
            stmt.setTimestamp(9, Timestamp.valueOf(LocalDateTime.now()));
            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }

        throw new SQLException("Application ID not generated.");
    }

    private void insertApplicationDetails(Connection conn, int applicationId, HttpServletRequest request) throws SQLException {
        String sql = "INSERT INTO application_details (application_id, application_type, supplier_name, supplier_address, supplier_phone, manufacturer_name, manufacturer_address, manufacturer_phone, principal_name, principal_address, principal_phone, standard_name, certification_license, certification_valid_until, test_report_reference, test_report_date, warranty_years, sabah_rep_name, sabah_rep_address, sabah_rep_phone, declaration_name, declaration_position) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.setString(2, trim(request.getParameter("application_type")));
            stmt.setString(3, trim(request.getParameter("supplier_name")));
            stmt.setString(4, trim(request.getParameter("supplier_address")));
            stmt.setString(5, trim(request.getParameter("supplier_phone")));
            stmt.setString(6, trim(request.getParameter("manufacturer_name")));
            stmt.setString(7, trim(request.getParameter("manufacturer_address")));
            stmt.setString(8, trim(request.getParameter("manufacturer_phone")));
            stmt.setString(9, trim(request.getParameter("principal_name")));
            stmt.setString(10, trim(request.getParameter("principal_address")));
            stmt.setString(11, trim(request.getParameter("principal_phone")));
            stmt.setString(12, getPrimaryParam(request, "standard_name"));
            stmt.setString(13, getPrimaryParam(request, "certification_license"));
            stmt.setDate(14, parseDate(getPrimaryParam(request, "certification_valid_until")));
            stmt.setString(15, getPrimaryParam(request, "test_report_reference"));
            stmt.setDate(16, parseDate(getPrimaryParam(request, "test_report_date")));
            stmt.setBigDecimal(17, parseDecimal(getPrimaryParam(request, "warranty_years")));
            stmt.setString(18, trim(request.getParameter("sabah_rep_name")));
            stmt.setString(19, trim(request.getParameter("sabah_rep_address")));
            stmt.setString(20, trim(request.getParameter("sabah_rep_phone")));
            stmt.setString(21, trim(request.getParameter("declaration_name")));
            stmt.setString(22, trim(request.getParameter("declaration_position")));
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
            stmt.setString(1, trim(request.getParameter("application_type")));
            stmt.setString(2, trim(request.getParameter("supplier_name")));
            stmt.setString(3, trim(request.getParameter("supplier_address")));
            stmt.setString(4, trim(request.getParameter("supplier_phone")));
            stmt.setString(5, trim(request.getParameter("manufacturer_name")));
            stmt.setString(6, trim(request.getParameter("manufacturer_address")));
            stmt.setString(7, trim(request.getParameter("manufacturer_phone")));
            stmt.setString(8, trim(request.getParameter("principal_name")));
            stmt.setString(9, trim(request.getParameter("principal_address")));
            stmt.setString(10, trim(request.getParameter("principal_phone")));
            stmt.setString(11, getPrimaryParam(request, "standard_name"));
            stmt.setString(12, getPrimaryParam(request, "certification_license"));
            stmt.setDate(13, parseDate(getPrimaryParam(request, "certification_valid_until")));
            stmt.setString(14, getPrimaryParam(request, "test_report_reference"));
            stmt.setDate(15, parseDate(getPrimaryParam(request, "test_report_date")));
            stmt.setBigDecimal(16, parseDecimal(getPrimaryParam(request, "warranty_years")));
            stmt.setString(17, trim(request.getParameter("sabah_rep_name")));
            stmt.setString(18, trim(request.getParameter("sabah_rep_address")));
            stmt.setString(19, trim(request.getParameter("sabah_rep_phone")));
            stmt.setString(20, trim(request.getParameter("declaration_name")));
            stmt.setString(21, trim(request.getParameter("declaration_position")));
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
            stmt.setString(1, getPrimaryParam(request, "product_name"));
            stmt.setString(2, getPrimaryParam(request, "product_category"));
            stmt.setString(3, buildApplicationSummary(request));
            stmt.setString(4, trim(request.getParameter("supplier_name")));
            stmt.setString(5, trim(request.getParameter("supplier_address")));
            stmt.setString(6, trim(request.getParameter("supplier_phone")));
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
        String applicationType = trim(request.getParameter("application_type"));
        String supplierName = trim(request.getParameter("supplier_name"));
        String productName = getPrimaryParam(request, "product_name");
        String productCategory = getPrimaryParam(request, "product_category");

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

                try (PreparedStatement stmt = conn.prepareStatement(
                        "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)")) {
                    stmt.setInt(1, userId);
                    stmt.setString(2, "UPDATE_APPLICATION");
                    stmt.setString(3, "Pemohon mengemaskini permohonan. ID: " + applicationId + " (Status asal: " + currentStatus + ")");
                    stmt.setString(4, request.getRemoteAddr());
                    stmt.executeUpdate();
                }

                conn.commit();
                committed = true;
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

    private void prepareCreateFormStateFromRequest(HttpServletRequest request, Integer renewalSourceId, Connection conn) {
        request.setAttribute("application", buildApplicationFromRequest(request));
        request.setAttribute("requiredDocuments", buildRequiredDocuments());
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
        app.put("application_type", trim(request.getParameter("application_type")));
        app.put("supplier_name", trim(request.getParameter("supplier_name")));
        app.put("supplier_email", trim(request.getParameter("supplier_email")));
        app.put("supplier_phone", trim(request.getParameter("supplier_phone")));
        app.put("supplier_address", trim(request.getParameter("supplier_address")));
        app.put("manufacturer_name", trim(request.getParameter("manufacturer_name")));
        app.put("manufacturer_address", trim(request.getParameter("manufacturer_address")));
        app.put("manufacturer_phone", trim(request.getParameter("manufacturer_phone")));
        app.put("principal_name", trim(request.getParameter("principal_name")));
        app.put("principal_address", trim(request.getParameter("principal_address")));
        app.put("principal_phone", trim(request.getParameter("principal_phone")));
        app.put("product_name", getPrimaryParam(request, "product_name"));
        app.put("product_category", getPrimaryParam(request, "product_category"));
        app.put("brand", getPrimaryParam(request, "brand"));
        app.put("standard_name", getPrimaryParam(request, "standard_name"));
        app.put("certification_license", getPrimaryParam(request, "certification_license"));
        app.put("certification_valid_until", getPrimaryParam(request, "certification_valid_until"));
        app.put("test_report_reference", getPrimaryParam(request, "test_report_reference"));
        app.put("test_report_date", getPrimaryParam(request, "test_report_date"));
        app.put("warranty_years", getPrimaryParam(request, "warranty_years"));
        app.put("product_description", getPrimaryParam(request, "product_description"));
        app.put("product_class", getPrimaryParam(request, "product_class"));
        app.put("product_size", getPrimaryParam(request, "product_size"));
        app.put("sabah_rep_name", trim(request.getParameter("sabah_rep_name")));
        app.put("sabah_rep_address", trim(request.getParameter("sabah_rep_address")));
        app.put("sabah_rep_phone", trim(request.getParameter("sabah_rep_phone")));
        app.put("declaration_name", trim(request.getParameter("declaration_name")));
        app.put("declaration_position", trim(request.getParameter("declaration_position")));
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
                app.put("product_description", extractFieldFromSummary(productSummary, "Perihal Produk:"));
                app.put("product_class", extractFieldFromSummary(productSummary, "Class Produk:"));
                app.put("product_size", extractFieldFromSummary(productSummary, "Saiz Produk:"));
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
                        app.put("product_description", extractFieldFromSummary(productSummary, "Perihal Produk:"));
                        app.put("product_class", extractFieldFromSummary(productSummary, "Class Produk:"));
                        app.put("product_size", extractFieldFromSummary(productSummary, "Saiz Produk:"));
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
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, "CREATE_APPLICATION");
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
                    + "application_type ENUM('BAHARU','PEMBAHARUAN') NOT NULL,"
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
        }
    }

    private Map<String, String> buildRequiredDocuments() {
        Map<String, String> docs = new LinkedHashMap<>();
        docs.put("official_application_letter", "Surat permohonan rasmi kepada Pengarah JANS");
        docs.put("principal_appointment_letter", "Surat pelantikan pembekal dari prinsipal/pemilik produk");
        docs.put("renewal_certificate", "Salinan sijil/perakuan lama bagi pembaharuan");
        docs.put("certification_license_file", "Lesen persijilan produk (SIRIM/IKRAM/dll)");
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
        mandatoryDocs.add("sop_document");
        mandatoryDocs.add("performance_monitoring_program");

        if ("PEMBAHARUAN".equalsIgnoreCase(trim(applicationType))) {
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
        List<String> productNames = getParamList(request, "product_name");
        List<String> productCategories = getParamList(request, "product_category");
        List<String> brands = getParamList(request, "brand");
        List<String> standards = getParamList(request, "standard_name");
        List<String> certificationLicenses = getParamList(request, "certification_license");
        List<String> certificationValidUntil = getParamList(request, "certification_valid_until");
        List<String> testReportReferences = getParamList(request, "test_report_reference");
        List<String> testReportDates = getParamList(request, "test_report_date");
        List<String> warrantyYears = getParamList(request, "warranty_years");
        List<String> productDescriptions = getParamList(request, "product_description");
        List<String> productClasses = getParamList(request, "product_class");
        List<String> productSizes = getParamList(request, "product_size");

        int productCount = productNames.size();
        productCount = Math.max(productCount, productCategories.size());
        productCount = Math.max(productCount, brands.size());
        productCount = Math.max(productCount, standards.size());
        productCount = Math.max(productCount, certificationLicenses.size());
        productCount = Math.max(productCount, certificationValidUntil.size());
        productCount = Math.max(productCount, testReportReferences.size());
        productCount = Math.max(productCount, testReportDates.size());
        productCount = Math.max(productCount, warrantyYears.size());
        productCount = Math.max(productCount, productDescriptions.size());
        productCount = Math.max(productCount, productClasses.size());
        productCount = Math.max(productCount, productSizes.size());
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
            String description = getValueAt(productDescriptions, i);
                String productClass = getValueAt(productClasses, i);
                String productSize = getValueAt(productSizes, i);
            if (name.isEmpty() && category.isEmpty() && brand.isEmpty() && standard.isEmpty()
                    && certificationLicense.isEmpty() && certificationUntil.isEmpty()
                    && testReportReference.isEmpty() && testReportDate.isEmpty()
                    && warranty.isEmpty() && description.isEmpty()
                    && productClass.isEmpty() && productSize.isEmpty()) {
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
                    .append(" | Perihal Produk: ").append(description.isEmpty() ? "-" : description)
                    .append(" | Class Produk: ").append(productClass.isEmpty() ? "-" : productClass)
                    .append(" | Saiz Produk: ").append(productSize.isEmpty() ? "-" : productSize);
        }

        return "Jenis Permohonan: " + trim(request.getParameter("application_type"))
                + "\nSenarai Produk:\n" + (productLines.length() == 0 ? "-" : productLines);
    }

    private String extractSubmittedFileName(Part part) {
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return "document.pdf";
        }
        return Path.of(submitted).getFileName().toString();
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String getPrimaryParam(HttpServletRequest request, String baseName) {
        List<String> values = getParamList(request, baseName);
        if (!values.isEmpty()) {
            return values.get(0);
        }
        return "";
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

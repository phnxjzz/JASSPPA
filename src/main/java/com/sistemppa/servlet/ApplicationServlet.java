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
import java.util.logging.Logger;

@MultipartConfig(maxFileSize = 15 * 1024 * 1024, maxRequestSize = 120 * 1024 * 1024)
public class ApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ApplicationServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = requireUserSession(request, response);
        if (session == null) {
            return;
        }

        String pathInfo = request.getPathInfo(); // e.g. "/new" or "/6"
        if (pathInfo == null || "/new".equals(pathInfo)) {
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
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
        String applicationType = trim(request.getParameter("application_type"));
        String supplierName = trim(request.getParameter("supplier_name"));
        String productName = trim(request.getParameter("product_name"));
        String productCategory = trim(request.getParameter("product_category"));

        if (supplierName.isEmpty() || productName.isEmpty() || productCategory.isEmpty() || applicationType.isEmpty()) {
            request.setAttribute("error", "Sila lengkapkan bahagian wajib borang PPP1.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        List<String> missingMandatoryDocs = findMissingMandatoryDocuments(request, applicationType);
        if (!missingMandatoryDocs.isEmpty()) {
            request.setAttribute("error", "Tidak Berjaya Sila Lengkapkan Dokumen yang diperlukan!");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.setAttribute("missingMandatoryDocuments", missingMandatoryDocs);
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        // Check active application limit (max 3 PENDING or DRAFT)
        try (Connection limitConn = DatabaseConfig.getConnection();
             PreparedStatement limitPs = limitConn.prepareStatement(
                 "SELECT COUNT(*) FROM applications WHERE user_id = ? AND status IN ('PENDING', 'DRAFT')")) {
            limitPs.setInt(1, userId);
            try (ResultSet limitRs = limitPs.executeQuery()) {
                if (limitRs.next() && limitRs.getInt(1) >= 3) {
                    request.setAttribute("error", "Anda telah mencapai had maksimum 3 permohonan aktif (PENDING/DRAFT). Sila tunggu sehingga permohonan sedia ada diselesaikan sebelum membuat permohonan baharu.");
                    request.setAttribute("requiredDocuments", buildRequiredDocuments());
                    request.getRequestDispatcher("/application-form.jsp").forward(request, response);
                    return;
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to check application limit: " + e.getMessage());
            request.setAttribute("error", "Ralat semasa memeriksa had permohonan. Sila cuba lagi.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureOnlineApplicationSchema(conn);
            conn.setAutoCommit(false);
            boolean committed = false;
            try {
                int applicationId = insertApplication(conn, userId, request);
                insertApplicationDetails(conn, applicationId, request);
                saveUploadedDocuments(conn, applicationId, request);
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
            request.setAttribute("error", "Permohonan tidak berjaya disimpan. Sila cuba lagi.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        } catch (IOException | ServletException e) {
            LOGGER.severe("IO/Servlet error saving application: " + e.getMessage());
            request.setAttribute("error", "Ralat sistem semasa menghantar permohonan. Sila cuba lagi.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
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
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, userId);
            stmt.setString(2, trim(request.getParameter("product_name")));
            stmt.setString(3, trim(request.getParameter("product_category")));
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
            stmt.setString(12, trim(request.getParameter("standard_name")));
            stmt.setString(13, trim(request.getParameter("certification_license")));
            stmt.setDate(14, parseDate(request.getParameter("certification_valid_until")));
            stmt.setString(15, trim(request.getParameter("test_report_reference")));
            stmt.setDate(16, parseDate(request.getParameter("test_report_date")));
            stmt.setBigDecimal(17, parseDecimal(request.getParameter("warranty_years")));
            stmt.setString(18, trim(request.getParameter("sabah_rep_name")));
            stmt.setString(19, trim(request.getParameter("sabah_rep_address")));
            stmt.setString(20, trim(request.getParameter("sabah_rep_phone")));
            stmt.setString(21, trim(request.getParameter("declaration_name")));
            stmt.setString(22, trim(request.getParameter("declaration_position")));
            stmt.executeUpdate();
        }
    }

    private void saveUploadedDocuments(Connection conn, int applicationId, HttpServletRequest request) throws SQLException, IOException, ServletException {
        Path baseDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")), "uploads", "sistemppa", String.valueOf(applicationId));
        Files.createDirectories(baseDir);

        String sql = "INSERT INTO application_documents (application_id, document_type, original_filename, stored_filename, stored_path, content_type, file_size) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (Map.Entry<String, String> entry : buildRequiredDocuments().entrySet()) {
                Part part = request.getPart(entry.getKey());
                if (part == null || part.getSize() == 0) {
                    continue;
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

    private List<String> findMissingMandatoryDocuments(HttpServletRequest request, String applicationType)
            throws IOException, ServletException {
        Map<String, String> allDocs = buildRequiredDocuments();
        Set<String> mandatoryDocKeys = buildMandatoryDocuments(applicationType);
        List<String> missing = new ArrayList<>();

        for (String docKey : mandatoryDocKeys) {
            Part part = request.getPart(docKey);
            if (part == null || part.getSize() == 0) {
                missing.add(allDocs.getOrDefault(docKey, docKey));
            }
        }

        if (missing.isEmpty()) {
            return Collections.emptyList();
        }
        return missing;
    }

    private String buildApplicationSummary(HttpServletRequest request) {
        return "Jenis Permohonan: " + trim(request.getParameter("application_type"))
                + "\nJenama: " + trim(request.getParameter("brand"))
                + "\nStandard: " + trim(request.getParameter("standard_name"))
                + "\nNo. Lesen Persijilan: " + trim(request.getParameter("certification_license"))
                + "\nNo. Laporan Ujian: " + trim(request.getParameter("test_report_reference"))
                + "\nPerihal Produk: " + trim(request.getParameter("product_description"));
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

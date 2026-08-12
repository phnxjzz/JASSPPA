package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas CertificateServlet.
 * Dipanggil melalui URL:  /certificate (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Serves the printable Perakuan Pendaftaran (Registration Certificate) page.
 * Accessible by: ADMIN (any), USER (own applications only).
 */
public class CertificateServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(CertificateServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer sessionUserId = (Integer) session.getAttribute("user_id");
        String role = (String) session.getAttribute("role");
        boolean isAdmin = "ADMIN".equals(role);

        String idParam = request.getParameter("id");
        Integer applicationId = parseInteger(idParam);
        if (applicationId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureCertificateColumns(conn);
            ensureCertificateSnapshotTable(conn);
            syncCertificateSnapshot(conn, applicationId);
            Map<String, Object> app = loadCertificateData(conn, applicationId);
            if (app == null || app.isEmpty()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Perakuan tidak ditemui");
                return;
            }

            // Access control: only admin or the application owner
            int appUserId = ((Number) app.get("user_id")).intValue();
            if (!isAdmin && sessionUserId != appUserId) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses ditolak");
                return;
            }

            // Must be APPROVED with certificate_number
            if (!"APPROVED".equals(app.get("status")) || app.get("certificate_number") == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Perakuan belum dikeluarkan untuk permohonan ini");
                return;
            }

            List<Map<String, String>> products = parseCertificateProducts(app);
            app.put("certificate_products", products);
            app.putAll(buildCertificateHeaderFields(app, products));
            request.setAttribute("certApp", app);
            request.getRequestDispatcher("/certificate.jsp").forward(request, response);

        } catch (SQLException e) {
            LOGGER.severe("Failed to load certificate: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan perakuan");
        }
    }

    private Map<String, Object> loadCertificateData(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.user_id, "
            + "COALESCE(cs.product_name, a.product_name) AS product_name, "
            + "COALESCE(cs.product_category, a.product_category) AS product_category, "
            + "COALESCE(cs.product_description, a.product_description) AS product_description, "
            + "COALESCE(cs.company_name, a.company_name) AS company_name, "
            + "COALESCE(cs.company_address, a.company_address) AS company_address, "
            + "COALESCE(cs.contact_number, a.contact_number) AS contact_number, "
            + "COALESCE(cs.email, a.email) AS email, "
            + "a.status, "
            + "COALESCE(cs.certificate_number, a.certificate_number) AS certificate_number, "
            + "COALESCE(cs.issued_at, a.issued_at) AS issued_at, "
            + "COALESCE(cs.valid_until, a.valid_until) AS valid_until, "
            + "a.reviewed_at, "
                + "u.full_name AS applicant_name, u.email AS user_email, "
            + "COALESCE(cs.application_type, ad.application_type) AS application_type, "
            + "COALESCE(cs.supplier_name, ad.supplier_name) AS supplier_name, "
            + "COALESCE(cs.supplier_address, ad.supplier_address) AS supplier_address, "
            + "COALESCE(cs.manufacturer_name, ad.manufacturer_name) AS manufacturer_name, "
            + "COALESCE(cs.principal_name, ad.principal_name) AS principal_name, "
            + "COALESCE(cs.standard_name, ad.standard_name) AS standard_name, "
            + "COALESCE(cs.certification_license, ad.certification_license) AS certification_license "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN certificate_application_snapshots cs ON cs.application_id = a.id "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("user_id", rs.getInt("user_id"));
                row.put("product_name", rs.getString("product_name"));
                row.put("product_category", rs.getString("product_category"));
                row.put("company_name", rs.getString("company_name"));
                row.put("company_address", rs.getString("company_address"));
                row.put("contact_number", rs.getString("contact_number"));
                row.put("email", rs.getString("email"));
                row.put("status", rs.getString("status"));
                row.put("certificate_number", rs.getString("certificate_number"));
                row.put("issued_at", rs.getDate("issued_at"));
                row.put("valid_until", rs.getDate("valid_until"));
                row.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                row.put("applicant_name", rs.getString("applicant_name"));
                row.put("user_email", rs.getString("user_email"));
                row.put("application_type", rs.getString("application_type"));
                row.put("product_description", rs.getString("product_description"));
                row.put("supplier_name", rs.getString("supplier_name"));
                row.put("supplier_address", rs.getString("supplier_address"));
                row.put("manufacturer_name", rs.getString("manufacturer_name"));
                row.put("principal_name", rs.getString("principal_name"));
                row.put("standard_name", rs.getString("standard_name"));
                row.put("certification_license", rs.getString("certification_license"));
                return row;
            }
        }
    }

    private void ensureCertificateSnapshotTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS certificate_application_snapshots ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "application_id INT NOT NULL, "
                + "certificate_number VARCHAR(60), "
                + "issued_at DATE, "
                + "valid_until DATE, "
                + "product_name VARCHAR(255) NOT NULL, "
                + "product_category VARCHAR(100) NOT NULL, "
                + "product_description TEXT, "
                + "company_name VARCHAR(255), "
                + "company_address TEXT, "
                + "contact_number VARCHAR(20), "
                + "email VARCHAR(100), "
                + "application_type ENUM('BAHARU', 'PEMBAHARUAN') NULL, "
                + "supplier_name VARCHAR(255), "
                + "supplier_address TEXT, "
                + "supplier_phone VARCHAR(50), "
                + "manufacturer_name VARCHAR(255), "
                + "manufacturer_address TEXT, "
                + "manufacturer_phone VARCHAR(50), "
                + "principal_name VARCHAR(255), "
                + "principal_address TEXT, "
                + "principal_phone VARCHAR(50), "
                + "standard_name VARCHAR(255), "
                + "certification_license VARCHAR(255), "
                + "certification_valid_until DATE, "
                + "test_report_reference VARCHAR(255), "
                + "test_report_date DATE, "
                + "warranty_years DECIMAL(5,2), "
                + "sabah_rep_name VARCHAR(255), "
                + "sabah_rep_address TEXT, "
                + "sabah_rep_phone VARCHAR(50), "
                + "declaration_name VARCHAR(255), "
                + "declaration_position VARCHAR(255), "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
                + "UNIQUE KEY uniq_certificate_snapshot_application (application_id), "
                + "KEY idx_certificate_snapshot_number (certificate_number), "
                + "CONSTRAINT fk_certificate_snapshot_application "
                + "FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE"
                + ")";
        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate(sql);
        }
    }

    private void syncCertificateSnapshot(Connection conn, int applicationId) throws SQLException {
        String sql = "INSERT INTO certificate_application_snapshots ("
                + "application_id, certificate_number, issued_at, valid_until, "
                + "product_name, product_category, product_description, company_name, company_address, contact_number, email, "
                + "application_type, supplier_name, supplier_address, supplier_phone, "
                + "manufacturer_name, manufacturer_address, manufacturer_phone, "
                + "principal_name, principal_address, principal_phone, "
                + "standard_name, certification_license, certification_valid_until, "
                + "test_report_reference, test_report_date, warranty_years, "
                + "sabah_rep_name, sabah_rep_address, sabah_rep_phone, declaration_name, declaration_position"
                + ") "
                + "SELECT "
                + "a.id, a.certificate_number, a.issued_at, a.valid_until, "
                + "a.product_name, a.product_category, a.product_description, a.company_name, a.company_address, a.contact_number, a.email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, "
                + "ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, ad.declaration_name, ad.declaration_position "
                + "FROM applications a "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ? "
                + "ON DUPLICATE KEY UPDATE "
                + "certificate_number = VALUES(certificate_number), "
                + "issued_at = VALUES(issued_at), "
                + "valid_until = VALUES(valid_until), "
                + "product_name = VALUES(product_name), "
                + "product_category = VALUES(product_category), "
                + "product_description = VALUES(product_description), "
                + "company_name = VALUES(company_name), "
                + "company_address = VALUES(company_address), "
                + "contact_number = VALUES(contact_number), "
                + "email = VALUES(email), "
                + "application_type = VALUES(application_type), "
                + "supplier_name = VALUES(supplier_name), "
                + "supplier_address = VALUES(supplier_address), "
                + "supplier_phone = VALUES(supplier_phone), "
                + "manufacturer_name = VALUES(manufacturer_name), "
                + "manufacturer_address = VALUES(manufacturer_address), "
                + "manufacturer_phone = VALUES(manufacturer_phone), "
                + "principal_name = VALUES(principal_name), "
                + "principal_address = VALUES(principal_address), "
                + "principal_phone = VALUES(principal_phone), "
                + "standard_name = VALUES(standard_name), "
                + "certification_license = VALUES(certification_license), "
                + "certification_valid_until = VALUES(certification_valid_until), "
                + "test_report_reference = VALUES(test_report_reference), "
                + "test_report_date = VALUES(test_report_date), "
                + "warranty_years = VALUES(warranty_years), "
                + "sabah_rep_name = VALUES(sabah_rep_name), "
                + "sabah_rep_address = VALUES(sabah_rep_address), "
                + "sabah_rep_phone = VALUES(sabah_rep_phone), "
                + "declaration_name = VALUES(declaration_name), "
                + "declaration_position = VALUES(declaration_position), "
                + "updated_at = CURRENT_TIMESTAMP";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.executeUpdate();
        }
    }

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private List<Map<String, String>> parseCertificateProducts(Map<String, Object> app) {
        List<Map<String, String>> products = new ArrayList<>();
        String summary = stringValue(app.get("product_description"));
        if (!summary.isBlank()) {
            for (String payload : extractProductPayloads(summary)) {
                String[] parts = payload.split("\\s*\\|\\s*");
                Map<String, String> product = new HashMap<>();
                String perihalRaw = extractLabeledPart(parts, "Perihal Produk:");
                String classRaw = extractLabeledPart(parts, "Class Produk:");
                String sizeRaw = extractLabeledPart(parts, "Saiz Produk:");
                String modelRaw = firstNonBlank(extractLabeledPart(parts, "Model:"), extractLabeledPart(parts, "Model Produk:"));
                String seriesRaw = firstNonBlank(extractLabeledPart(parts, "Siri:"), extractLabeledPart(parts, "Siri Produk:"));
                Map<String, String> parsedPerihal = parsePerihalDetails(perihalRaw);
                product.put("name", normalizeProductValue(parts.length > 0 ? parts[0] : ""));
                product.put("model", !modelRaw.isBlank() ? modelRaw : parsedPerihal.get("model"));
                product.put("series", !seriesRaw.isBlank() ? seriesRaw : parsedPerihal.get("series"));
                product.put("description", composeOrderedDescription(parsedPerihal.get("description"), classRaw, sizeRaw));
                products.add(product);
            }
        }

        if (products.isEmpty()) {
                String fallbackPerihal = firstNonBlank(extractTokenValue(summary, "Perihal Produk:"), stringValue(app.get("product_description")));
                String fallbackClass = extractTokenValue(summary, "Class Produk:");
                String fallbackSize = extractTokenValue(summary, "Saiz Produk:");
            Map<String, String> parsedPerihal = parsePerihalDetails(fallbackPerihal);
            Map<String, String> product = new HashMap<>();
            product.put("name", stringValue(app.get("product_name")));
            product.put("model", parsedPerihal.get("model"));
            product.put("series", parsedPerihal.get("series"));
            product.put("description", composeOrderedDescription(parsedPerihal.get("description"), fallbackClass, fallbackSize));
            products.add(product);
        }
        return products;
    }

    private Map<String, Object> buildCertificateHeaderFields(Map<String, Object> app, List<Map<String, String>> products) {
        Map<String, Object> fields = new HashMap<>();
        String summary = stringValue(app.get("product_description"));

        String brand = extractTokenValue(summary, "Jenama:");
        String perihal = "";
        String classValue = extractTokenValue(summary, "Class Produk:");
        String sizeValue = extractTokenValue(summary, "Saiz Produk:");

        String model = "";
        String series = "";
        if (!products.isEmpty()) {
            Map<String, String> first = products.get(0);
            model = stringValue(first.get("model"));
            series = stringValue(first.get("series"));
        }

        List<String> classSizeModel = new ArrayList<>();
        if (!model.isBlank()) {
            classSizeModel.add("Model: " + model);
        }
        if (!series.isBlank()) {
            classSizeModel.add("Siri: " + series);
        }
        if (!classValue.isBlank()) {
            classSizeModel.add("Class: " + classValue);
        }
        if (!sizeValue.isBlank()) {
            classSizeModel.add("Saiz: " + sizeValue);
        }

        fields.put("certificate_class_size_model", String.join(" | ", classSizeModel));
        fields.put("certificate_brand", brand);
        fields.put("certificate_product_brief", perihal);
        return fields;
    }

    private List<String> extractProductPayloads(String summary) {
        List<String> payloads = new ArrayList<>();
        if (summary == null || summary.isBlank()) {
            return payloads;
        }
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(
                "(?is)Produk\\s+\\d+\\s*:\\s*(.*?)(?=\\n\\s*Produk\\s+\\d+\\s*:|$)");
        java.util.regex.Matcher matcher = pattern.matcher(summary.replace("\r", ""));
        while (matcher.find()) {
            String payload = normalizeProductValue(matcher.group(1));
            if (!payload.isBlank()) {
                payloads.add(payload);
            }
        }
        return payloads;
    }

    private String extractTokenValue(String summary, String label) {
        if (summary == null || summary.isBlank()) {
            return "";
        }
        String pattern = "(?is)" + java.util.regex.Pattern.quote(label) + "\\s*([^|\\r\\n]+)";
        java.util.regex.Matcher matcher = java.util.regex.Pattern.compile(pattern).matcher(summary);
        if (matcher.find()) {
            return normalizeProductValue(matcher.group(1));
        }
        return "";
    }

    private Map<String, String> parsePerihalDetails(String rawPerihal) {
        String perihal = normalizeProductValue(rawPerihal);
        Map<String, String> details = new HashMap<>();
        details.put("description", perihal);
        String model = extractDetailValue(perihal,
                "model", "model no", "model number", "no model", "mdl", "kod model");
        String series = extractDetailValue(perihal,
                "siri", "series", "serial", "no siri", "nombor siri", "s/n", "sn");

        // Handle short free-form inputs like "siri" or "model" without separators.
        if (model.isBlank() && perihal.matches("(?i)^model\\b.*")) {
            model = perihal;
        }
        if (series.isBlank() && perihal.matches("(?i)^(siri|series)\\b.*")) {
            series = perihal;
        }

        details.put("model", model);
        details.put("series", series);
        return details;
    }

    private String extractDetailValue(String text, String... keys) {
        if (text == null || text.isBlank()) {
            return "";
        }
        for (String key : keys) {
            String escaped = java.util.regex.Pattern.quote(key);

            // Labeled style: Model: ABC-12 / Siri=XY9
            String labeledPattern = "(?i)(?:^|[\\s,;|/()\\[\\]-])" + escaped
                    + "\\s*[:=\\-]\\s*([^,;|/\\n\\r]+)";
            java.util.regex.Matcher labeledMatcher = java.util.regex.Pattern.compile(labeledPattern).matcher(text);
            if (labeledMatcher.find()) {
                return normalizeProductValue(labeledMatcher.group(1));
            }

            // Free style: Model ABC-12 / Siri XY9
            String freePattern = "(?i)(?:^|[\\s,;|/()\\[\\]-])" + escaped
                    + "\\s+([^,;|/\\n\\r]+)";
            java.util.regex.Matcher freeMatcher = java.util.regex.Pattern.compile(freePattern).matcher(text);
            if (freeMatcher.find()) {
                return normalizeProductValue(freeMatcher.group(1));
            }
        }
        return "";
    }

    private String extractLabeledPart(String[] parts, String label) {
        for (String part : parts) {
            if (part != null && part.startsWith(label)) {
                return normalizeProductValue(part.substring(label.length()).trim());
            }
        }
        return "";
    }

    private String extractFieldFromSummary(String summary, String label) {
        if (summary == null || summary.isBlank()) {
            return "";
        }
        for (String rawLine : summary.split("\\r?\\n")) {
            String line = rawLine == null ? "" : rawLine.trim();
            if (!line.startsWith("Produk ")) {
                continue;
            }
            int labelIdx = line.indexOf(label);
            if (labelIdx >= 0) {
                String value = normalizeProductValue(line.substring(labelIdx + label.length()).trim());
                int separatorIdx = value.indexOf("|");
                if (separatorIdx >= 0) {
                    value = normalizeProductValue(value.substring(0, separatorIdx).trim());
                }
                return value;
            }
        }
        return "";
    }

    private String composeOrderedDescription(String perihal, String classValue, String sizeValue) {
        List<String> segments = new ArrayList<>();
        String safePerihal = normalizeProductValue(perihal);
        String safeClass = normalizeProductValue(classValue);
        String safeSize = normalizeProductValue(sizeValue);

        if (!safePerihal.isBlank()) {
            segments.add("Perihal: " + safePerihal);
        }
        if (!safeClass.isBlank()) {
            segments.add("Class: " + safeClass);
        }
        if (!safeSize.isBlank()) {
            segments.add("Saiz: " + safeSize);
        }
        return String.join(" | ", segments);
    }

    private String firstNonBlank(String primary, String secondary) {
        return !primary.isBlank() ? primary : secondary;
    }

    private String normalizeProductValue(String value) {
        String cleaned = stringValue(value);
        return "-".equals(cleaned) ? "" : cleaned;
    }

    private String stringValue(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }
}


package com.sistemppa.servlet;

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

            app.put("certificate_products", parseCertificateProducts(app));
            request.setAttribute("certApp", app);
            request.getRequestDispatcher("/certificate.jsp").forward(request, response);

        } catch (SQLException e) {
            LOGGER.severe("Failed to load certificate: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan perakuan");
        }
    }

    private Map<String, Object> loadCertificateData(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.user_id, a.product_name, a.product_category, "
                + "a.product_description, a.company_name, "
                + "a.company_address, a.contact_number, a.email, a.status, "
                + "a.certificate_number, a.issued_at, a.valid_until, a.reviewed_at, "
                + "u.full_name AS applicant_name, u.email AS user_email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_address, "
                + "ad.manufacturer_name, ad.principal_name, "
                + "ad.standard_name, ad.certification_license "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
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
            String[] lines = summary.split("\\r?\\n");
            for (String rawLine : lines) {
                String line = rawLine == null ? "" : rawLine.trim();
                if (!line.startsWith("Produk ")) {
                    continue;
                }
                int colonIdx = line.indexOf(':');
                if (colonIdx < 0 || colonIdx + 1 >= line.length()) {
                    continue;
                }

                String payload = line.substring(colonIdx + 1).trim();
                String[] parts = payload.split("\\s*\\|\\s*");
                Map<String, String> product = new HashMap<>();
                String perihalRaw = extractLabeledPart(parts, "Perihal Produk:");
                String classRaw = extractLabeledPart(parts, "Class Produk:");
                String sizeRaw = extractLabeledPart(parts, "Saiz Produk:");
                Map<String, String> parsedPerihal = parsePerihalDetails(perihalRaw);
                product.put("name", normalizeProductValue(parts.length > 0 ? parts[0] : ""));
                product.put("model", parsedPerihal.get("model"));
                product.put("series", parsedPerihal.get("series"));
                product.put("description", composeOrderedDescription(parsedPerihal.get("description"), classRaw, sizeRaw));
                products.add(product);
            }
        }

        if (products.isEmpty()) {
            String fallbackPerihal = firstNonBlank(
                    extractFieldFromSummary(summary, "Perihal Produk:"),
                    stringValue(app.get("product_description")));
            String fallbackClass = extractFieldFromSummary(summary, "Class Produk:");
            String fallbackSize = extractFieldFromSummary(summary, "Saiz Produk:");
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

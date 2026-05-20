package com.sistemppa.servlet;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.awt.Color;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import javax.imageio.ImageIO;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Generates and streams a binary PDF Perakuan Pendaftaran (Registration Certificate).
 * URL: GET /certificate/pdf?id={applicationId}
 * Access: ADMIN (any approved), USER (own approved applications only).
 */
public class CertificatePdfServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(CertificatePdfServlet.class.getName());

    // Colours matching the reference layout
    private static final Color JANS_BLUE  = new Color(0x1b, 0x2a, 0x52);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ── authentication ────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        Integer sessionUserId = (Integer) session.getAttribute("user_id");
        String  role          = (String)  session.getAttribute("role");
        boolean isAdmin       = "ADMIN".equals(role);

        // ── validate id param ─────────────────────────────────────────
        String idParam = request.getParameter("id");
        int applicationId;
        try {
            applicationId = Integer.parseInt(idParam.trim());
        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureCertificateColumns(conn);
            Map<String, Object> app = loadCertData(conn, applicationId);

            if (app == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan tidak ditemui");
                return;
            }

            // ── access control ────────────────────────────────────────
            int appUserId = ((Number) app.get("user_id")).intValue();
            if (!isAdmin && !sessionUserId.equals(appUserId)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses ditolak");
                return;
            }

            if (!"APPROVED".equals(app.get("status")) || app.get("certificate_number") == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                        "Perakuan belum dikeluarkan untuk permohonan ini");
                return;
            }

            // ── stream PDF ────────────────────────────────────────────
            String certNum   = str(app.get("certificate_number"));
            String safeNum   = certNum.replace("/", "-");
            String fileName  = "Perakuan_JANS_" + safeNum + ".pdf";

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"" + fileName + "\"");
            response.setHeader("Cache-Control", "no-cache");

            try (OutputStream out = response.getOutputStream()) {
                generatePdf(app, out);
            }

        } catch (SQLException e) {
            LOGGER.severe("DB error generating certificate PDF: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Ralat pangkalan data – gagal menjana sijil");
        } catch (DocumentException e) {
            LOGGER.severe("OpenPDF error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Ralat PDF – gagal menjana sijil");
        }
    }

    // ── PDF generation ────────────────────────────────────────────────────────

    private void generatePdf(Map<String, Object> app, OutputStream out)
            throws DocumentException, IOException {

        // Avoid filesystem temp-cache dependency when decoding PNG in server runtime.
        ImageIO.setUseCache(false);

        // ── extract data ─────────────────────────────────────────────
        String certNum     = str(app.get("certificate_number"));
        String supplierNm  = str(app.get("supplier_name"));
        String mfrNm       = str(app.get("manufacturer_name"));
        String principalNm = str(app.get("principal_name"));
        String productNm   = str(app.get("product_name"));
        String category    = str(app.get("product_category"));
        String stdName     = str(app.get("standard_name"));
        String prodDesc    = str(app.get("product_description"));
        List<Map<String, String>> productRows = parseCertificateProducts(app);

        java.sql.Date issuedSql = (java.sql.Date) app.get("issued_at");
        java.sql.Date validSql  = (java.sql.Date) app.get("valid_until");
        LocalDate issued     = issuedSql != null ? issuedSql.toLocalDate()  : LocalDate.now();
        LocalDate validUntil = validSql  != null ? validSql.toLocalDate()   : LocalDate.now().plusYears(2);

        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd MMMM yyyy",
                new Locale("ms", "MY"));
        String issuedStr = issued.format(fmt);
        String validStr  = validUntil.format(fmt);

        // ── document ──────────────────────────────────────────────────
        // Left margin slightly wider to give field labels room
        Document doc = new Document(PageSize.A4, 50, 45, 45, 40);
        PdfWriter writer = PdfWriter.getInstance(doc, out);
        doc.open();

        float pw = doc.getPageSize().getWidth();    // 595.28
        float ph = doc.getPageSize().getHeight();   // 841.89

        // ── double border ─────────────────────────────────────────────
        PdfContentByte cb = writer.getDirectContent();
        // outer – 2.5pt navy
        cb.setLineWidth(2.5f);
        cb.setColorStroke(JANS_BLUE);
        cb.rectangle(18, 18, pw - 36, ph - 36);
        cb.stroke();
        // inner – 1pt navy, 7pt inset
        cb.setLineWidth(1f);
        cb.rectangle(26, 26, pw - 52, ph - 52);
        cb.stroke();

        // ── watermark: circular JABATAN AIR SABAH badge ───────────────
        String logoPath = resolveLogoPath();
        if (logoPath != null) {
            PdfContentByte cbUnder = writer.getDirectContentUnder();
            PdfGState gs = new PdfGState();
            gs.setFillOpacity(0.10f);
            gs.setStrokeOpacity(0.10f);
            cbUnder.setGState(gs);
            try {
                Image wm = Image.getInstance(logoPath);
                wm.scaleToFit(310, 310);
                float wmW = wm.getScaledWidth();
                float wmH = wm.getScaledHeight();
                wm.setAbsolutePosition((pw - wmW) / 2f, (ph - wmH) / 2f - 30);
                cbUnder.addImage(wm);
            } catch (Exception e) {
                LOGGER.warning("Could not add watermark: " + e.getMessage());
            }
        }

        // ── fonts ─────────────────────────────────────────────────────
        BaseFont bfBold = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.WINANSI, false);
        BaseFont bfReg  = BaseFont.createFont(BaseFont.HELVETICA,      BaseFont.WINANSI, false);

        Font fOrgName  = new Font(bfBold, 14, Font.NORMAL, Color.BLACK);
        Font fSubTitle = new Font(bfReg,  12, Font.NORMAL, Color.BLACK);
        Font fFieldLbl = new Font(bfBold, 10, Font.NORMAL, Color.BLACK);
        Font fFieldVal = new Font(bfReg,  10, Font.NORMAL, Color.BLACK);
        Font fTblHdr   = new Font(bfBold, 10, Font.NORMAL, Color.BLACK);
        Font fTblCell  = new Font(bfReg,  10, Font.NORMAL, Color.BLACK);

        // ── top logo ──────────────────────────────────────────────────
        if (logoPath != null) {
            try {
                Image logo = Image.getInstance(logoPath);
                logo.scaleToFit(85, 85);
                logo.setAlignment(Image.ALIGN_CENTER);
                logo.setSpacingAfter(6);
                doc.add(logo);
            } catch (Exception e) {
                LOGGER.warning("Could not add logo: " + e.getMessage());
            }
        }

        // ── header text ───────────────────────────────────────────────
        Paragraph orgPara = new Paragraph("JABATAN AIR SABAH", fOrgName);
        orgPara.setAlignment(Element.ALIGN_CENTER);
        orgPara.setSpacingBefore(4);
        orgPara.setSpacingAfter(4);
        doc.add(orgPara);

        Paragraph subPara = new Paragraph("Butiran Pendaftaran", fSubTitle);
        subPara.setAlignment(Element.ALIGN_CENTER);
        subPara.setSpacingAfter(14);
        doc.add(subPara);

        // ── fields ────────────────────────────────────────────────────
        // Exactly as shown in the reference image
        String[][] fields = {
            { "No Sijil",                 certNum     },
            { "Nama Pembekal",            supplierNm  },
            { "Nama Pengilang",           mfrNm       },
            { "Nama Prinsipal / Pemilik", principalNm },
            { "Nama Produk",              productNm   },
            { "Kategori",                 category    },
            { "Kelas/Saiz/Model",         ""          },
            { "Jenama",                   ""          },
            { "Piawaian",                 stdName     },
            { "Tarikh Dikeluarkan",       issuedStr   },
            { "Sah Sehingga",             validStr    },
            { "Perihal Produk",           prodDesc    },
        };

        // Column widths: label 32%, colon 4%, value 64%
        PdfPTable ftbl = new PdfPTable(new float[]{ 32, 4, 64 });
        ftbl.setWidthPercentage(88);
        ftbl.setSpacingBefore(2);
        ftbl.setSpacingAfter(14);
        ftbl.setHorizontalAlignment(Element.ALIGN_LEFT);

        for (String[] row : fields) {
            // label
            PdfPCell lc = new PdfPCell(new Phrase(row[0], fFieldLbl));
            lc.setBorder(Rectangle.NO_BORDER);
            lc.setPaddingTop(9);
            lc.setPaddingBottom(3);
            lc.setPaddingLeft(10);
            // colon
            PdfPCell cc = new PdfPCell(new Phrase(":", fFieldLbl));
            cc.setBorder(Rectangle.NO_BORDER);
            cc.setPaddingTop(9);
            cc.setPaddingBottom(3);
            // value with underline
            PdfPCell vc = new PdfPCell(new Phrase(row[1], fFieldVal));
            vc.setBorder(Rectangle.BOTTOM);
            vc.setBorderColorBottom(Color.BLACK);
            vc.setBorderWidthBottom(0.5f);
            vc.setPaddingTop(9);
            vc.setPaddingBottom(3);
            ftbl.addCell(lc);
            ftbl.addCell(cc);
            ftbl.addCell(vc);
        }
        doc.add(ftbl);

        // ── product table ─────────────────────────────────────────────
        PdfPTable ptbl = new PdfPTable(new float[]{ 28, 23, 17, 32 });
        ptbl.setWidthPercentage(88);
        ptbl.setSpacingBefore(0);

        // header row
        for (String h : new String[]{ "NAMA PRODUK", "MODEL", "SIRI", "PERIHAL/CLASS/SAIZ" }) {
            PdfPCell hc = new PdfPCell(new Phrase(h, fTblHdr));
            hc.setBorderColor(Color.BLACK);
            hc.setBorderWidth(0.8f);
            hc.setPaddingTop(8);
            hc.setPaddingBottom(8);
            hc.setHorizontalAlignment(Element.ALIGN_CENTER);
            ptbl.addCell(hc);
        }

        for (Map<String, String> productRow : productRows) {
            String[] rowValues = {
                str(productRow.get("name")),
                str(productRow.get("model")),
                str(productRow.get("series")),
                str(productRow.get("description"))
            };
            for (String cellText : rowValues) {
                PdfPCell dc = new PdfPCell(new Phrase(cellText, fTblCell));
                dc.setBorderColor(Color.BLACK);
                dc.setBorderWidth(0.8f);
                dc.setMinimumHeight(42);
                dc.setPaddingTop(6);
                dc.setPaddingLeft(4);
                ptbl.addCell(dc);
            }
        }
        doc.add(ptbl);

        doc.close();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /** Resolve the circular JABATAN AIR SABAH badge logo from webapp assets. */
    private String resolveLogoPath() {
        // prefer the circular badge; fall back to JANS 2025 logo if absent
        String[] candidates = {
            "/assets/images/logo-jabatan-air-sabah.png",
            "/assets/images/logo-jans-2025-main.png"
        };
        for (String path : candidates) {
            String real = getServletContext().getRealPath(path);
            if (real != null && new File(real).exists()) {
                return real;
            }
        }
        return null;
    }

    // ── DB query ──────────────────────────────────────────────────────────────

    private Map<String, Object> loadCertData(Connection conn, int applicationId)
            throws SQLException {
        String sql =
            "SELECT a.id, a.user_id, a.product_name, a.product_category, "
            + "a.product_description, a.company_name, a.company_address, "
            + "a.contact_number, a.email, a.status, "
            + "a.certificate_number, a.issued_at, a.valid_until, "
            + "u.full_name AS applicant_name, "
            + "ad.application_type, ad.supplier_name, "
            + "ad.manufacturer_name, ad.principal_name, "
            + "ad.standard_name "
            + "FROM applications a "
            + "JOIN users u ON u.id = a.user_id "
            + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "WHERE a.id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, applicationId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> row = new HashMap<>();
                row.put("id",                  rs.getInt("id"));
                row.put("user_id",             rs.getInt("user_id"));
                row.put("product_name",        rs.getString("product_name"));
                row.put("product_category",    rs.getString("product_category"));
                row.put("product_description", rs.getString("product_description"));
                row.put("company_name",        rs.getString("company_name"));
                row.put("company_address",     rs.getString("company_address"));
                row.put("email",               rs.getString("email"));
                row.put("status",              rs.getString("status"));
                row.put("certificate_number",  rs.getString("certificate_number"));
                row.put("issued_at",           rs.getDate("issued_at"));
                row.put("valid_until",         rs.getDate("valid_until"));
                row.put("applicant_name",      rs.getString("applicant_name"));
                row.put("application_type",    rs.getString("application_type"));
                row.put("supplier_name",       rs.getString("supplier_name"));
                row.put("manufacturer_name",   rs.getString("manufacturer_name"));
                row.put("principal_name",      rs.getString("principal_name"));
                row.put("standard_name",       rs.getString("standard_name"));
                return row;
            }
        }
    }

    private String str(Object o) {
        return (o != null && !o.toString().isBlank()) ? o.toString() : "";
    }

    private String fallback(Object primary, Object secondary) {
        if (primary != null && !primary.toString().isBlank()) return primary.toString();
        return secondary != null ? secondary.toString() : "";
    }

    private List<Map<String, String>> parseCertificateProducts(Map<String, Object> app) {
        List<Map<String, String>> products = new ArrayList<>();
        String summary = str(app.get("product_description"));
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
                Map<String, String> parsedPerihal = parsePerihalDetails(perihalRaw);
                product.put("name", normalizeProductValue(parts.length > 0 ? parts[0] : ""));
                product.put("model", parsedPerihal.get("model"));
                product.put("series", parsedPerihal.get("series"));
                product.put("description", parsedPerihal.get("description"));
                products.add(product);
            }
        }

        if (products.isEmpty()) {
            String fallbackPerihal = firstNonBlank(
                    extractDescriptionFromSummary(summary),
                    str(app.get("product_description")));
            Map<String, String> parsedPerihal = parsePerihalDetails(fallbackPerihal);
            Map<String, String> product = new HashMap<>();
            product.put("name", str(app.get("product_name")));
            product.put("model", parsedPerihal.get("model"));
            product.put("series", parsedPerihal.get("series"));
            product.put("description", parsedPerihal.get("description"));
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

    private String extractDescriptionFromSummary(String summary) {
        if (summary == null || summary.isBlank()) {
            return "";
        }
        for (String rawLine : summary.split("\\r?\\n")) {
            String line = rawLine == null ? "" : rawLine.trim();
            if (!line.startsWith("Produk ")) {
                continue;
            }
            int labelIdx = line.indexOf("Perihal Produk:");
            if (labelIdx >= 0) {
                return normalizeProductValue(line.substring(labelIdx + "Perihal Produk:".length()).trim());
            }
        }
        return "";
    }

    private String firstNonBlank(String primary, String secondary) {
        return !primary.isBlank() ? primary : secondary;
    }

    private String normalizeProductValue(String value) {
        String cleaned = str(value);
        return "-".equals(cleaned) ? "" : cleaned;
    }
}

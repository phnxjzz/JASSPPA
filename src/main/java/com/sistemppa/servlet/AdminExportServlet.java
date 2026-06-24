package com.sistemppa.servlet;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

public class AdminExportServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminExportServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String format = request.getParameter("format");
        String search = trim(request.getParameter("q"));
        String status = trim(request.getParameter("status"));
        String scope = trim(request.getParameter("scope"));
        boolean userScope = "users".equalsIgnoreCase(scope);
        boolean recentOnly = "1".equals(request.getParameter("recent"));

        if (format == null || (!"pdf".equalsIgnoreCase(format) && !"xlsx".equalsIgnoreCase(format))) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unsupported export format");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            if (userScope) {
                List<Map<String, Object>> users = DashboardDataService.loadRegisteredUsers(conn, search, recentOnly, 0);
                if ("pdf".equalsIgnoreCase(format)) {
                    exportUsersPdf(response, users, search, recentOnly);
                    return;
                }
                exportUsersExcel(response, users, recentOnly);
                return;
            }

            List<Map<String, Object>> applications = DashboardDataService.loadApplications(conn, search, status, null, null, 0);
            if ("pdf".equalsIgnoreCase(format)) {
                exportPdf(response, applications, search, status);
                return;
            }
            exportExcel(response, applications);
        } catch (SQLException | DocumentException e) {
            LOGGER.severe("Failed to export applications: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to export applications");
        }
    }

    private void exportPdf(HttpServletResponse response, List<Map<String, Object>> applications,
                           String search, String status) throws IOException, DocumentException {
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=laporan-permohonan-sppa.pdf");

        byte[] bytes = buildApplicationPdfBytes(applications, search, status);
        response.getOutputStream().write(bytes);
    }

    private byte[] buildApplicationPdfBytes(List<Map<String, Object>> applications,
                                            String search, String status) throws IOException, DocumentException {
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4.rotate(), 24, 24, 24, 24);
            PdfWriter.getInstance(document, output);
            document.open();
            document.add(new Paragraph("Laporan Permohonan SPPA",
                    FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            String filterText = "Carian: " + (isBlank(search) ? "Semua" : search)
                    + " | Status: " + (isBlank(status) ? "Semua" : status.toUpperCase());
            document.add(new Paragraph(filterText, FontFactory.getFont(FontFactory.HELVETICA, 10)));
            document.add(new Paragraph(" "));

            PdfPTable table = new PdfPTable(new float[]{1.2f, 3.2f, 2.2f, 2.2f, 1.5f, 2.2f});
            table.setWidthPercentage(100);
            addHeaderCell(table, "ID");
            addHeaderCell(table, "Syarikat / Pemohon");
            addHeaderCell(table, "Produk");
            addHeaderCell(table, "Kategori");
            addHeaderCell(table, "Status");
            addHeaderCell(table, "Dihantar");

            for (Map<String, Object> application : applications) {
                table.addCell(String.valueOf(application.get("id")));
                table.addCell(application.get("company_name") + "\n" + application.get("full_name"));
                table.addCell(String.valueOf(application.get("product_name")));
                table.addCell(String.valueOf(application.get("product_category")));
                table.addCell(String.valueOf(application.get("status")));
                table.addCell(application.get("submitted_at") == null ? "-" : String.valueOf(application.get("submitted_at")));
            }
            document.add(table);
            document.close();
            return output.toByteArray();
        }
    }

    private void exportExcel(HttpServletResponse response, List<Map<String, Object>> applications) throws IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename=laporan-permohonan-sppa.xlsx");

        byte[] bytes = buildApplicationExcelBytes(applications);
        response.getOutputStream().write(bytes);
    }

    private byte[] buildApplicationExcelBytes(List<Map<String, Object>> applications) throws IOException {
        try (ByteArrayOutputStream output = new ByteArrayOutputStream();
             XSSFWorkbook workbook = new XSSFWorkbook()) {
            XSSFSheet sheet = workbook.createSheet("Permohonan SPPA");
            String[] headers = {"ID", "Nama Syarikat", "Pemohon", "Email", "Nama Produk", "Kategori", "Status", "Tarikh Hantar"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
            }

            int rowIndex = 1;
            for (Map<String, Object> application : applications) {
                Row row = sheet.createRow(rowIndex++);
                row.createCell(0).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("id")));
                row.createCell(1).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("company_name")));
                row.createCell(2).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("full_name")));
                row.createCell(3).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("user_email")));
                row.createCell(4).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("product_name")));
                row.createCell(5).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("product_category")));
                row.createCell(6).setCellValue(ValidationUtil.sanitizeXlsxCell(application.get("status")));
                row.createCell(7).setCellValue(application.get("submitted_at") == null
                        ? "-" : String.valueOf(application.get("submitted_at")));
            }

            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            workbook.write(output);
            return output.toByteArray();
        }
    }

    private void exportUsersPdf(HttpServletResponse response, List<Map<String, Object>> users,
                                String search, boolean recentOnly) throws IOException, DocumentException {
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", recentOnly
                ? "attachment; filename=senarai-pemohon-baharu-sppa.pdf"
                : "attachment; filename=senarai-pemohon-berdaftar-sppa.pdf");

        Document document = new Document(PageSize.A4.rotate(), 24, 24, 24, 24);
        PdfWriter.getInstance(document, response.getOutputStream());
        document.open();
        document.add(new Paragraph(recentOnly
                        ? "Senarai Pemohon Baharu (30 Hari)"
                        : "Senarai Pemohon Berdaftar SPPA",
                FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
        document.add(new Paragraph("Carian: " + (isBlank(search) ? "Semua" : search),
                FontFactory.getFont(FontFactory.HELVETICA, 10)));
        document.add(new Paragraph(" "));

        PdfPTable table = new PdfPTable(new float[]{1.0f, 2.0f, 2.2f, 2.8f, 1.2f, 2.0f});
        table.setWidthPercentage(100);
        addHeaderCell(table, "ID");
        addHeaderCell(table, "Nama Pengguna");
        addHeaderCell(table, "Nama Penuh");
        addHeaderCell(table, "Email");
        addHeaderCell(table, "Status");
        addHeaderCell(table, "Tarikh Daftar");

        for (Map<String, Object> user : users) {
            table.addCell(String.valueOf(user.get("display_id")));
            table.addCell(String.valueOf(user.get("username")));
            table.addCell(String.valueOf(user.get("full_name")));
            table.addCell(String.valueOf(user.get("email")));
            table.addCell(String.valueOf(user.get("status")));
            table.addCell(user.get("created_at") == null ? "-" : String.valueOf(user.get("created_at")));
        }

        document.add(table);
        document.close();
    }

    private void exportUsersExcel(HttpServletResponse response, List<Map<String, Object>> users,
                                  boolean recentOnly) throws IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", recentOnly
                ? "attachment; filename=senarai-pemohon-baharu-sppa.xlsx"
                : "attachment; filename=senarai-pemohon-berdaftar-sppa.xlsx");

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            XSSFSheet sheet = workbook.createSheet(recentOnly ? "Pemohon Baharu" : "Pemohon Berdaftar");
            String[] headers = {"ID", "Nama Pengguna", "Nama Penuh", "Email", "Status", "Tarikh Daftar"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
            }

            int rowIndex = 1;
            for (Map<String, Object> user : users) {
                Row row = sheet.createRow(rowIndex++);
                row.createCell(0).setCellValue(ValidationUtil.sanitizeXlsxCell(user.get("display_id")));
                row.createCell(1).setCellValue(ValidationUtil.sanitizeXlsxCell(user.get("username")));
                row.createCell(2).setCellValue(ValidationUtil.sanitizeXlsxCell(user.get("full_name")));
                row.createCell(3).setCellValue(ValidationUtil.sanitizeXlsxCell(user.get("email")));
                row.createCell(4).setCellValue(ValidationUtil.sanitizeXlsxCell(user.get("status")));
                row.createCell(5).setCellValue(user.get("created_at") == null ? "-" : String.valueOf(user.get("created_at")));
            }

            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            workbook.write(response.getOutputStream());
        }
    }

    private void addHeaderCell(PdfPTable table, String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10)));
        table.addCell(cell);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}

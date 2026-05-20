package com.sistemppa.servlet;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.OutputStream;
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
 * Downloadable KSPP survey form template for renewal applications.
 * URL: GET /renewal-form/pdf?id={applicationId}
 */
public class RenewalSurveyPdfServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(RenewalSurveyPdfServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String role = (String) session.getAttribute("role");
        boolean isPrivileged = "ADMIN".equalsIgnoreCase(role) || "KPP".equalsIgnoreCase(role);

        if (!isPrivileged) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses borang ini hanya untuk Admin/KPP");
            return;
        }

        Integer applicationId = parseInteger(request.getParameter("id"));
        if (applicationId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            Map<String, Object> app = loadApplication(conn, applicationId);
            if (app == null || app.isEmpty()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan tidak ditemui");
                return;
            }

            String appType = str(app.get("application_type"));
            if (!"PEMBAHARUAN".equalsIgnoreCase(appType)) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                        "Borang KSPP hanya untuk permohonan pembaharuan");
                return;
            }

            String fileName = "Borang_KSPP_Pembaharuan_APP" + applicationId + ".pdf";
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            response.setHeader("Cache-Control", "no-cache");

            try (OutputStream out = response.getOutputStream()) {
                generatePdf(out);
            }

        } catch (SQLException e) {
            LOGGER.severe("Failed to load renewal application data: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Ralat pangkalan data - gagal menjana borang KSPP");
        } catch (DocumentException e) {
            LOGGER.severe("PDF generation error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Ralat PDF - gagal menjana borang KSPP");
        }
    }

    private void generatePdf(OutputStream out) throws DocumentException, IOException {
        Document doc = new Document(PageSize.A4, 30, 30, 30, 30);
        PdfWriter.getInstance(doc, out);
        doc.open();

        BaseFont bfBold = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.WINANSI, false);
        BaseFont bfReg = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, false);

        Font title15 = new Font(bfBold, 15);
        Font title13 = new Font(bfBold, 13);
        Font section11 = new Font(bfBold, 11);
        Font text10 = new Font(bfReg, 10);
        Font text9 = new Font(bfReg, 9);
        Font head10 = new Font(bfBold, 10);

        addCentered(doc, "JABATAN AIR SABAH", title15, 0);
        addCentered(doc, "BORANG KAJI SELIDIK", title13, 0);
        addCentered(doc, "PRESTASI PEMBEKAL DAN PRODUK BEKALAN AIR", title13, 0);
        addCentered(doc, "(PEMBAHARUAN)", title13, 10);

        addSectionTitle(doc, "BAHAGIAN A : MAKLUMAT RESPONDEN", section11);
        drawTwoColTable(doc, text10, new RowDef[] {
                row("Nama Penuh", 35),
                row("Cawangan / Jabatan Air Daerah", 35),
                row("Jawatan Hakiki & Gred", 35),
                row("Gelaran Jawatan", 35),
                row("Nombor Telefon", 35),
                row("Emel Rasmi Kerajaan", 35),
                row("Tempoh berkhidmat", 35)
        }, 180f, 330f);

        addSectionTitle(doc, "BAHAGIAN B : MAKLUMAT PRODUK", section11);
        drawTwoColTable(doc, text10, new RowDef[] {
                row("Nama Produk", 35),
                row("Jenama", 35),
                row("Perihal Produk\n(Model/Kelas/Saiz)", 60),
                row("Tarikh Mula & Siap", 35),
                row("% Siap", 35)
        }, 180f, 330f);

        addSectionTitle(doc, "BAHAGIAN C : MAKLUMAT PEMBEKAL DAN PRODUK", section11);
        drawTwoColTable(doc, text10, new RowDef[] {
                row("Nama Pembekal", 35),
                row("Nama Produk", 35),
                row("Jenama", 35),
                row("Perihal Produk\n(Model/Kelas/Saiz/dll)", 80)
        }, 180f, 330f);

        Paragraph note = new Paragraph();
        note.add(new Phrase("Nota : ", head10));
        note.add(new Phrase("Hanya Borang KSPP ini yang dicetak atas kertas A4 putih (depan & belakang) diterima.", text10));
        note.setSpacingBefore(8);
        note.setSpacingAfter(8);
        doc.add(note);

        doc.newPage();

        addSectionTitle(doc, "BAHAGIAN D : PRESTASI PEMBEKAL DAN PRODUK", section11);
        Paragraph noteD = new Paragraph("Nota : # Sila nyatakan (Ya / Tidak / Tidak Berkenaan)", text10);
        noteD.setSpacingAfter(6);
        doc.add(noteD);

        List<String> questions = buildQuestions();
        PdfPTable qTable = new PdfPTable(new float[] { 8f, 72f, 20f });
        qTable.setWidthPercentage(100);

        qTable.addCell(headerCell("NO", head10));
        qTable.addCell(headerCell("PERKARA", head10));
        qTable.addCell(headerCell("# CATATAN", head10));

        for (int i = 0; i < questions.size(); i++) {
            PdfPCell no = bodyCell(String.valueOf(i + 1), text9, Element.ALIGN_CENTER, 36f);
            PdfPCell perkara = bodyCell(questions.get(i), text9, Element.ALIGN_LEFT, 36f);
            PdfPCell catatan = bodyCell("", text9, Element.ALIGN_LEFT, 36f);
            qTable.addCell(no);
            qTable.addCell(perkara);
            qTable.addCell(catatan);
        }
        doc.add(qTable);

        addSectionTitle(doc,
                "BAHAGIAN E : ULASAN TERHADAP PEMBAHARUAN PERAKUAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR",
                section11);

        Paragraph p1 = new Paragraph(
                "Saya *bersetuju / tidak bersetuju terhadap kelulusan Perakuan Pembaharuan Pendaftaran Pembekal dan Produk tersebut. (Sila potong yang mana tidak berkenaan)",
                text10);
        p1.setSpacingAfter(10);
        doc.add(p1);

        doc.add(new Paragraph("Jika tidak bersetuju, sila beri ulasan.................................................................", text10));
        doc.add(new Paragraph("................................................................................................................", text10));

        Paragraph p2 = new Paragraph(
                "Saya dengan ini mengesahkan bahawa semua maklumat dan butiran yang dinyatakan dalam Borang Kaji Selidik Prestasi Pembekal dan Produk ini adalah tepat dan benar.",
                text10);
        p2.setSpacingBefore(12);
        p2.setSpacingAfter(30);
        doc.add(p2);

        doc.add(new Paragraph("Nama : ____________________________", text10));
        doc.add(new Paragraph("", text10));
        doc.add(new Paragraph("Tarikh : ___________________________", text10));
        doc.add(new Paragraph("", text10));
        doc.add(new Paragraph("Cop Jawatan : ______________________", text10));

        doc.close();
    }

    private Map<String, Object> loadApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.user_id, ad.application_type FROM applications a "
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
                row.put("application_type", rs.getString("application_type"));
                return row;
            }
        }
    }

    private void addCentered(Document doc, String text, Font font, float spacingAfter) throws DocumentException {
        Paragraph p = new Paragraph(text, font);
        p.setAlignment(Element.ALIGN_CENTER);
        p.setSpacingAfter(spacingAfter);
        doc.add(p);
    }

    private void addSectionTitle(Document doc, String text, Font font) throws DocumentException {
        Paragraph p = new Paragraph(text, font);
        p.setSpacingBefore(8);
        p.setSpacingAfter(6);
        doc.add(p);
    }

    private void drawTwoColTable(Document doc, Font textFont, RowDef[] rows, float left, float right)
            throws DocumentException {
        PdfPTable table = new PdfPTable(new float[] { left, right });
        table.setWidthPercentage(100);
        for (RowDef row : rows) {
            PdfPCell leftCell = bodyCell(row.label, textFont, Element.ALIGN_LEFT, row.height);
            leftCell.setPaddingLeft(6f);
            leftCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            PdfPCell rightCell = bodyCell("", textFont, Element.ALIGN_LEFT, row.height);
            table.addCell(leftCell);
            table.addCell(rightCell);
        }
        table.setSpacingAfter(10f);
        doc.add(table);
    }

    private PdfPCell headerCell(String text, Font font) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPaddingTop(8f);
        cell.setPaddingBottom(8f);
        cell.setBorder(Rectangle.BOX);
        return cell;
    }

    private PdfPCell bodyCell(String text, Font font, int align, float minHeight) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(align);
        cell.setVerticalAlignment(Element.ALIGN_TOP);
        cell.setMinimumHeight(minHeight);
        cell.setPaddingTop(6f);
        cell.setPaddingBottom(6f);
        cell.setBorder(Rectangle.BOX);
        return cell;
    }

    private static RowDef row(String label, float height) {
        return new RowDef(label, height);
    }

    private static final class RowDef {
        private final String label;
        private final float height;

        private RowDef(String label, float height) {
            this.label = label;
            this.height = height;
        }
    }

    private List<String> buildQuestions() {
        List<String> questions = new ArrayList<>();
        questions.add("Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?");
        questions.add("Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal / pemilik produk masih sah?");
        questions.add("Adakah dokumen jaminan produk masih sah?");
        questions.add("Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?");
        questions.add("Adakah mudah dihubungi pada bila-bila masa?");
        questions.add("Adakah jadual penghantaran produk ke lokasi dipatuhi?");
        questions.add("Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?");
        questions.add("Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?");
        questions.add("Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?");
        questions.add("Adakah amalan pelaksanaan kerja mengurangkan kesan / impak negatif terhadap alam sekitar dipatuhi?");
        questions.add("Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?");
        questions.add("Adakah pemasangan produk diselia / dipantau sehingga selesai?");
        questions.add("Adakah pengujian dan pentauliahan produk disaksikan sehingga selesai?");
        questions.add("Adakah produk yang rosak diganti ataupun dibaiki dengan segera?");
        questions.add("Adakah Manual Operasi diberikan?");
        questions.add("Adakah latihan operasi dan senggara produk diberikan?");
        questions.add("Adakah produk yang dibekalkan memenuhi spesifikasi yang diiktirafkan, berfungsi dengan baik dan tidak ada kecacatan?");
        questions.add("Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)");
        questions.add("Adakah produk mempunyai rekod prestasi yang tidak memuaskan / rosak dalam tempoh tanggungan kecacatan?");
        questions.add("Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan.");
        return questions;
    }

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}

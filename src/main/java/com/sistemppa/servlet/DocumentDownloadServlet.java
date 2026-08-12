package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DocumentDownloadServlet.
 * Dipanggil melalui URL:  /documents/download (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DocumentDownloadServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String documentId = request.getParameter("id");
        if (documentId == null || documentId.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Dokumen tidak sah");
            return;
        }
        boolean inlinePreview = "1".equals(request.getParameter("inline"))
            || "true".equalsIgnoreCase(request.getParameter("inline"));

        try (Connection conn = DatabaseConfig.getConnection()) {
            Integer userId = (Integer) session.getAttribute("user_id");
            String role = String.valueOf(session.getAttribute("role"));
            String sql = "SELECT d.original_filename, d.stored_path, d.content_type FROM application_documents d "
                    + "JOIN applications a ON a.id = d.application_id WHERE d.id = ? AND (? = 'ADMIN' OR a.user_id = ?)";

            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, Integer.parseInt(documentId));
                stmt.setString(2, role);
                stmt.setInt(3, userId);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Dokumen tidak dijumpai");
                        return;
                    }

                    Path path = Path.of(rs.getString("stored_path"));
                    if (!Files.exists(path)) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Fail dokumen tidak dijumpai");
                        return;
                    }

                        String contentType = rs.getString("content_type") != null
                            ? rs.getString("content_type")
                            : "application/octet-stream";
                        String originalFilename = rs.getString("original_filename") != null
                            ? rs.getString("original_filename")
                            : "dokumen";
                        String safeFilename = originalFilename
                            .replace("\"", "")
                            .replace("\r", "")
                            .replace("\n", "");
                        String disposition = inlinePreview ? "inline" : "attachment";

                        response.setContentType(contentType);
                        response.setHeader("Content-Disposition", disposition + "; filename=\"" + safeFilename + "\"");
                    Files.copy(path, response.getOutputStream());
                }
            }
        } catch (SQLException e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuat turun dokumen");
        }
    }
}


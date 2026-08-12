package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas UserProfileAssetServlet.
 * Dipanggil melalui mapping servlet dalam WEB-INF/web.xml.
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
import java.util.Locale;
import java.util.logging.Logger;

public class UserProfileAssetServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(UserProfileAssetServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer currentUserId = resolveUserId(session.getAttribute("user_id"));
        if (currentUserId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
            return;
        }

        String kind = normalizeKind(request.getParameter("kind"));
        Integer requestedUserId = parseInteger(request.getParameter("user_id"));
        String role = String.valueOf(session.getAttribute("role"));
        boolean canViewOtherUsers = "ADMIN".equals(role) || "DIRECTOR".equals(role);
        int targetUserId = requestedUserId != null && canViewOtherUsers ? requestedUserId : currentUserId;

        if (!canViewOtherUsers && targetUserId != currentUserId) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses tidak dibenarkan");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            AssetData assetData = loadAssetData(conn, targetUserId, kind);
            if (assetData == null || assetData.path == null || assetData.path.isBlank()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Fail tidak dijumpai");
                return;
            }

            if (assetData.path.startsWith("http://") || assetData.path.startsWith("https://")) {
                response.sendRedirect(assetData.path);
                return;
            }

            Path baseDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")), "uploads", "sistemppa");
            Path assetPath = Path.of(assetData.path).normalize();
            if (!Files.exists(assetPath)) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Fail tidak dijumpai");
                return;
            }

            try {
                Path realBase = baseDir.toRealPath();
                Path realAsset = assetPath.toRealPath();
                if (!realAsset.startsWith(realBase)) {
                    LOGGER.warning("Blocked profile asset traversal for user " + targetUserId + ": " + assetPath);
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses tidak dibenarkan");
                    return;
                }
            } catch (IOException e) {
                LOGGER.warning("Unable to resolve profile asset path for user " + targetUserId + ": " + e.getMessage());
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Fail tidak dijumpai");
                return;
            }

            String contentType = Files.probeContentType(assetPath);
            if (contentType == null || contentType.isBlank()) {
                contentType = assetData.kind.equals("document") ? "application/pdf" : "application/octet-stream";
            }
            response.setContentType(contentType);
            response.setHeader("Content-Disposition", "inline; filename=\"" + assetPath.getFileName() + "\"");
            response.setContentLengthLong(Files.size(assetPath));
            Files.copy(assetPath, response.getOutputStream());
        } catch (SQLException e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan fail profil");
        }
    }

    private AssetData loadAssetData(Connection conn, int userId, String kind) throws SQLException {
        String sql = "SELECT avatar_url, supporting_document_url FROM users WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                String path = "document".equals(kind)
                        ? rs.getString("supporting_document_url")
                        : rs.getString("avatar_url");
                return new AssetData(kind, path);
            }
        }
    }

    private Integer resolveUserId(Object value) {
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value == null) {
            return null;
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (NumberFormatException e) {
            return null;
        }
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

    private String normalizeKind(String kind) {
        if (kind == null) {
            return "avatar";
        }
        String normalized = kind.trim().toLowerCase(Locale.ROOT);
        return "document".equals(normalized) ? "document" : "avatar";
    }

    private static final class AssetData {
        private final String kind;
        private final String path;

        private AssetData(String kind, String path) {
            this.kind = kind;
            this.path = path;
        }
    }
}


package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DirectorAccessServlet.
 * Dipanggil melalui URL:  /director/access (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
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
import java.sql.Timestamp;
import java.util.logging.Logger;

public class DirectorAccessServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DirectorAccessServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String token = trim(request.getParameter("token"));
        LOGGER.info("[DirectorAccess] Raw token param: " + token);
        ApplicationServlet.DirectorAccessTokenPayload payload = ApplicationServlet.validateDirectorAccessToken(token, getServletContext());
        if (payload == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Pautan akses Pengarah tidak sah atau telah tamat tempoh.");
            return;
        }

        DirectorUser directorUser;
        try (Connection conn = DatabaseConfig.getConnection()) {
            directorUser = loadDirectorUser(conn, payload.userId());
        } catch (SQLException ex) {
            LOGGER.warning("Failed to validate director user from token: " + ex.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Tidak dapat mengesahkan akses Pengarah.");
            return;
        }

        if (directorUser == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akaun Pengarah tidak aktif atau tidak sepadan.");
            return;
        }

        HttpSession existing = request.getSession(false);
        if (existing != null) {
            existing.invalidate();
        }

        HttpSession session = request.getSession(true);
        session.setAttribute("user_id", directorUser.id());
        session.setAttribute("username", directorUser.username());
        session.setAttribute("email", directorUser.email());
        session.setAttribute("role", "DIRECTOR");
        session.setAttribute("portal_role", "DIRECTOR");
        session.setAttribute("login_time", new Timestamp(System.currentTimeMillis()));

        response.sendRedirect(request.getContextPath() + "/dashboard?director_open_application_id=" + payload.applicationId());
    }

    private DirectorUser loadDirectorUser(Connection conn, int userId) throws SQLException {
        String sql = "SELECT id, username, email FROM users "
                + "WHERE id = ? AND role = 'DIRECTOR' AND status = 'ACTIVE' LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new DirectorUser(
                        rs.getInt("id"),
                        trim(rs.getString("username")),
                        trim(rs.getString("email"))
                );
            }
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private record DirectorUser(int id, String username, String email) {}
}


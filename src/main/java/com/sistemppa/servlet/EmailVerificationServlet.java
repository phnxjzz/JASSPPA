package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas EmailVerificationServlet.
 * Dipanggil melalui URL:  /verify-email (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Map;
import java.util.logging.Logger;

public class EmailVerificationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(EmailVerificationServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String token = request.getParameter("token");
        if (token == null || token.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/login?verify_error=1");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            Map<String, Object> tokenData = DashboardDataService.findVerificationToken(conn, token);
            if (tokenData == null) {
                response.sendRedirect(request.getContextPath() + "/login?verify_error=2");
                return;
            }
            Timestamp expires = (Timestamp) tokenData.get("expires_at");
            if (expires != null && expires.before(new Timestamp(System.currentTimeMillis()))) {
                DashboardDataService.deleteVerificationToken(conn, token);
                response.sendRedirect(request.getContextPath() + "/login?verify_error=3");
                return;
            }
            int userId = ((Number) tokenData.get("user_id")).intValue();
            DashboardDataService.activateUser(conn, userId);
            DashboardDataService.deleteVerificationToken(conn, token);
            LOGGER.info("User " + userId + " email verified successfully.");
            response.sendRedirect(request.getContextPath() + "/login?verified=1");
        } catch (SQLException e) {
            LOGGER.severe("DB error during email verification: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/login?verify_error=1");
        }
    }
}


package com.sistemppa.servlet;

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

public class UserAvatarServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request,HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Integer userId = resolveUserId(session);
        if (userId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
            return;
        }

        try (Connection connection = DatabaseConfig.getConnection()) {
            String avatarValue = findAvatarValue(connection, userId);
            if (avatarValue == null || avatarValue.isBlank()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Avatar tidak dijumpai");
                return;
            }

            if (avatarValue.startsWith("http://") || avatarValue.startsWith("https://")) {
                response.sendRedirect(avatarValue);
                return;

            }

            Path avatarPath = Path.of(avatarValue);
            if (!Files.exists(avatarPath)) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Fail avatar tidak dijumpai");
                return;

            }

            String contentType = Files.probeContentType(avatarPath);
            response.setContentType(contentType != null ? contentType : "application/octet-stream");
            response.setHeader("Content-Disposition", "inline; filename=\"" + avatarPath.getFileName() +  "\"");
            response.setContentLengthLong(Files.size(avatarPath));
            Files.copy(avatarPath, response.getOutputStream());
        } catch (SQLException ex) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan avatar");
        }
    }

    private Integer resolveUserId(HttpSession session) {
        if (session == null) {
            return null;
        }

        Object primary = session.getAttribute("user_id");
        if (primary instanceof Integer) {
            return (Integer) primary;
        }
        if (primary != null) {
            try {
                return Integer.parseInt(String.valueOf(primary));
            } catch (NumberFormatException ignored) {
                // continue checking fallback key
            }
        }

        Object fallback = session.getAttribute("userId");
        if (fallback instanceof Integer) {
            return (Integer) fallback;
        }
        if (fallback != null) {
            try {
                return Integer.parseInt(String.valueOf(fallback));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }

        return null;
    }

    private String findAvatarValue(Connection conn , int userId) throws SQLException {
        String sql = "SELECT avatar_url FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String avatarUrl = rs.getString("avatar_url");
                    if (avatarUrl != null && !avatarUrl.isBlank()) {
                        return avatarUrl;
                    }
                    return null;
                }
            }
        }
        return null;
    }
}

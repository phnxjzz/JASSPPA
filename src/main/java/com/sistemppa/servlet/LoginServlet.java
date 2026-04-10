package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.logging.Logger;
import org.mindrot.jbcrypt.BCrypt;

public class LoginServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(LoginServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("user_id") != null) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
        } else {
            request.setAttribute("selected_role", normalizeRole(request.getParameter("role")));
            if (request.getParameter("registered") != null) {
                request.setAttribute("success", "Akaun berjaya didaftarkan. Sila log masuk.");
            } else if (request.getParameter("verify_pending") != null) {
                request.setAttribute("success", "Akaun berjaya didaftarkan. Sila semak e-mel anda untuk mengaktifkan akaun.");
            } else if (request.getParameter("verified") != null) {
                request.setAttribute("success", "E-mel berjaya disahkan! Sila log masuk.");
            } else if (request.getParameter("reset") != null) {
                request.setAttribute("success", "Kata laluan berjaya diset semula. Sila log masuk.");
            }
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = trim(request.getParameter("username"));
        String password = trim(request.getParameter("password"));
        String selectedRole = normalizeRole(request.getParameter("portal_role"));

        if (username.isEmpty() || password.isEmpty()) {
            request.setAttribute("error", "Username dan kata laluan diperlukan.");
            request.setAttribute("selected_role", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        if (selectedRole == null) {
            request.setAttribute("error", "Sila pilih peranan portal sebelum log masuk.");
            request.setAttribute("selected_role", "");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            String sql = "SELECT id, username, role, status, password_hash FROM users WHERE username = ? LIMIT 1";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, username);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        String storedPassword = rs.getString("password_hash");
                        if (!passwordMatches(password, storedPassword)) {
                            request.setAttribute("error", "Username atau kata laluan tidak sah.");
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        String status = rs.getString("status");
                        if (!"ACTIVE".equals(status)) {
                            String statusMsg = "SUSPENDED".equals(status)
                                ? "Akaun anda telah digantung. Sila hubungi pentadbir."
                                : "Akaun anda belum disahkan. Sila semak e-mel anda atau hubungi pentadbir.";
                            request.setAttribute("error", statusMsg);
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        String userRole = rs.getString("role");
                        if (!selectedRole.equals(userRole)) {
                            request.setAttribute("error", "Akaun ini tidak sepadan dengan portal yang dipilih.");
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        // Migrate plain-text or SHA-256 hashes to BCrypt on successful login
                        boolean alreadyBcrypt = storedPassword != null
                                && (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$"));
                        if (!alreadyBcrypt) {
                            migratePasswordHash(conn, rs.getInt("id"), password);
                        }

                        HttpSession session = request.getSession();
                        session.setAttribute("user_id", rs.getInt("id"));
                        session.setAttribute("username", rs.getString("username"));
                        session.setAttribute("role", userRole);
                        session.setAttribute("login_time", new Timestamp(System.currentTimeMillis()));

                        LOGGER.info("User logged in: " + username);
                        response.sendRedirect(request.getContextPath() + "/dashboard");
                    } else {
                        request.setAttribute("error", "Username atau kata laluan tidak sah.");
                        request.setAttribute("selected_role", selectedRole);
                        request.getRequestDispatcher("/login.jsp").forward(request, response);
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            request.setAttribute("error", "Ralat pangkalan data. Sila cuba lagi.");
            request.setAttribute("selected_role", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    private String normalizeRole(String value) {
        if (value == null) {
            return null;
        }
        String role = value.trim().toUpperCase();
        if ("ADMIN".equals(role) || "USER".equals(role)) {
            return role;
        }
        return null;
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private boolean passwordMatches(String inputPassword, String storedPassword) {
        if (storedPassword == null || storedPassword.isBlank()) {
            return false;
        }
        // BCrypt hash (starts with $2a$, $2b$, or $2y$)
        if (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$")) {
            // jBCrypt 0.4 only supports $2a$ prefix — normalize $2b$ and $2y$ before checking
            String normalizedHash = storedPassword.replaceFirst("^\\$2[by]\\$", "\\$2a\\$");
            try {
                return BCrypt.checkpw(inputPassword, normalizedHash);
            } catch (IllegalArgumentException e) {
                LOGGER.warning("BCrypt check failed (invalid hash format): " + e.getMessage());
                return false;
            }
        }
        // Legacy SHA-256 or plain-text fallback
        String hashedInput = sha256Hex(inputPassword);
        return storedPassword.equalsIgnoreCase(hashedInput) || storedPassword.equals(inputPassword);
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                String part = Integer.toHexString(0xff & b);
                if (part.length() == 1) {
                    hex.append('0');
                }
                hex.append(part);
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    }

    private void migratePasswordHash(Connection conn, int userId, String password) throws SQLException {
        String bcryptHash = BCrypt.hashpw(password, BCrypt.gensalt(12));
        String updateSql = "UPDATE users SET password_hash = ? WHERE id = ?";
        try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
            updateStmt.setString(1, bcryptHash);
            updateStmt.setInt(2, userId);
            updateStmt.executeUpdate();
            LOGGER.info("Migrated password to BCrypt for user_id: " + userId);
        }
    }
}

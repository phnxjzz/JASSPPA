package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas LoginServlet.
 * Dipanggil melalui URL:  /login (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.filter.RateLimitFilter;
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
        HttpSession session = request.getSession(false);
        String selectedRole = normalizeRole(request.getParameter("role"));
        if (selectedRole == null) {
            selectedRole = normalizeRole(request.getParameter("portal_role"));
        }

        if (session != null && session.getAttribute("user_id") != null) {
            if (selectedRole == null) {
                selectedRole = "";
            }

            String currentRole = trim((String) session.getAttribute("role")).toUpperCase(java.util.Locale.ROOT);
            String currentEmail = trim((String) session.getAttribute("email"));

            boolean canReuseCurrentSession = selectedRole.equals(currentRole)
                    || ("USER".equals(selectedRole) && "ADMIN".equals(currentRole))
                    || ("STAFF".equals(selectedRole)
                        && ("ADMIN".equals(currentRole) || "STAFF".equals(currentRole))
                        && isGovernmentEmail(currentEmail));

            if (canReuseCurrentSession) {
                session.setAttribute("portal_role", selectedRole);
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }
        }

        boolean maintenanceMode = Boolean.TRUE.equals(getServletContext().getAttribute("maintenanceMode"));
        request.setAttribute("selected_role", selectedRole);
        request.setAttribute("maintenance_mode", maintenanceMode);

        if (request.getParameter("portal_mismatch") != null) {
            request.setAttribute("error", "Sila log masuk semula melalui portal peranan yang betul.");
        }

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

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = trim(request.getParameter("username"));
        String password = trim(request.getParameter("password"));
        String selectedRole = normalizeRole(request.getParameter("portal_role"));
        boolean maintenanceMode = Boolean.TRUE.equals(getServletContext().getAttribute("maintenanceMode"));

        request.setAttribute("maintenance_mode", maintenanceMode);

        if (username.isEmpty() || password.isEmpty()) {
            request.setAttribute("error", "Username dan kata laluan diperlukan.");
            request.setAttribute("selected_role", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            String sql = "SELECT id, username, email, role, status, password_hash FROM users WHERE username = ? LIMIT 1";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, username);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        String storedPassword = rs.getString("password_hash");
                        if (!passwordMatches(password, storedPassword)) {
                            RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                            request.setAttribute("error", "Username atau kata laluan tidak sah.");
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        String status = rs.getString("status");
                        if (!"ACTIVE".equals(status)) {
                            RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                            String statusMsg = "SUSPENDED".equals(status)
                                ? "Akaun anda telah digantung. Sila hubungi pentadbir."
                                : "Akaun anda belum disahkan. Sila semak e-mel anda atau hubungi pentadbir.";
                            request.setAttribute("error", statusMsg);
                            request.setAttribute("selected_role", selectedRole);
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        String userRole = rs.getString("role");
                        String userEmail = trim(rs.getString("email"));
                        if (maintenanceMode && "USER".equals(userRole)) {
                            request.setAttribute("error", "Portal Pemohon sedang dalam penyelenggaraan. Sila cuba lagi sebentar.");
                            request.setAttribute("selected_role", selectedRole != null ? selectedRole : "USER");
                            request.getRequestDispatcher("/login.jsp").forward(request, response);
                            return;
                        }

                        if ("STAFF".equals(selectedRole)) {
                            boolean staffPortalRoleAllowed = "ADMIN".equals(userRole) || "STAFF".equals(userRole);
                            if (!staffPortalRoleAllowed) {
                                RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                                request.setAttribute("error", "Portal Staff hanya untuk akaun Admin atau Staff.");
                                request.setAttribute("selected_role", selectedRole);
                                request.getRequestDispatcher("/login.jsp").forward(request, response);
                                return;
                            }
                            if (!isGovernmentEmail(userEmail)) {
                                RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                                request.setAttribute("error", "Portal Staff memerlukan e-mel rasmi kerajaan (contoh: @sabah.gov.my). ");
                                request.setAttribute("selected_role", selectedRole);
                                request.getRequestDispatcher("/login.jsp").forward(request, response);
                                return;
                            }
                        } else if (selectedRole != null && !selectedRole.equals(userRole)) {
                            boolean userTryingAdminPortal = "ADMIN".equals(selectedRole) && "USER".equals(userRole);
                            boolean adminUsingApplicantPortal = "USER".equals(selectedRole) && "ADMIN".equals(userRole);

                            if (userTryingAdminPortal) {
                                RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                                request.setAttribute("portal_error", "Sila Pergi ke Portal Pemohon!");
                                request.setAttribute("selected_role", selectedRole);
                                request.getRequestDispatcher("/login.jsp").forward(request, response);
                                return;
                            }

                            if (!adminUsingApplicantPortal) {
                                RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
                                request.setAttribute("error", "Akaun ini tidak sepadan dengan portal yang dipilih.");
                                request.setAttribute("selected_role", selectedRole);
                                request.getRequestDispatcher("/login.jsp").forward(request, response);
                                return;
                            }
                        }

                        // Migrate plain-text or SHA-256 hashes to BCrypt on successful login
                        boolean alreadyBcrypt = storedPassword != null
                                && (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$"));
                        if (!alreadyBcrypt) {
                            migratePasswordHash(conn, rs.getInt("id"), password);
                        }

                        // Successful login: clear rate-limit record
                        RateLimitFilter.clearRecord(RateLimitFilter.resolveClientIp(request));

                        HttpSession session = request.getSession();
                        session.setAttribute("user_id", rs.getInt("id"));
                        session.setAttribute("username", rs.getString("username"));
                        session.setAttribute("email", userEmail);
                        session.setAttribute("role", userRole);
                        String effectivePortalRole = selectedRole != null && !selectedRole.isBlank()
                            ? selectedRole
                            : userRole;
                        session.setAttribute("portal_role", effectivePortalRole);
                        session.setAttribute("login_time", new Timestamp(System.currentTimeMillis()));

                        LOGGER.info("User logged in: " + username);
                        response.sendRedirect(request.getContextPath() + "/dashboard");
                    } else {
                        RateLimitFilter.recordFailure(RateLimitFilter.resolveClientIp(request));
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
        if ("ADMIN".equals(role) || "USER".equals(role) || "STAFF".equals(role)) {
            return role;
        }
        return null;
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private boolean isGovernmentEmail(String email) {
        if (email == null) {
            return false;
        }
        String normalizedEmail = email.trim().toLowerCase(java.util.Locale.ROOT);
        return normalizedEmail.endsWith(".gov.my");
    }

    private boolean passwordMatches(String inputPassword, String storedPassword) {
        if (storedPassword == null || storedPassword.isBlank()) {
            return false;
        }
        // BCrypt hash (starts with $2a$, $2b$, or $2y$)
        if (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$")) {
            // jBCrypt 0.4 only supports $2a$ prefix â€” normalize $2b$ and $2y$ before checking
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


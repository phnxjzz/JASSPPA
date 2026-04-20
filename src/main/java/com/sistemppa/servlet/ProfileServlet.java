package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import java.util.logging.Logger;
import org.mindrot.jbcrypt.BCrypt;
import com.sistemppa.util.ValidationUtil;

@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class ProfileServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ProfileServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            populateProfile(request, (Integer) session.getAttribute("user_id"), conn);
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load profile: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to load profile");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        int userId = (Integer) session.getAttribute("user_id");
        String fullName = trim(request.getParameter("full_name"));
        String username = trim(request.getParameter("username"));
        String email = trim(request.getParameter("email"));
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");

        request.setAttribute("full_name", fullName);
        request.setAttribute("username", username);
        request.setAttribute("email", email);

        try (Connection conn = DatabaseConfig.getConnection()) {
            String currentAvatar = loadCurrentAvatarValue(conn, userId);
            request.setAttribute("avatar_url", currentAvatar);

            if (isBlank(fullName) || isBlank(username) || isBlank(email)) {
                request.setAttribute("error", "Nama penuh, nama pengguna dan email wajib diisi.");
                request.getRequestDispatcher("/profile.jsp").forward(request, response);
                return;
            }

            if (!isBlank(password) && !password.equals(confirmPassword)) {
                request.setAttribute("error", "Pengesahan kata laluan tidak sepadan.");
                request.getRequestDispatcher("/profile.jsp").forward(request, response);
                return;
            }

            Part avatarFile = request.getPart("avatar_file");
            if (avatarFile != null && avatarFile.getSize() > 0) {
                // Validate with both declared MIME type AND magic bytes
                if (!isSupportedImage(avatarFile) || !ValidationUtil.isValidImageMagicBytes(avatarFile)) {
                    request.setAttribute("error", "Gambar profil mesti fail imej PNG, JPG, GIF atau WEBP yang sah.");
                    request.getRequestDispatcher("/profile.jsp").forward(request, response);
                    return;
                }
            }

            if (!isBlank(password)) {
                // Validate new password against unified policy before saving
                String policyError = ValidationUtil.validatePasswordPolicy(password);
                if (policyError != null) {
                    request.setAttribute("error", policyError);
                    request.getRequestDispatcher("/profile.jsp").forward(request, response);
                    return;
                }
            }

            if (existsDuplicateUser(conn, userId, username, email)) {
                request.setAttribute("error", "Nama pengguna atau email sudah digunakan.");
                request.getRequestDispatcher("/profile.jsp").forward(request, response);
                return;
            }

            String avatarValue = currentAvatar;
            if (avatarFile != null && avatarFile.getSize() > 0) {
                avatarValue = saveUploadedAvatar(avatarFile, userId, currentAvatar);
            }

            updateProfile(conn, userId, fullName, username, email, avatarValue, password);
            session.setAttribute("username", username);
            response.sendRedirect(request.getContextPath() + "/profile?updated=1");
        } catch (IllegalStateException e) {
            request.setAttribute("error", "Saiz gambar profil terlalu besar. Had maksimum ialah 5MB.");
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to update profile: " + e.getMessage());
            request.setAttribute("error", "Kemaskini profil gagal disimpan.");
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
        }
    }

    private void populateProfile(HttpServletRequest request, int userId, Connection conn) throws SQLException {
        String sql = "SELECT full_name, username, email, avatar_url, status, created_at "
                + "FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    request.setAttribute("full_name", rs.getString("full_name"));
                    request.setAttribute("username", rs.getString("username"));
                    request.setAttribute("email", rs.getString("email"));
                    request.setAttribute("avatar_url", rs.getString("avatar_url"));
                    request.setAttribute("status", rs.getString("status"));
                    request.setAttribute("created_at", rs.getTimestamp("created_at"));
                }
            }
        }
    }

    private boolean existsDuplicateUser(Connection conn, int userId, String username, String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE (username = ? OR email = ?) AND id <> ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, username);
            stmt.setString(2, email);
            stmt.setInt(3, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private String loadCurrentAvatarValue(Connection conn, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement("SELECT avatar_url FROM users WHERE id = ?")) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("avatar_url");
                }
                return null;
            }
        }
    }

    private String saveUploadedAvatar(Part avatarFile, int userId, String currentAvatar) throws IOException {
        String submittedName = extractSubmittedFileName(avatarFile);
        String safeName = UUID.randomUUID() + "-" + submittedName.replaceAll("[^a-zA-Z0-9._-]", "_");
        Path baseDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")), "uploads", "sistemppa", "avatars", String.valueOf(userId));
        Files.createDirectories(baseDir);

        Path storedFile = baseDir.resolve(safeName);
        try (var inputStream = avatarFile.getInputStream()) {
            Files.copy(inputStream, storedFile, StandardCopyOption.REPLACE_EXISTING);
        }

        if (!isBlank(currentAvatar) && !currentAvatar.startsWith("http://") && !currentAvatar.startsWith("https://")) {
            try {
                Files.deleteIfExists(Path.of(currentAvatar));
            } catch (IOException ignored) {
                LOGGER.warning("Unable to delete old avatar: " + ignored.getMessage());
            }
        }

        return storedFile.toString();
    }

    private boolean isSupportedImage(Part avatarFile) {
        String contentType = avatarFile.getContentType();
        if (contentType == null) {
            return false;
        }
        return contentType.equalsIgnoreCase("image/png")
                || contentType.equalsIgnoreCase("image/jpeg")
                || contentType.equalsIgnoreCase("image/gif")
                || contentType.equalsIgnoreCase("image/webp");
    }

    private String extractSubmittedFileName(Part part) {
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return "avatar.png";
        }
        return Path.of(submitted).getFileName().toString();
    }

    private void updateProfile(Connection conn, int userId, String fullName, String username, String email,
                               String avatarUrl, String password) throws SQLException {
        boolean hasPassword = !isBlank(password);
        if (hasPassword) {
            // Use BCrypt (NOT SHA2 in SQL) so the hash is consistent with login / registration
            String hashed = BCrypt.hashpw(password, BCrypt.gensalt(12));
            String sql = "UPDATE users SET full_name = ?, username = ?, email = ?, avatar_url = ?, password_hash = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, username);
                stmt.setString(3, email);
                stmt.setString(4, isBlank(avatarUrl) ? null : avatarUrl);
                stmt.setString(5, hashed);
                stmt.setInt(6, userId);
                stmt.executeUpdate();
            }
        } else {
            String sql = "UPDATE users SET full_name = ?, username = ?, email = ?, avatar_url = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, username);
                stmt.setString(3, email);
                stmt.setString(4, isBlank(avatarUrl) ? null : avatarUrl);
                stmt.setInt(5, userId);
                stmt.executeUpdate();
            }
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}

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
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import org.mindrot.jbcrypt.BCrypt;
import com.sistemppa.util.ValidationUtil;

@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class ProfileServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ProfileServlet.class.getName());
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{8,20}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);
            populateProfile(request, (Integer) session.getAttribute("user_id"), conn);
            loadApprovedCertificates(request, (Integer) session.getAttribute("user_id"), conn);
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
        String phoneNumber = trim(request.getParameter("phone_number"));
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");

        request.setAttribute("full_name", fullName);
        request.setAttribute("username", username);
        request.setAttribute("email", email);
        request.setAttribute("phone_number", phoneNumber);

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);
            String currentAvatar = loadCurrentAvatarValue(conn, userId);
            request.setAttribute("avatar_url", currentAvatar);

            if (isBlank(fullName) || isBlank(username) || isBlank(email) || isBlank(phoneNumber)) {
                request.setAttribute("error", "Nama penuh, nama pengguna, email dan nombor telefon wajib diisi.");
                request.getRequestDispatcher("/profile.jsp").forward(request, response);
                return;
            }

            if (!PHONE_PATTERN.matcher(phoneNumber).matches()) {
                request.setAttribute("error", "Nombor telefon tidak sah. Gunakan 8 hingga 20 aksara (nombor/simbol +()- sahaja).");
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

            updateProfile(conn, userId, fullName, username, email, phoneNumber, avatarValue, password);
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
        String sql = "SELECT full_name, username, email, phone_number, avatar_url, status, created_at "
                + "FROM users WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    request.setAttribute("full_name", rs.getString("full_name"));
                    request.setAttribute("username", rs.getString("username"));
                    request.setAttribute("email", rs.getString("email"));
                    request.setAttribute("phone_number", rs.getString("phone_number"));
                    request.setAttribute("avatar_url", rs.getString("avatar_url"));
                    request.setAttribute("status", rs.getString("status"));
                    request.setAttribute("created_at", rs.getTimestamp("created_at"));
                }
            }
        }
    }

    private void loadApprovedCertificates(HttpServletRequest request, int userId, Connection conn) throws SQLException {
        String sql = "SELECT a.id, a.product_name, a.company_name, a.certificate_number, a.issued_at, a.valid_until, "
                + "a.status, ad.application_type, ad.standard_name "
                + "FROM applications a "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
            + "WHERE a.user_id = ? AND a.status = 'APPROVED' "
                + "ORDER BY COALESCE(a.issued_at, a.created_at) DESC, a.id DESC";

        List<Map<String, Object>> certificates = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("company_name", rs.getString("company_name"));
                    row.put("certificate_number", rs.getString("certificate_number"));
                    row.put("issued_at", rs.getDate("issued_at"));
                    row.put("valid_until", rs.getDate("valid_until"));
                    row.put("application_type", rs.getString("application_type"));
                    row.put("standard_name", rs.getString("standard_name"));
                    certificates.add(row);
                }
            }
        }

        request.setAttribute("approved_certificates", certificates);
        request.setAttribute("approved_certificate_count", certificates.size());
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
                               String phoneNumber,
                               String avatarUrl, String password) throws SQLException {
        boolean hasPassword = !isBlank(password);
        if (hasPassword) {
            // Use BCrypt (NOT SHA2 in SQL) so the hash is consistent with login / registration
            String hashed = BCrypt.hashpw(password, BCrypt.gensalt(12));
            String sql = "UPDATE users SET full_name = ?, username = ?, email = ?, phone_number = ?, avatar_url = ?, password_hash = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, username);
                stmt.setString(3, email);
                stmt.setString(4, phoneNumber);
                stmt.setString(5, isBlank(avatarUrl) ? null : avatarUrl);
                stmt.setString(6, hashed);
                stmt.setInt(7, userId);
                stmt.executeUpdate();
            }
        } else {
            String sql = "UPDATE users SET full_name = ?, username = ?, email = ?, phone_number = ?, avatar_url = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, fullName);
                stmt.setString(2, username);
                stmt.setString(3, email);
                stmt.setString(4, phoneNumber);
                stmt.setString(5, isBlank(avatarUrl) ? null : avatarUrl);
                stmt.setInt(6, userId);
                stmt.executeUpdate();
            }
        }
    }

    private void ensureUsersPhoneNumberColumn(Connection conn) throws SQLException {
        DatabaseMetaData meta = conn.getMetaData();
        try (ResultSet rs = meta.getColumns(null, null, "users", "phone_number")) {
            if (rs.next()) {
                return;
            }
        }
        try (PreparedStatement stmt = conn.prepareStatement("ALTER TABLE users ADD COLUMN phone_number VARCHAR(30)")) {
            stmt.executeUpdate();
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}

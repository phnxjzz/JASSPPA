package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas RegisterServlet.
 * Dipanggil melalui URL:  /register (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.service.TemplateService;
import com.sistemppa.util.EmailUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import org.mindrot.jbcrypt.BCrypt;

public class RegisterServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(RegisterServlet.class.getName());
    private static final int MIN_PASSWORD_LENGTH = 10;
    private static final Pattern UPPERCASE_PATTERN = Pattern.compile("[A-Z]");
    private static final Pattern LOWERCASE_PATTERN = Pattern.compile("[a-z]");
    private static final Pattern DIGIT_PATTERN = Pattern.compile("\\d");
    private static final Pattern SPECIAL_PATTERN = Pattern.compile("[^A-Za-z0-9]");
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{8,20}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String fullName = trim(request.getParameter("full_name"));
        String username = trim(request.getParameter("username"));
        String phoneNumber = trim(request.getParameter("phone_number"));
        String email = trim(request.getParameter("email"));
        String password = trim(request.getParameter("password"));
        String confirmPassword = trim(request.getParameter("confirm_password"));
        String privacyConsent = trim(request.getParameter("privacy_consent"));

        if (fullName.isEmpty() || username.isEmpty() || phoneNumber.isEmpty() || email.isEmpty() || password.isEmpty()) {
            request.setAttribute("error", "Sila lengkapkan semua medan wajib.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!PHONE_PATTERN.matcher(phoneNumber).matches()) {
            request.setAttribute("error", "Nombor telefon tidak sah. Gunakan 8 hingga 20 aksara (nombor/simbol +()- sahaja).");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!password.equals(confirmPassword)) {
            request.setAttribute("error", "Pengesahan kata laluan tidak sepadan.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!("1".equals(privacyConsent) || "on".equalsIgnoreCase(privacyConsent)
                || "true".equalsIgnoreCase(privacyConsent))) {
            request.setAttribute("error", "Sila tandakan persetujuan privasi sebelum daftar akaun.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        String passwordPolicyError = validatePasswordPolicy(password);
        if (passwordPolicyError != null) {
            request.setAttribute("error", passwordPolicyError);
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureUsersPhoneNumberColumn(conn);

            if (userExists(conn, username, email)) {
                request.setAttribute("error", "Nama pengguna atau email sudah digunakan.");
                request.getRequestDispatcher("/register.jsp").forward(request, response);
                return;
            }

            String bcryptHash = BCrypt.hashpw(password, BCrypt.gensalt(12));
            String sql = "INSERT INTO users (username, email, phone_number, password_hash, role, full_name, status) VALUES (?, ?, ?, ?, 'USER', ?, 'ACTIVE')";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, username);
                stmt.setString(2, email);
                stmt.setString(3, phoneNumber);
                stmt.setString(4, bcryptHash);
                stmt.setString(5, fullName);
                stmt.executeUpdate();
            }
            response.sendRedirect(request.getContextPath() + "/login?registered=1");

        } catch (SQLException e) {
            LOGGER.severe("Registration failed: " + e.getMessage());
            request.setAttribute("error", "Pendaftaran gagal. Sila cuba lagi.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        }
    }

    private boolean sendVerificationEmail(HttpServletRequest request, Connection conn,
            int userId, String email, String fullName) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) {
            return false; // SMTP not configured
        }
        try {
            int smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls = Boolean.parseBoolean(getContextParam(request, "smtp.tls", "true"));
            String smtpUser = getContextParam(request, "smtp.username", "");
            String smtpPass = getContextParam(request, "smtp.password", "");
            String smtpFrom = getContextParam(request, "smtp.from", smtpUser);
            String baseUrl = getContextParam(request, "app.base.url",
                    request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath());

            String token = generateToken();
            Timestamp expires = new Timestamp(System.currentTimeMillis() + 24L * 60 * 60 * 1000);
            DashboardDataService.storeVerificationToken(conn, userId, token, expires);

            String verifyUrl = baseUrl + "/verify-email?token=" + token;
        Map<String, String> vars = new LinkedHashMap<>();
        vars.put("full_name", escapeHtml(fullName));
        vars.put("verify_url", escapeHtml(verifyUrl));
        vars.put("verify_link_html", buildHtmlLink(verifyUrl, "Klik Di Sini"));

        String fallbackSubject = "Pengesahan E-mel \u2013 Sistem Pendaftaran Produk Air";
        String fallbackBody = "<p>Tuan/Puan " + escapeHtml(fullName) + ",</p>"
            + "<p><strong>PENGESAHAN ALAMAT E-MEL SISTEM PENDAFTARAN PRODUK AIR</strong></p>"
            + "<p>Dengan hormatnya perkara di atas adalah dirujuk.</p>"
            + "<p>2. Sukacita dimaklumkan bahawa pendaftaran akaun tuan/puan telah diterima. "
            + "Bagi melengkapkan proses pengaktifan akaun, sila sahkan alamat e-mel melalui pautan berikut: "
            + buildHtmlLink(verifyUrl, "Klik Di Sini") + "</p>"
            + "<p>3. Pautan pengesahan ini sah selama dua puluh empat (24) jam dari tarikh emel ini dihantar. "
            + "Jika tuan/puan tidak membuat pendaftaran, sila abaikan emel ini.</p>"
            + "<p>Sekian, terima kasih.</p>"
            + "<p>Urusetia<br>Sistem Pendaftaran Produk Air</p>"
            + "<p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>";

        String subject = TemplateService.renderEmailSubject(conn, "EMAIL_VERIFICATION", vars, fallbackSubject);
        String body = TemplateService.renderEmailBody(conn, "EMAIL_VERIFICATION", vars, fallbackBody);

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            return emailUtil.sendHtml(email, subject, body);
        } catch (Exception e) {
            LOGGER.warning("Failed to send verification email to " + email + ": " + e.getMessage());
            return false;
        }
    }

    private void activateUserDirectly(Connection conn, int userId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement("UPDATE users SET status = 'ACTIVE' WHERE id = ?")) {
            stmt.setInt(1, userId);
            stmt.executeUpdate();
        }
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private String buildHtmlLink(String url, String label) {
        if (url == null || url.isBlank()) {
            return "";
        }
        String safeUrl = escapeHtml(url);
        String safeLabel = escapeHtml(label == null || label.isBlank() ? url : label);
        return "<a href=\"" + safeUrl + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + safeLabel + "</a>";
    }

    private boolean userExists(Connection conn, String username, String email) throws SQLException {
        String sql = "SELECT 1 FROM users WHERE username = ? OR email = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, username);
            stmt.setString(2, email);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
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

    private String validatePasswordPolicy(String password) {
        if (password == null || password.length() < MIN_PASSWORD_LENGTH) {
            return "Kata laluan mesti sekurang-kurangnya 10 aksara.";
        }
        if (!UPPERCASE_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu huruf besar.";
        }
        if (!LOWERCASE_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu huruf kecil.";
        }
        if (!DIGIT_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu nombor.";
        }
        if (!SPECIAL_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu simbol khas (contoh: !@#$%).";
        }
        return null;
    }
}


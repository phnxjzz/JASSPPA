package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;

/**
 * Handles KPP special-link generation and guest digital form flow.
 */
public class KppGuestAccessServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(KppGuestAccessServlet.class.getName());

    private static final String VERIFIED_TOKEN_ATTR = "kpp_guest_verified_token";
    private static final String VERIFIED_EMAIL_ATTR = "kpp_guest_verified_email";

    private static final String ACTION_KSPP = "KSPP";
    private static final String ACTION_UJPPP = "UJPPP";
    private static final String ACTION_BOTH = "KSPP_UJPPP";

    private static final Set<String> ACTIONS = Set.of(ACTION_KSPP, ACTION_UJPPP, ACTION_BOTH);
    private static final long TOKEN_VALIDITY_SECONDS = 7L * 24L * 60L * 60L;

    private String tokenSecret;

    @Override
    public void init() throws ServletException {
        String envSecret = System.getenv("KPP_LINK_SECRET");
        if (envSecret != null && !envSecret.isBlank()) {
            tokenSecret = envSecret.trim();
        } else {
            tokenSecret = "SPPA_KPP_GUEST_LINK_SECRET_CHANGE_ME";
            LOGGER.warning("KPP_LINK_SECRET env var not set. Using fallback secret; set KPP_LINK_SECRET in production.");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String servletPath = request.getServletPath();
        if ("/kpp/generate-link".equals(servletPath)) {
            handleGenerateLink(request, response);
            return;
        }
        
        if ("/kpp/delete-entry".equals(servletPath)) {
            handleDeleteEntry(request, response);
            return;
        }

        if (!"/kpp/guest-access".equals(servletPath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        TokenPayload payload = validateToken(request.getParameter("token"));
        if (payload == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Pautan khas tidak sah atau telah tamat tempoh.");
            return;
        }

        String view = str(request.getParameter("view"));
        if ("form".equalsIgnoreCase(view) && isVerified(request.getSession(false), request.getParameter("token"))) {
            request.setAttribute("kppActionType", payload.actionType());
            request.setAttribute("kppRecipientEmail", payload.recipientEmail());
            request.setAttribute("kppToken", request.getParameter("token"));
            request.getRequestDispatcher("/kpp-guest-form.jsp").forward(request, response);
            return;
        }

        request.setAttribute("kppActionType", payload.actionType());
        request.setAttribute("kppRecipientEmail", payload.recipientEmail());
        request.setAttribute("kppToken", request.getParameter("token"));
        request.getRequestDispatcher("/kpp-guest-verify.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!"/kpp/guest-access".equals(request.getServletPath())) {
            response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }

        String action = str(request.getParameter("flow_action"));
        if ("verify_email".equals(action)) {
            handleVerifyEmail(request, response);
            return;
        }
        if ("save_form".equals(action)) {
            handleSaveForm(request, response);
            return;
        }

        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Tindakan tidak dikenali.");
    }

    private void handleGenerateLink(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesi telah tamat.");
            return;
        }

        String role = str(session.getAttribute("role"));
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses ditolak.");
            return;
        }

        String recipientEmail = normalizeEmail(request.getParameter("recipient_email"));
        String actionType = normalizeActionType(request.getParameter("action_type"));

        if (!isValidEmail(recipientEmail)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Emel penerima tidak sah.");
            return;
        }

        if (!ACTIONS.contains(actionType)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Jenis tindakan tidak sah.");
            return;
        }

        long expiresAt = Instant.now().getEpochSecond() + TOKEN_VALIDITY_SECONDS;
        String token = issueToken(recipientEmail, actionType, expiresAt);

        String appBaseUrl = str(getServletContext().getInitParameter("app.base.url"));
        if (appBaseUrl.isBlank()) {
            appBaseUrl = request.getScheme() + "://" + request.getServerName()
                    + (request.getServerPort() == 80 || request.getServerPort() == 443 ? "" : ":" + request.getServerPort())
                    + request.getContextPath();
        }
        String link = appBaseUrl + "/kpp/guest-access?token=" + URLEncoder.encode(token, StandardCharsets.UTF_8);

        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"link\":\"" + jsonEscape(link) + "\"}");
    }

    private void handleVerifyEmail(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String token = str(request.getParameter("token"));
        TokenPayload payload = validateToken(token);
        if (payload == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Pautan khas tidak sah atau telah tamat tempoh.");
            return;
        }

        String enteredEmail = normalizeEmail(request.getParameter("access_email"));
        if (!isValidEmail(enteredEmail) || !enteredEmail.equalsIgnoreCase(payload.recipientEmail())) {
            request.setAttribute("kppVerifyError", "Emel tidak sepadan dengan emel penerima dalam pautan khas.");
            request.setAttribute("kppActionType", payload.actionType());
            request.setAttribute("kppRecipientEmail", payload.recipientEmail());
            request.setAttribute("kppToken", token);
            request.getRequestDispatcher("/kpp-guest-verify.jsp").forward(request, response);
            return;
        }

        HttpSession session = request.getSession(true);
        session.setAttribute(VERIFIED_TOKEN_ATTR, token);
        session.setAttribute(VERIFIED_EMAIL_ATTR, enteredEmail);

        response.sendRedirect(request.getContextPath() + "/kpp/guest-access?token="
                + URLEncoder.encode(token, StandardCharsets.UTF_8) + "&view=form");
    }

    private void handleSaveForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String token = str(request.getParameter("token"));
        TokenPayload payload = validateToken(token);
        HttpSession session = request.getSession(false);

        if (payload == null || !isVerified(session, token)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Sesi guest tidak sah. Sila akses semula melalui pautan khas.");
            return;
        }

        Map<String, String> collected = new LinkedHashMap<>();
        request.getParameterMap().forEach((key, values) -> {
            if (key != null && key.startsWith("f_") && values != null && values.length > 0) {
                collected.put(key, values[0]);
            }
        });

        String submitterEmail = normalizeEmail(String.valueOf(session.getAttribute(VERIFIED_EMAIL_ATTR)));

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureSubmissionTable(conn);
            saveSubmission(conn, payload, token, submitterEmail, collected, request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.severe("Failed to save KPP guest submission: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Gagal menyimpan borang digital. Sila cuba lagi.");
            return;
        }

        request.setAttribute("kppFormSaved", Boolean.TRUE);
        request.setAttribute("kppActionType", payload.actionType());
        request.setAttribute("kppRecipientEmail", payload.recipientEmail());
        request.setAttribute("kppToken", token);
        request.getRequestDispatcher("/kpp-guest-form.jsp").forward(request, response);
    }

    private void handleDeleteEntry(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"Sesi telah tamat.\"}");
            return;
        }

        String role = str(session.getAttribute("role"));
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"Akses ditolak.\"}");
            return;
        }

        String recipientEmail = normalizeEmail(request.getParameter("recipient_email"));
        if (!isValidEmail(recipientEmail)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"Emel penerima tidak sah.\"}");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureSubmissionTable(conn);
            int deleted = deleteSubmission(conn, recipientEmail);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":true,\"deleted\":" + deleted + "}");
        } catch (SQLException e) {
            LOGGER.severe("Failed to delete KPP guest entry: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"Gagal memadam entri.\"}");
        }
    }

    private boolean isVerified(HttpSession session, String token) {
        if (session == null) {
            return false;
        }
        Object verifiedToken = session.getAttribute(VERIFIED_TOKEN_ATTR);
        return verifiedToken instanceof String && token.equals(verifiedToken);
    }

    private String issueToken(String recipientEmail, String actionType, long expiresAt) {
        String payloadRaw = recipientEmail + "\n" + actionType + "\n" + expiresAt;
        String payload = base64UrlEncode(payloadRaw.getBytes(StandardCharsets.UTF_8));
        String signature = sign(payload);
        return payload + "." + signature;
    }

    private TokenPayload validateToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }

        String[] parts = token.split("\\.");
        if (parts.length != 2) {
            return null;
        }

        String payload = parts[0];
        String providedSignature = parts[1];
        String expectedSignature = sign(payload);

        if (!MessageDigest.isEqual(
                expectedSignature.getBytes(StandardCharsets.UTF_8),
                providedSignature.getBytes(StandardCharsets.UTF_8))) {
            return null;
        }

        String decoded;
        try {
            decoded = new String(Base64.getUrlDecoder().decode(payload), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ex) {
            return null;
        }

        String[] tokens = decoded.split("\\n");
        if (tokens.length != 3) {
            return null;
        }

        String email = normalizeEmail(tokens[0]);
        String actionType = normalizeActionType(tokens[1]);
        long expiresAt;
        try {
            expiresAt = Long.parseLong(tokens[2]);
        } catch (NumberFormatException ex) {
            return null;
        }

        if (!isValidEmail(email) || !ACTIONS.contains(actionType)) {
            return null;
        }
        if (Instant.now().getEpochSecond() > expiresAt) {
            return null;
        }

        return new TokenPayload(email, actionType, expiresAt);
    }

    private String sign(String payload) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(tokenSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] signature = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return base64UrlEncode(signature);
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("Unable to sign token", ex);
        }
    }

    private void ensureSubmissionTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS kpp_guest_form_submissions ("
                + "id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                + "recipient_email VARCHAR(255) NOT NULL,"
                + "action_type VARCHAR(30) NOT NULL,"
                + "token_hash VARCHAR(128) NOT NULL,"
                + "submitter_email VARCHAR(255) NOT NULL,"
                + "form_payload LONGTEXT NOT NULL,"
                + "source_ip VARCHAR(64),"
                + "submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP"
                + ")";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    private void saveSubmission(
            Connection conn,
            TokenPayload payload,
            String token,
            String submitterEmail,
            Map<String, String> formValues,
            String sourceIp
    ) throws SQLException {

        String sql = "INSERT INTO kpp_guest_form_submissions "
                + "(recipient_email, action_type, token_hash, submitter_email, form_payload, source_ip) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, payload.recipientEmail());
            stmt.setString(2, payload.actionType());
            stmt.setString(3, sha256Hex(token));
            stmt.setString(4, submitterEmail);
            stmt.setString(5, toJson(formValues));
            stmt.setString(6, str(sourceIp));
            stmt.executeUpdate();
        }
    }

    private int deleteSubmission(Connection conn, String recipientEmail) throws SQLException {
        String sql = "DELETE FROM kpp_guest_form_submissions WHERE recipient_email = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, recipientEmail);
            return stmt.executeUpdate();
        }
    }

    private String toJson(Map<String, String> formValues) {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        boolean first = true;
        for (Map.Entry<String, String> entry : formValues.entrySet()) {
            if (!first) {
                sb.append(',');
            }
            first = false;
            sb.append('"').append(jsonEscape(entry.getKey())).append('"')
                    .append(':')
                    .append('"').append(jsonEscape(entry.getValue())).append('"');
        }
        sb.append("}");
        return sb.toString();
    }

    private String jsonEscape(String text) {
        if (text == null) {
            return "";
        }
        return text
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(str(value).getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hashed) {
                sb.append(String.format(Locale.ROOT, "%02x", b));
            }
            return sb.toString();
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("Unable to hash token", ex);
        }
    }

    private String base64UrlEncode(byte[] input) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(input);
    }

    private String normalizeEmail(String email) {
        return str(email).toLowerCase(Locale.ROOT);
    }

    private String normalizeActionType(String actionType) {
        String value = str(actionType).toUpperCase(Locale.ROOT).replace('-', '_').replace(' ', '_');
        if ("KSPP+UJPPP".equals(value) || "KSPP_UJPPP".equals(value) || "BOTH".equals(value)) {
            return ACTION_BOTH;
        }
        if ("UJPPP".equals(value)) {
            return ACTION_UJPPP;
        }
        return ACTION_KSPP;
    }

    private boolean isValidEmail(String email) {
        return email != null
                && email.length() <= 255
                && email.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    }

    private String str(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private record TokenPayload(String recipientEmail, String actionType, long expiresAt) {}
}

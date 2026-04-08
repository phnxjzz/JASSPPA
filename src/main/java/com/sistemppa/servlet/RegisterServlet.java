package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;

public class RegisterServlet extends HttpServlet {
    private static final int MIN_PASSWORD_LENGTH = 10;
    private static final Pattern UPPERCASE_PATTERN = Pattern.compile("[A-Z]");
    private static final Pattern LOWERCASE_PATTERN = Pattern.compile("[a-z]");
    private static final Pattern DIGIT_PATTERN = Pattern.compile("\\d");
    private static final Pattern SPECIAL_PATTERN = Pattern.compile("[^A-Za-z0-9]");

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
        String email = trim(request.getParameter("email"));
        String password = trim(request.getParameter("password"));
        String confirmPassword = trim(request.getParameter("confirm_password"));

        if (fullName.isEmpty() || username.isEmpty() || email.isEmpty() || password.isEmpty()) {
            request.setAttribute("error", "Sila lengkapkan semua medan wajib.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            return;
        }

        if (!password.equals(confirmPassword)) {
            request.setAttribute("error", "Pengesahan kata laluan tidak sepadan.");
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
            if (userExists(conn, username, email)) {
                request.setAttribute("error", "Nama pengguna atau email sudah digunakan.");
                request.getRequestDispatcher("/register.jsp").forward(request, response);
                return;
            }

            String sql = "INSERT INTO users (username, email, password_hash, role, full_name, status) VALUES (?, ?, SHA2(?, 256), 'USER', ?, 'ACTIVE')";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, username);
                stmt.setString(2, email);
                stmt.setString(3, password);
                stmt.setString(4, fullName);
                stmt.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/login?registered=1");
        } catch (SQLException e) {
            request.setAttribute("error", "Pendaftaran gagal. Sila cuba lagi.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        }
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

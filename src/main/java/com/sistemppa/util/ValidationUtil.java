package com.sistemppa.util;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas ValidationUtil.
 * Dipanggil sebagai util/helper oleh servlet atau service.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.regex.Pattern;

/**
 * Shared validation and sanitisation utilities used across servlets.
 */
public final class ValidationUtil {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private static final Pattern UPPERCASE_PATTERN = Pattern.compile("[A-Z]");
    private static final Pattern LOWERCASE_PATTERN = Pattern.compile("[a-z]");
    private static final Pattern DIGIT_PATTERN     = Pattern.compile("\\d");
    private static final Pattern SPECIAL_PATTERN   = Pattern.compile("[^A-Za-z0-9]");

    private static final int MIN_PASSWORD_LENGTH = 10;

    private ValidationUtil() {}

    // -------------------------------------------------------------------------
    // HTML escaping
    // -------------------------------------------------------------------------

    /** Escape HTML special characters to prevent XSS. */
    public static String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#x27;");
    }

    // -------------------------------------------------------------------------
    // XLSX formula injection prevention
    // -------------------------------------------------------------------------

    /**
     * Sanitise a value before writing to an XLSX cell.
     * Values that start with =, +, -, @ would be interpreted as formulas by
     * Excel; prefix them with a single quote so they are treated as plain text.
     */
    public static String sanitizeXlsxCell(Object value) {
        if (value == null) return "";
        String s = String.valueOf(value);
        if (!s.isEmpty()) {
            char first = s.charAt(0);
            if (first == '=' || first == '+' || first == '-' || first == '@') {
                return "'" + s;
            }
        }
        return s;
    }

    // -------------------------------------------------------------------------
    // Email validation
    // -------------------------------------------------------------------------

    public static boolean isValidEmail(String email) {
        return email != null && EMAIL_PATTERN.matcher(email.trim()).matches();
    }

    // -------------------------------------------------------------------------
    // Password policy
    // -------------------------------------------------------------------------

    /**
     * Validate password against the unified site policy.
     * Returns {@code null} when the password is valid; otherwise returns a
     * Malay-language error message.
     */
    public static String validatePasswordPolicy(String password) {
        if (password == null || password.length() < MIN_PASSWORD_LENGTH) {
            return "Kata laluan mesti sekurang-kurangnya " + MIN_PASSWORD_LENGTH + " aksara.";
        }
        if (!UPPERCASE_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu huruf besar (A-Z).";
        }
        if (!LOWERCASE_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu huruf kecil (a-z).";
        }
        if (!DIGIT_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu nombor.";
        }
        if (!SPECIAL_PATTERN.matcher(password).find()) {
            return "Kata laluan mesti mengandungi sekurang-kurangnya satu simbol khas (contoh: !@#$%).";
        }
        return null; // valid
    }

    // -------------------------------------------------------------------------
    // File magic-byte validation
    // -------------------------------------------------------------------------

    /**
     * Verify an uploaded image file using magic bytes (not just the MIME type
     * declared by the browser, which can be spoofed).
     * Supports JPEG, PNG, GIF and WEBP.
     */
    public static boolean isValidImageMagicBytes(Part part) throws IOException {
        byte[] header = readHeader(part, 12);
        if (header == null) return false;

        // JPEG: FF D8
        if (header[0] == (byte) 0xFF && header[1] == (byte) 0xD8) return true;
        // PNG: 89 50 4E 47
        if (header[0] == (byte) 0x89 && header[1] == 'P' && header[2] == 'N' && header[3] == 'G') return true;
        // GIF: 47 49 46
        if (header[0] == 'G' && header[1] == 'I' && header[2] == 'F') return true;
        // WEBP: offset 8 = "WEBP"
        if (header.length >= 12
                && header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P') return true;

        return false;
    }

    /**
     * Verify an uploaded file is a genuine PDF using magic bytes.
     */
    public static boolean isValidPdfMagicBytes(Part part) throws IOException {
        byte[] header = readHeader(part, 4);
        if (header == null || header.length < 4) return false;
        // PDF: %PDF
        return header[0] == '%' && header[1] == 'P' && header[2] == 'D' && header[3] == 'F';
    }

    // -------------------------------------------------------------------------
    // Path traversal protection
    // -------------------------------------------------------------------------

    /**
     * Return {@code true} only if {@code candidate} resolves to a path that is
     * strictly inside {@code base}.  Both paths must exist on the filesystem
     * when this method is called (because {@link Path#toRealPath()} is used).
     * If the candidate file does not yet exist, use
     * {@link #isSafeUploadPathLenient(Path, Path)} instead.
     */
    public static boolean isSafeUploadPath(Path base, Path candidate) {
        try {
            Path realBase = base.toRealPath();
            Path realCand = candidate.toRealPath();
            return realCand.startsWith(realBase);
        } catch (IOException e) {
            return false;
        }
    }

    /**
     * Lenient variant that works even when the candidate file does not yet
     * exist: normalise and compare as absolute string paths.
     */
    public static boolean isSafeUploadPathLenient(Path base, Path candidate) {
        try {
            Path realBase = base.toRealPath();
            Path normCand = candidate.normalize().toAbsolutePath();
            return normCand.startsWith(realBase);
        } catch (IOException e) {
            return false;
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private static byte[] readHeader(Part part, int length) throws IOException {
        byte[] buf = new byte[length];
        int read;
        try (InputStream is = part.getInputStream()) {
            read = is.read(buf);
        }
        if (read <= 0) return null;
        if (read < length) {
            byte[] trimmed = new byte[read];
            System.arraycopy(buf, 0, trimmed, 0, read);
            return trimmed;
        }
        return buf;
    }
}


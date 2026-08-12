package com.sistemppa.util;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas UserDisplayIdUtil.
 * Dipanggil sebagai util/helper oleh servlet atau service.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import java.util.Locale;

public final class UserDisplayIdUtil {
    private UserDisplayIdUtil() {
    }

    public static String format(int userId, String role) {
        return format(userId, role, null);
    }

    public static String format(int userId, String role, Integer roleSequence) {
        int number = roleSequence != null && roleSequence > 0 ? roleSequence : userId;
        if (number <= 0) {
            return "-";
        }
        String normalizedRole = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        String prefix;
        if ("ADMIN".equals(normalizedRole)) {
            prefix = "ADM";
        } else if ("STAFF".equals(normalizedRole)) {
            prefix = "STF";
        } else {
            prefix = "P";
        }
        return prefix + String.format("%03d", number);
    }
}

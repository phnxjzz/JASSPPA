package com.sistemppa.util;

import java.util.Locale;

public final class UserDisplayIdUtil {
    private UserDisplayIdUtil() {
    }

    public static String format(int userId, String role) {
        if (userId <= 0) {
            return "-";
        }
        String normalizedRole = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        String prefix = "ADMIN".equals(normalizedRole) ? "A" : "P";
        return prefix + String.format("%03d", userId);
    }
}
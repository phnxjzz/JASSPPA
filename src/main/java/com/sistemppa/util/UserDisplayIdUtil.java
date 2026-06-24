package com.sistemppa.util;

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
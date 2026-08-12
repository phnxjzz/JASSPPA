package com.sistemppa.util;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas PublicUrlResolver.
 * Dipanggil sebagai util/helper oleh servlet atau service.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import jakarta.servlet.http.HttpServletRequest;

import java.net.URI;
import java.util.Locale;

public final class PublicUrlResolver {
    private PublicUrlResolver() {
    }

    public static String resolveBaseUrl(HttpServletRequest request, String configuredBaseUrl) {
        String forwardedBaseUrl = buildForwardedBaseUrl(request);
        if (!forwardedBaseUrl.isBlank()) {
            return forwardedBaseUrl;
        }

        String normalizedConfiguredBaseUrl = normalizeBaseUrl(configuredBaseUrl);
        if (!normalizedConfiguredBaseUrl.isBlank()) {
            if (shouldPreferRequestOverConfigured(normalizedConfiguredBaseUrl, request)) {
                return buildRequestBaseUrl(request);
            }
            return normalizedConfiguredBaseUrl;
        }

        return buildRequestBaseUrl(request);
    }

    public static String buildRequestBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String host = request.getServerName();
        int port = request.getServerPort();
        String contextPath = request.getContextPath();
        boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                || ("https".equalsIgnoreCase(scheme) && port == 443);
        return normalizeBaseUrl(scheme + "://" + host + (defaultPort ? "" : ":" + port) + contextPath);
    }

    public static String normalizeBaseUrl(String baseUrl) {
        String value = trim(baseUrl);
        while (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        return value;
    }

    public static boolean isLocalHostUrl(String url) {
        String value = trim(url).toLowerCase(Locale.ROOT);
        return value.startsWith("http://localhost")
                || value.startsWith("https://localhost")
                || value.startsWith("http://127.0.0.1")
                || value.startsWith("https://127.0.0.1")
                || value.startsWith("http://0.0.0.0")
                || value.startsWith("https://0.0.0.0")
                || value.startsWith("http://[::1]")
                || value.startsWith("https://[::1]");
    }

    public static boolean isLocalHostName(String hostName) {
        String value = trim(hostName).toLowerCase(Locale.ROOT);
        return "localhost".equals(value)
                || "127.0.0.1".equals(value)
                || "0.0.0.0".equals(value)
                || "::1".equals(value)
                || "[::1]".equals(value);
    }

    private static boolean shouldPreferRequestOverConfigured(String configuredBaseUrl, HttpServletRequest request) {
        String requestHost = trim(request.getServerName());
        if (requestHost.isBlank()) {
            return false;
        }

        // Never switch to localhost/loopback request host for public links.
        if (isLocalHostName(requestHost)) {
            return false;
        }

        if (isLocalHostUrl(configuredBaseUrl)) {
            return !isLocalHostName(requestHost);
        }

        String configuredHost = extractHost(configuredBaseUrl);
        if (configuredHost.isBlank()) {
            return false;
        }

        if (isPrivateHost(configuredHost)) {
            // Prefer the live request host whenever the configured private host is stale or different.
            return !configuredHost.equalsIgnoreCase(requestHost) && !isLocalHostName(requestHost);
        }

        return false;
    }

    private static String extractHost(String url) {
        try {
            URI uri = URI.create(trim(url));
            return trim(uri.getHost());
        } catch (IllegalArgumentException ex) {
            return "";
        }
    }

    private static boolean isPrivateHost(String host) {
        String value = trim(host).toLowerCase(Locale.ROOT);
        if (isLocalHostName(value)) {
            return true;
        }

        if (value.startsWith("10.") || value.startsWith("192.168.")) {
            return true;
        }

        if (value.startsWith("172.")) {
            String[] parts = value.split("\\.");
            if (parts.length >= 2) {
                try {
                    int secondOctet = Integer.parseInt(parts[1]);
                    if (secondOctet >= 16 && secondOctet <= 31) {
                        return true;
                    }
                } catch (NumberFormatException ignored) {
                    return false;
                }
            }
        }

        return false;
    }

    private static String buildForwardedBaseUrl(HttpServletRequest request) {
        String forwardedProto = firstHeaderValue(request, "X-Forwarded-Proto");
        String forwardedHost = firstHeaderValue(request, "X-Forwarded-Host");
        String forwardedPort = firstHeaderValue(request, "X-Forwarded-Port");

        if (forwardedProto.isBlank() && forwardedHost.isBlank() && forwardedPort.isBlank()) {
            return "";
        }

        String scheme = forwardedProto.isBlank() ? request.getScheme() : forwardedProto;
        String host = forwardedHost.isBlank() ? request.getServerName() : forwardedHost;
        String contextPath = request.getContextPath();

        if (host.contains(":")) {
            return normalizeBaseUrl(scheme + "://" + host + contextPath);
        }

        int port = parsePort(forwardedPort, request.getServerPort());
        boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                || ("https".equalsIgnoreCase(scheme) && port == 443);
        return normalizeBaseUrl(scheme + "://" + host + (defaultPort ? "" : ":" + port) + contextPath);
    }

    private static String firstHeaderValue(HttpServletRequest request, String headerName) {
        String value = request.getHeader(headerName);
        if (value == null || value.isBlank()) {
            return "";
        }
        int commaIndex = value.indexOf(',');
        if (commaIndex >= 0) {
            value = value.substring(0, commaIndex);
        }
        return value.trim();
    }

    private static int parsePort(String portValue, int fallbackPort) {
        String value = trim(portValue);
        if (value.isBlank()) {
            return fallbackPort;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            return fallbackPort;
        }
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }
}


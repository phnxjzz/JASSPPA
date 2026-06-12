package com.sistemppa.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

/**
 * Brute-force protection for POST /login and POST /forgot-password.
 *
 * After {@value #MAX_ATTEMPTS} failed attempts within {@value #WINDOW_MINUTES}
 * minutes the originating IP is blocked for {@value #BLOCK_MINUTES} minutes.
 *
 * Servlets call {@link #recordFailure} on bad credentials and
 * {@link #clearRecord} on successful login.
 */
public class RateLimitFilter implements Filter {

    private static final Logger LOGGER = Logger.getLogger(RateLimitFilter.class.getName());

    static final int  MAX_ATTEMPTS    = 5;
    static final long WINDOW_MINUTES  = 15;
    static final long BLOCK_MINUTES   = 15;

    private static final long WINDOW_MS = WINDOW_MINUTES * 60_000L;
    private static final long BLOCK_MS  = BLOCK_MINUTES  * 60_000L;

    // key = client IP,  value = long[3] { windowStart, failCount, blockExpiry }
    private static final ConcurrentHashMap<String, long[]> RECORDS = new ConcurrentHashMap<>();

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String ip  = resolveClientIp(request);
            long   now = System.currentTimeMillis();

            long[] record = RECORDS.computeIfAbsent(ip, k -> new long[]{now, 0L, 0L});

            synchronized (record) {
                if (record[2] > 0 && now < record[2]) {
                    // IP is still blocked
                    long waitSecs = (record[2] - now) / 1000;
                    LOGGER.warning("Rate limit blocked POST from IP " + ip
                            + " (" + waitSecs + "s remaining)");
                    request.setAttribute("error",
                            "Terlalu banyak percubaan gagal. Sila cuba lagi dalam "
                            + waitSecs + " saat.");
                    String path = request.getServletPath();
                    if (path != null && path.contains("forgot")) {
                        request.getRequestDispatcher("/forgot-password.jsp")
                               .forward(request, response);
                    } else {
                        request.getRequestDispatcher("/login.jsp")
                               .forward(request, response);
                    }
                    return;
                }

                // Reset window if it has expired
                if (now - record[0] > WINDOW_MS) {
                    record[0] = now;
                    record[1] = 0L;
                    record[2] = 0L;
                }
            }

            // Opportunistically clean up old entries (roughly every 500 requests)
            if (RECORDS.size() > 1000) {
                pruneStale(now);
            }
        }

        chain.doFilter(req, res);
    }

    /**
     * Call this from a servlet when authentication fails for the given IP.
     */
    public static void recordFailure(String ip) {
        long now = System.currentTimeMillis();
        long[] record = RECORDS.computeIfAbsent(ip, k -> new long[]{now, 0L, 0L});
        synchronized (record) {
            // Reset window if expired
            if (now - record[0] > WINDOW_MS) {
                record[0] = now;
                record[1] = 0L;
                record[2] = 0L;
            }
            record[1]++;
            if (record[1] >= MAX_ATTEMPTS && record[2] == 0) {
                record[2] = now + BLOCK_MS;
                LOGGER.warning("Rate limit: IP " + ip + " blocked for "
                        + BLOCK_MINUTES + " min after " + record[1] + " failures.");
            }
        }
    }

    /**
     * Call this from a servlet on successful authentication to clear the record.
     */
    public static void clearRecord(String ip) {
        RECORDS.remove(ip);
    }

    // -------------------------------------------------------------------------

    public static String resolveClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            return xff.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private void pruneStale(long now) {
        Iterator<Map.Entry<String, long[]>> it = RECORDS.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, long[]> entry = it.next();
            long[] r = entry.getValue();
            // Remove if block has expired and window has also expired
            if ((r[2] == 0 || now >= r[2]) && (now - r[0] > WINDOW_MS)) {
                it.remove();
            }
        }
    }

    @Override
    public void destroy() {
        RECORDS.clear();
    }
}

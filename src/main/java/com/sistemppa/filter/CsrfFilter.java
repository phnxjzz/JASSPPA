package com.sistemppa.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.logging.Logger;

/**
 * Synchronizer-token CSRF protection for all state-changing (POST) requests.
 *
 * <p>A unique, session-scoped token is generated on the first request and stored
 * under the session attribute {@value #SESSION_ATTR}.  Every POST request must
 * supply the same token as a form field named {@value #PARAM_NAME} or as an HTTP
 * header named {@value #HEADER_NAME}.  Requests that fail the check receive a
 * 403 Forbidden response.</p>
 *
 * <p>Paths that serve binary content (file downloads, image serving) are excluded
 * from the check because they do not accept POST bodies, but the filter still
 * generates/exposes the token for GET requests so that JSPs can embed it.</p>
 */
public class CsrfFilter implements Filter {

    private static final Logger LOGGER = Logger.getLogger(CsrfFilter.class.getName());

    /** Session attribute key that stores the CSRF token. */
    public static final String SESSION_ATTR = "csrf_token";

    /** HTML form field name expected in POST requests. */
    public static final String PARAM_NAME = "_csrf";

    /** HTTP header name accepted as an alternative to the form field (for AJAX). */
    public static final String HEADER_NAME = "X-CSRF-Token";

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        // Ensure session always has a CSRF token (create lazily)
        String token = ensureToken(request);

        // Expose token as request attribute so JSPs can embed it with ${csrf_token}
        request.setAttribute(SESSION_ATTR, token);

        String method = request.getMethod();
        boolean isPost = "POST".equalsIgnoreCase(method);

        if (isPost && !isExcluded(request)) {
            String supplied = request.getParameter(PARAM_NAME);
            if (supplied == null || supplied.isBlank()) {
                supplied = request.getHeader(HEADER_NAME);
            }

            if (supplied == null || !supplied.equals(token)) {
                LOGGER.warning("CSRF validation failed for "
                        + request.getMethod() + " " + request.getRequestURI()
                        + " from IP " + request.getRemoteAddr());
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Permintaan tidak sah (CSRF token tidak sepadan). Sila muat semula halaman dan cuba lagi.");
                return;
            }
        }

        chain.doFilter(req, res);
    }

    // -------------------------------------------------------------------------

    private String ensureToken(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Object existing = session.getAttribute(SESSION_ATTR);
            if (existing instanceof String && !((String) existing).isBlank()) {
                return (String) existing;
            }
        }
        // Generate a new token and bind it to the session
        String token = generateToken();
        HttpSession newSession = request.getSession(true);
        newSession.setAttribute(SESSION_ATTR, token);
        return token;
    }

    private static String generateToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Paths that should not be CSRF-validated on POST.
     * These are binary-serving endpoints that do not accept form data.
     */
    private boolean isExcluded(HttpServletRequest request) {
        String path = request.getServletPath();
        if (path == null) return false;
        return path.startsWith("/avatars/")
                || path.startsWith("/documents/")
                || path.startsWith("/announcement-images/")
                || path.startsWith("/product-attachments/");
    }

    @Override
    public void destroy() {}
}

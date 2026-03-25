package com.sistemppa.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class ProductAttachmentProxyServlet extends HttpServlet {
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(20))
            .build();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String rawUrl = request.getParameter("url");
        if (rawUrl == null || rawUrl.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Lampiran tidak sah");
            return;
        }

        URI uri;
        try {
            uri = URI.create(rawUrl.trim());
        } catch (IllegalArgumentException ex) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "URL lampiran tidak sah");
            return;
        }

        if (!isAllowedAttachmentHost(uri)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Sumber lampiran tidak dibenarkan");
            return;
        }

        HttpRequest proxyRequest = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofSeconds(30))
                .header("User-Agent", "SPPA-Attachment-Viewer/1.0")
                .GET()
                .build();

        try {
            HttpResponse<InputStream> proxyResponse = HTTP_CLIENT.send(proxyRequest, HttpResponse.BodyHandlers.ofInputStream());
            int status = proxyResponse.statusCode();
            if (status >= 400) {
                response.sendError(status == 404 ? HttpServletResponse.SC_NOT_FOUND : HttpServletResponse.SC_BAD_GATEWAY,
                        "Lampiran tidak dapat dipaparkan");
                return;
            }

            String contentType = proxyResponse.headers().firstValue("Content-Type").orElse("application/octet-stream");
            response.setContentType(contentType);
            response.setHeader("Content-Disposition", "inline; filename=\"" + extractFileName(uri) + "\"");
            proxyResponse.headers().firstValueAsLong("Content-Length").ifPresent(response::setContentLengthLong);

            try (InputStream inputStream = proxyResponse.body()) {
                inputStream.transferTo(response.getOutputStream());
            }
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            response.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Paparan lampiran terganggu");
        } catch (IOException ex) {
            response.sendError(HttpServletResponse.SC_BAD_GATEWAY, "Ralat semasa memaparkan lampiran");
        }
    }

    private boolean isAllowedAttachmentHost(URI uri) {
        String scheme = uri.getScheme();
        String host = uri.getHost();
        return ("https".equalsIgnoreCase(scheme) || "http".equalsIgnoreCase(scheme))
                && host != null
                && "water.sabah.gov.my".equalsIgnoreCase(host);
    }

    private String extractFileName(URI uri) {
        String path = uri.getPath();
        if (path == null || path.isBlank()) {
            return "lampiran";
        }
        int slashIndex = path.lastIndexOf('/');
        if (slashIndex >= 0 && slashIndex < path.length() - 1) {
            return path.substring(slashIndex + 1);
        }
        return "lampiran";
    }
}

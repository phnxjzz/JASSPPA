package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas AnnouncementImageServlet.
 * Dipanggil melalui URL:  /announcement-images/* (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

public class AnnouncementImageServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AnnouncementImageServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        if (pathInfo == null || pathInfo.isBlank() || "/".equals(pathInfo)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Gambar pengumuman tidak dijumpai");
            return;
        }

        String fileName = Path.of(pathInfo).getFileName().toString();
        if (!fileName.matches("[A-Za-z0-9._-]+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Nama fail gambar tidak sah");
            return;
        }

        Path imagePath = resolveImagePath(fileName, request);
        if (imagePath == null || !Files.exists(imagePath) || !Files.isRegularFile(imagePath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Gambar pengumuman tidak dijumpai");
            return;
        }

        String contentType = Files.probeContentType(imagePath);
        response.setContentType(contentType != null ? contentType : "application/octet-stream");
        response.setHeader("Content-Disposition", "inline; filename=\"" + fileName + "\"");
        response.setHeader("Cache-Control", "public, max-age=300");
        response.setContentLengthLong(Files.size(imagePath));
        Files.copy(imagePath, response.getOutputStream());
    }

    private Path resolveImagePath(String fileName, HttpServletRequest request) {
        List<Path> candidates = new ArrayList<>();

        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null && !catalinaBase.isBlank()) {
            candidates.add(Path.of(catalinaBase, "uploads", "sistemppa", "announcements", fileName));
            candidates.add(Path.of(catalinaBase, "webapps", resolveAppFolder(request), "assets", "images", "announcements", fileName));
        }

        String realAssetsPath = getServletContext().getRealPath("/assets/images/announcements");
        if (realAssetsPath != null && !realAssetsPath.isBlank()) {
            candidates.add(Path.of(realAssetsPath, fileName));
        }

        for (Path candidate : candidates) {
            if (Files.exists(candidate) && Files.isRegularFile(candidate)) {
                return candidate;
            }
        }

        LOGGER.warning("Announcement image not found for file: " + fileName + ". Checked paths: " + candidates);
        return null;
    }

    private String resolveAppFolder(HttpServletRequest request) {
        String contextPath = request.getContextPath();
        if (contextPath == null || contextPath.isBlank() || "/".equals(contextPath)) {
            return "ROOT";
        }
        return contextPath.startsWith("/") ? contextPath.substring(1) : contextPath;
    }
}

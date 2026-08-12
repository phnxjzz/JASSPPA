package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DashboardServlet.
 * Dipanggil melalui URL:  /dashboard (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.service.KppReminderService;
import com.sistemppa.service.StatusConfigService;
import com.sistemppa.service.TemplateService;
import com.sistemppa.util.EmailUtil;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.mindrot.jbcrypt.BCrypt;

@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class DashboardServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());
    private static final String ANNOUNCEMENT_IMAGE_ENDPOINT = "/announcement-images/";
    private static final int ADMIN_APPLICATION_LIMIT = 50;
    private static final int DIRECTOR_APPLICATION_LIMIT = 50;
    private static final int DASHBOARD_PRODUCT_LIMIT = 8;
    private static final int DASHBOARD_ANNOUNCEMENT_LIMIT = 20;
    private static final int HOMEPAGE_ANNOUNCEMENT_LIMIT = 5;
    private static final long ANNOUNCEMENT_MAX_IMAGE_SIZE_BYTES = 10L * 1024L * 1024L;
        private static final String[] KSPP_QUESTIONS = new String[] {
            "Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?",
            "Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal/pemilik produk masih sah?",
            "Adakah dokumen jaminan produk masih sah?",
            "Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?",
            "Adakah mudah dihubungi pada bila-bila masa?",
            "Adakah jadual penghantaran produk ke lokasi dipatuhi?",
            "Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?",
            "Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?",
            "Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?",
            "Adakah amalan pelaksanaan kerja mengurangkan kesan/impak negatif terhadap alam sekitar dipatuhi?",
            "Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?",
            "Adakah pemasangan produk dieselia/dipantau sehingga selesai?",
            "Adakah pengujian dan pentauliahan produk diasakna sehingga selesai?",
            "Adakah produk yang rosak diganti ataupun dibaiki dengan segera?",
            "Adakah Manual Operasi diberikan?",
            "Adakah latihan operasi dan senggara produk diberikan?",
            "Adakah produk yang dibekalkan memenuhi spesifikasi yang dititikrafkan, berfungsi dengan baik dan tidak ada kecacatan?",
            "Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)",
            "Adakah produk mempunyai rekod prestasi yang tidak memuaskan/rosak dalam tempoh tanggungan kecacatan?",
            "Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan."
        };

    // Titik masuk GET untuk URL /dashboard dari web.xml.
    // Dari sini sistem tentukan portal role semasa (USER/STAFF/ADMIN/DIRECTOR)
    // sebelum forward ke JSP yang berkaitan.
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer userId = (Integer) session.getAttribute("user_id");
        String role = (String) session.getAttribute("role");
        String email = session.getAttribute("email") == null
                ? ""
                : String.valueOf(session.getAttribute("email"));
        String portalRole = session.getAttribute("portal_role") == null
                ? ""
                : String.valueOf(session.getAttribute("portal_role")).trim().toUpperCase(java.util.Locale.ROOT);
        boolean adminViewingUserPortal = "ADMIN".equals(role) && "USER".equals(portalRole);
        boolean viewingStaffPortal = "STAFF".equals(portalRole);

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureApplicationWorkflowSchema(conn);
            if ("USER".equals(role) && !adminViewingUserPortal) {
                if (!isUserProfileApproved(conn, userId)) {
                    response.sendRedirect(request.getContextPath() + "/profile?complete_profile=1");
                    return;
                }
            }

            if (viewingStaffPortal) {
                boolean staffPortalRoleAllowed = "ADMIN".equals(role) || "STAFF".equals(role);
                if (staffPortalRoleAllowed && isGovernmentEmail(email)) {
                    request.getRequestDispatcher("/staff-dashboard.jsp").forward(request, response);
                    return;
                }
                response.sendRedirect(buildRoleLoginRedirect(request, "STAFF"));
                return;
            }

            if ("DIRECTOR".equals(role)) {
                if (!"DIRECTOR".equals(portalRole)) {
                    // Strict role check: DIRECTOR role accessing via non-DIRECTOR portal
                    LOGGER.warning("Unauthorized director access attempt: user " + userId + " with portalRole " + portalRole);
                    response.sendRedirect(buildRoleLoginRedirect(request, "DIRECTOR"));
                    return;
                }
                loadDirectorDashboard(conn, request);
                request.getRequestDispatcher("/director-dashboard.jsp").forward(request, response);
                return;
            }

            if ("ADMIN".equals(role) && !adminViewingUserPortal) {
                if (portalRole != null && !portalRole.isEmpty() && !"ADMIN".equals(portalRole)) {
                    // Strict role check: ADMIN trying to access with wrong portalRole
                    LOGGER.warning("Unauthorized admin access attempt: user " + userId + " with portalRole " + portalRole);
                    response.sendRedirect(buildRoleLoginRedirect(request, "ADMIN"));
                    return;
                }
                String adminView = trim(request.getParameter("view"));
                boolean settingsView = "settings".equalsIgnoreCase(adminView);
                Long downloadId = parseLong(request.getParameter("kpp_download_id"));
                if (downloadId != null) {
                    handleKppSubmissionDownload(conn, downloadId, response);
                    return;
                }

                if ("1".equals(request.getParameter("aduan_view"))) {
                    String adminDisplayId = DashboardDataService.resolveDisplayUserId(conn, userId, "ADMIN");
                    if (!"ADM001".equals(adminDisplayId)) {
                        response.sendRedirect(request.getContextPath() + "/dashboard?aduan_access=denied");
                        return;
                    }
                    loadAdminComplaintCenter(conn, request);
                    request.getRequestDispatcher("/admin-complaints.jsp").forward(request, response);
                    return;
                }

                String aduanAccessStatus = trim(request.getParameter("aduan_access"));
                if ("denied".equalsIgnoreCase(aduanAccessStatus)) {
                    request.setAttribute("aduan_access_notice", "Akses Modul Aduan ditolak. Hanya admin ADM001 dibenarkan.");
                } else if ("password_required".equalsIgnoreCase(aduanAccessStatus)) {
                    request.setAttribute("aduan_access_notice", "Kata laluan diperlukan untuk akses Modul Aduan.");
                } else if ("invalid_password".equalsIgnoreCase(aduanAccessStatus)) {
                    request.setAttribute("aduan_access_notice", "Kata laluan tidak sah untuk akses Modul Aduan.");
                } else if ("invalid_action".equalsIgnoreCase(aduanAccessStatus)) {
                    request.setAttribute("aduan_access_notice", "Permintaan akses Modul Aduan tidak sah.");
                }

                if ("1".equals(request.getParameter("smtp_saved"))) {
                    request.setAttribute("smtp_success", "Tetapan email pengirim berjaya dikemas kini.");
                }
                String smtpError = trim(request.getParameter("smtp_error"));
                if ("missing_host".equalsIgnoreCase(smtpError)) {
                    request.setAttribute("smtp_error", "SMTP host wajib diisi.");
                } else if ("invalid_port".equalsIgnoreCase(smtpError)) {
                    request.setAttribute("smtp_error", "SMTP port tidak sah. Gunakan nombor port yang betul seperti 587 atau 465.");
                } else if ("auth_missing_credential".equalsIgnoreCase(smtpError)) {
                    request.setAttribute("smtp_error", "SMTP authentication diaktifkan. Sila isi username dan password.");
                } else if ("save_failed".equalsIgnoreCase(smtpError)) {
                    request.setAttribute("smtp_error", "Gagal menyimpan tetapan SMTP. Sila cuba lagi.");
                }

                if ("1".equals(request.getParameter("announcement_saved"))) {
                    request.setAttribute("announcement_success", "Pengumuman berjaya disimpan.");
                }
                if ("1".equals(request.getParameter("announcement_deleted"))) {
                    request.setAttribute("announcement_success", "Pengumuman berjaya dihapus.");
                }
                if ("1".equals(request.getParameter("profile_review_saved"))) {
                    request.setAttribute("profile_review_success", "Semakan profil pemohon berjaya dikemas kini.");
                }
                String profileReviewError = trim(request.getParameter("profile_review_error"));
                if ("missing_user".equalsIgnoreCase(profileReviewError)) {
                    request.setAttribute("profile_review_error", "Pemohon tidak ditemui. Sila muat semula senarai dan cuba lagi.");
                } else if ("missing_reason".equalsIgnoreCase(profileReviewError)) {
                    request.setAttribute("profile_review_error", "Sebab penolakan wajib diisi sebelum tindakan diteruskan.");
                } else if ("invalid_action".equalsIgnoreCase(profileReviewError)) {
                    request.setAttribute("profile_review_error", "Tindakan semakan profil tidak sah.");
                }
                if (settingsView) {
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                } else {
                    loadAdminDashboard(conn, request);
                    request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                }
                return;
            }

            if ("STAFF".equals(role)) {
                if (!"STAFF".equals(portalRole)) {
                    // Strict role check: STAFF role accessing via non-STAFF portal
                    LOGGER.warning("Unauthorized staff access attempt: user " + userId + " with portalRole " + portalRole);
                    response.sendRedirect(buildRoleLoginRedirect(request, "STAFF"));
                    return;
                }
                request.getRequestDispatcher("/staff-dashboard.jsp").forward(request, response);
                return;
            }

            if ("USER".equals(role)) {
                // Strict role check: USER accessing dashboard
                if (portalRole != null && !portalRole.isEmpty() && !"USER".equals(portalRole) && !adminViewingUserPortal) {
                    LOGGER.warning("Unauthorized user access attempt: user " + userId + " with portalRole " + portalRole);
                    response.sendRedirect(buildRoleLoginRedirect(request, "USER"));
                    return;
                }
                loadUserDashboard(conn, userId, request);
                request.getRequestDispatcher("/user-dashboard.jsp").forward(request, response);
                return;
            }

            // Unknown role - deny access
            LOGGER.warning("Unknown role in session: user " + userId + " with role " + role);
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses ditolak.");
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    private String buildRoleLoginRedirect(HttpServletRequest request, String role) {
        return request.getContextPath() + "/login?role=" + role + "&portal_mismatch=1";
    }

    // Bina semua data paparan untuk director-dashboard.jsp:
    // kiraan mengikut peringkat semakan, senarai tindakan, dan mesej hasil tindakan.
    private void loadDirectorDashboard(Connection conn, HttpServletRequest request) throws SQLException {
        String search = trim(request.getParameter("q"));
        String dateFrom = trim(request.getParameter("date_from"));
        String dateTo = trim(request.getParameter("date_to"));
        HttpSession session = request.getSession(false);
        Integer currentDirectorUserId = session == null ? null : (Integer) session.getAttribute("user_id");
        request.setAttribute("current_director_display_id",
                DashboardDataService.resolveDisplayUserId(conn, currentDirectorUserId, "DIRECTOR"));

        // ===== PERINGKAT MULA (Initial Stage) =====
        int directorInitialPendingCount = DashboardDataService.countDirectorAdminApplications(
            conn,
            null,
            null,
            null,
            "INITIAL",
            null);
        request.setAttribute("director_initial_pending_count", directorInitialPendingCount);

        // Count applications by stage across all directors
        int directorInitialTerimaCount = countApplicationsByStatusAndReviewType(conn, "DILULUSKAN_PENGARAH", "INITIAL");
        int directorInitialTolakCount = countApplicationsByStatusAndReviewType(conn, "REJECTED", "INITIAL");
        int directorInitialGantungCount = countApplicationsByStatusAndReviewType(conn, "SUSPENDED", "INITIAL");

        int directorInitialTotalCount = directorInitialPendingCount + directorInitialTerimaCount 
            + directorInitialTolakCount + directorInitialGantungCount;

        request.setAttribute("director_initial_total_count", directorInitialTotalCount);
        request.setAttribute("director_initial_terima_count", directorInitialTerimaCount);
        request.setAttribute("director_initial_tolak_count", directorInitialTolakCount);
        request.setAttribute("director_initial_gantung_count", directorInitialGantungCount);

        // ===== PERINGKAT AKHIR (Final Stage) =====
        int directorFinalLulusCount = countApplicationsByStatusAndReviewType(conn, "MENUNGGU_SETERUSNYA_DILULUSKAN", "FINAL");
        int directorFinalTolakCount = countApplicationsByStatusAndReviewType(conn, "REJECTED", "FINAL")
            + countApplicationsByStatusAndReviewType(conn, "SUSPENDED", "FINAL")
            + countApplicationsByStatusAndReviewType(conn, "ARCHIVED", "FINAL")
            + countApplicationsByStatusAndReviewType(conn, "KUERI", "FINAL");

        request.setAttribute("director_final_lulus_count", directorFinalLulusCount);
        request.setAttribute("director_final_tidak_lulus_count", directorFinalTolakCount);

        int directorAdminCount = DashboardDataService.countDirectorAdminApplications(conn, search, dateFrom, dateTo);
        request.setAttribute("director_admin_count", directorAdminCount);

        request.setAttribute("search_query", search == null ? "" : search);
        request.setAttribute("date_from", dateFrom == null ? "" : dateFrom);
        request.setAttribute("date_to", dateTo == null ? "" : dateTo);
        // SENARAI PERMOHONAN MASUK: INITIAL review type, NOT forwarded by admin (submitted directly by user)
        int directorIncomingCount = DashboardDataService.countDirectorAdminApplications(conn, search, dateFrom, dateTo, "INITIAL", false);
        request.setAttribute("director_incoming_count", directorIncomingCount);
        request.setAttribute("director_incoming_applications",
            DashboardDataService.loadDirectorAdminApplications(conn, search, dateFrom, dateTo, DIRECTOR_APPLICATION_LIMIT, "INITIAL", false));

        request.setAttribute("director_applications", java.util.Collections.emptyList());
        request.setAttribute("director_processed_applications",
            currentDirectorUserId == null
                ? java.util.Collections.emptyList()
                : DashboardDataService.loadDirectorProcessedApplications(conn, currentDirectorUserId, search, dateFrom, dateTo, DIRECTOR_APPLICATION_LIMIT));
        // PERMOHONAN UNTUK DIAMBIL TINDAKAN (INITIAL): include all INITIAL pending items
        int directorInitialActionCount = DashboardDataService.countDirectorAdminApplications(conn, search, dateFrom, dateTo, "INITIAL", null);
        request.setAttribute("director_initial_action_count", directorInitialActionCount);
        request.setAttribute("director_initial_action_applications",
            DashboardDataService.loadDirectorAdminApplications(conn, search, dateFrom, dateTo, DIRECTOR_APPLICATION_LIMIT, "INITIAL", null));
        // FINAL: Permohonan Untuk Diluluskan (Lulus/Tolak/Gantung/Batal) â€” forwarded by ADMIN
        int directorFinalActionCount = DashboardDataService.countDirectorAdminApplications(conn, search, dateFrom, dateTo, "FINAL", true);
        request.setAttribute("director_final_action_count", directorFinalActionCount);
        request.setAttribute("director_final_action_applications",
            DashboardDataService.loadDirectorAdminApplications(conn, search, dateFrom, dateTo, DIRECTOR_APPLICATION_LIMIT, "FINAL", true));
        // Keep legacy attribute for backward compat (PERMOHONAN UNTUK DIAMBIL TINDAKAN combined)
        request.setAttribute("director_admin_count", directorInitialActionCount + directorFinalActionCount);
        request.setAttribute("director_admin_applications",
            DashboardDataService.loadDirectorAdminApplications(conn, search, dateFrom, dateTo, DIRECTOR_APPLICATION_LIMIT, null, true));
        request.setAttribute("director_processed_open", "1".equals(request.getParameter("director_updated")));

        if ("1".equals(request.getParameter("director_updated"))) {
            String result = trim(request.getParameter("director_result"));
            if ("accepted".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Permohonan berjaya dihantar kepada Pengarah untuk tindakan akhir.");
            } else if ("initial_accepted".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Terima berjaya direkodkan. Status kini: Diluluskan Pengarah dan dihantar ke Admin.");
            } else if ("initial_rejected".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Tolak berjaya direkodkan.");
            } else if ("initial_suspended".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Gantung berjaya direkodkan.");
            } else if ("initial_cancelled".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Batal berjaya direkodkan.");
            } else if ("final_approved".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Lulus (akhir) berjaya direkodkan. Menunggu tindakan Admin untuk pengeluaran sijil.");
            } else if ("final_rejected".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Tolak (akhir) berjaya direkodkan.");
            } else if ("final_suspended".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Gantung (akhir) berjaya direkodkan.");
            } else if ("final_cancelled".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Batal (akhir) berjaya direkodkan.");
            } else if ("initial_queried".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Kuiri berjaya direkodkan dan dihantar kepada pemohon.");
            } else if ("final_queried".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Kuiri (akhir) berjaya direkodkan dan dihantar kepada pemohon.");
            } else if ("approved_pending".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Luluskan telah direkodkan dan menunggu tindakan Seterusnya oleh Admin.");
            } else if ("rejected_pending".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Gagal telah direkodkan dan menunggu tindakan Seterusnya oleh Admin.");
            } else if ("suspended_pending".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Gantung telah direkodkan dan menunggu tindakan Seterusnya oleh Admin.");
            } else if ("cancelled_pending".equalsIgnoreCase(result)) {
                request.setAttribute("director_success", "Keputusan Batal telah direkodkan dan menunggu tindakan Seterusnya oleh Admin.");
            } else {
                request.setAttribute("director_success", "Tindakan Pengarah berjaya dikemas kini.");
            }
        }

        String directorError = trim(request.getParameter("director_error"));
        if ("missing_application".equalsIgnoreCase(directorError)) {
            request.setAttribute("director_error", "Permohonan tidak ditemui. Sila buka semula senarai dan cuba lagi.");
        } else if ("missing_notes".equalsIgnoreCase(directorError)) {
            request.setAttribute("director_error", "Sebab keputusan wajib diisi untuk Gagal, Gantung, Batal atau Kuiri.");
        } else if ("invalid_state".equalsIgnoreCase(directorError)) {
            request.setAttribute("director_error", "Status permohonan telah berubah. Muat semula senarai sebelum buat tindakan.");
        } else if ("save_failed".equalsIgnoreCase(directorError)) {
            request.setAttribute("director_error", "Tindakan gagal disimpan. Sila cuba lagi atau semak log sistem.");
        }
    }

    private int countApplicationsByStatusAndReviewType(Connection conn, String status, String reviewType) throws SQLException {
        // Count applications by current status and review type stage
        String sql = "SELECT COUNT(*) as count FROM applications WHERE status = ? AND director_review_type = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, reviewType);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("count");
                }
            }
        }
        return 0;
    }

    private boolean isGovernmentEmail(String email) {
        if (email == null) {
            return false;
        }
        String normalizedEmail = email.trim().toLowerCase(java.util.Locale.ROOT);
        return normalizedEmail.endsWith(".gov.my");
    }

    // Titik masuk POST untuk /dashboard.
    // Digunakan oleh borang dan AJAX dari admin-dashboard.jsp, director-dashboard.jsp, dan user-dashboard.jsp.
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String role = String.valueOf(session.getAttribute("role"));
        String directorAction = trim(request.getParameter("director_action"));
        String presentationResponseAction = trim(request.getParameter("presentation_response_action"));
        if ("DIRECTOR".equals(role) && directorAction != null && !directorAction.isBlank()) {
            processDirectorAction(request, response, session, directorAction, "/dashboard");
            return;
        }
        if ("USER".equals(role) && presentationResponseAction != null && !presentationResponseAction.isBlank()) {
            handleUserPresentationResponse(request, response, session, presentationResponseAction);
            return;
        }
        if (!"ADMIN".equals(role)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String requestContentType = request.getContentType();
        if (requestContentType != null
                && requestContentType.toLowerCase(java.util.Locale.ROOT).contains("application/json")) {
            JsonObject requestBody = parseJsonRequestBody(request);
            if ("send_kpp_emails".equalsIgnoreCase(getJsonString(requestBody, "action"))) {
                handleKppEmailSend(request, response, requestBody);
                return;
            }
        }

        String action = trim(request.getParameter("announcement_action"));
        String kppAction = trim(request.getParameter("kpp_submission_action"));
        String smtpAction = trim(request.getParameter("smtp_action"));
        String templateAction = trim(request.getParameter("template_action"));
        String maintenanceAction = trim(request.getParameter("maintenance_action"));
        String secureAction = trim(request.getParameter("secure_action"));
        String staffComplaintAction = trim(request.getParameter("staff_complaint_action"));
            String profileReviewAction = trim(request.getParameter("profile_review_action"));
        Integer userId = (Integer) session.getAttribute("user_id");

        String title = trim(request.getParameter("announcement_title"));
        String content = trim(request.getParameter("announcement_content"));
        String existingImageUrl = trim(request.getParameter("announcement_existing_image_url"));
        boolean isActive = "on".equalsIgnoreCase(request.getParameter("announcement_active"));

        if (maintenanceAction != null && !maintenanceAction.isBlank()) {
            boolean maintenanceEnabled;
            if ("enable".equalsIgnoreCase(maintenanceAction)) {
                maintenanceEnabled = true;
            } else if ("disable".equalsIgnoreCase(maintenanceAction)) {
                maintenanceEnabled = false;
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard?maintenance=unchanged");
                return;
            }

            request.getServletContext().setAttribute("maintenanceMode", maintenanceEnabled);
            String maintenanceQuery = maintenanceEnabled ? "enabled" : "disabled";
            response.sendRedirect(request.getContextPath() + "/dashboard?maintenance=" + maintenanceQuery);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            String adminDisplayId = DashboardDataService.resolveDisplayUserId(conn, userId, "ADMIN");
            if (secureAction != null && !secureAction.isBlank()) {
                if (!"access_aduan".equalsIgnoreCase(secureAction)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?aduan_access=invalid_action");
                    return;
                }

                if (!"ADM001".equals(adminDisplayId)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?aduan_access=denied");
                    return;
                }

                String securePassword = trim(request.getParameter("secure_password"));
                if (securePassword == null || securePassword.isBlank()) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?aduan_access=password_required");
                    return;
                }

                if (!validateUserPassword(conn, userId, securePassword)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?aduan_access=invalid_password");
                    return;
                }

                response.sendRedirect(request.getContextPath() + "/dashboard?aduan_view=1");
                return;
            }

            if (staffComplaintAction != null && !staffComplaintAction.isBlank()) {
                Long complaintId = parseLong(request.getParameter("staff_complaint_id"));
                String nextStatus = trim(request.getParameter("next_status")).toUpperCase(java.util.Locale.ROOT);
                if (complaintId == null || !isStaffComplaintStatusAllowed(nextStatus)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?aduan_view=1");
                    return;
                }

                ensureStaffComplaintTable(conn);
                updateStaffComplaintStatus(conn, complaintId, nextStatus);
                response.sendRedirect(request.getContextPath() + "/dashboard?aduan_view=1");
                return;
            }

            if (profileReviewAction != null && !profileReviewAction.isBlank()) {
                Integer profileUserId = parseInteger(request.getParameter("profile_user_id"));
                String profileReviewNotes = trim(request.getParameter("profile_review_notes"));
                if (profileUserId == null) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_error=missing_user#profileReviewPanel");
                    return;
                }
                if ("reject".equalsIgnoreCase(profileReviewAction) && (profileReviewNotes == null || profileReviewNotes.isBlank())) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_error=missing_reason#profileReviewPanel");
                    return;
                }

                handleProfileReviewAction(conn, request, response, profileUserId, profileReviewAction, profileReviewNotes, userId, adminDisplayId);
                return;
            }

                if (smtpAction != null && !smtpAction.isBlank()) {
                if (!"update_sender".equalsIgnoreCase(smtpAction)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&smtp_error=save_failed#smtpSettingsCard");
                    return;
                }

                String smtpHostInput = trim(request.getParameter("smtp_host"));
                String smtpPortInput = trim(request.getParameter("smtp_port"));
                String smtpUserInput = trim(request.getParameter("smtp_username"));
                String smtpPassInput = trim(request.getParameter("smtp_password"));
                String smtpFromInput = trim(request.getParameter("smtp_from"));
                String smtpAuthInput = trim(request.getParameter("smtp_auth"));
                String smtpTlsInput = trim(request.getParameter("smtp_tls"));

                if (smtpHostInput == null || smtpHostInput.isBlank()) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&smtp_error=missing_host#smtpSettingsCard");
                    return;
                }

                Integer smtpPortParsed = parseInteger(smtpPortInput);
                if (smtpPortParsed == null || smtpPortParsed <= 0) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&smtp_error=invalid_port#smtpSettingsCard");
                    return;
                }

                Map<String, String> existingSmtp = loadSmtpSettings(conn);
                boolean smtpAuthEnabled = parseBoolean(smtpAuthInput, true);
                boolean smtpTlsEnabled = parseBoolean(smtpTlsInput, true);
                String smtpUserFinal = smtpUserInput == null ? "" : smtpUserInput;
                String smtpPassFinal = (smtpPassInput == null || smtpPassInput.isBlank())
                    ? existingSmtp.getOrDefault("smtp_password", "")
                    : smtpPassInput;
                String smtpFromFinal = (smtpFromInput == null || smtpFromInput.isBlank()) ? smtpUserFinal : smtpFromInput;

                if (smtpAuthEnabled && (smtpUserFinal.isBlank() || smtpPassFinal.isBlank())) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&smtp_error=auth_missing_credential#smtpSettingsCard");
                    return;
                }

                upsertSmtpSetting(conn, "smtp_host", smtpHostInput,
                    "SMTP host server");
                upsertSmtpSetting(conn, "smtp_port", String.valueOf(smtpPortParsed),
                    "SMTP host port");
                upsertSmtpSetting(conn, "smtp_auth", String.valueOf(smtpAuthEnabled),
                    "Enable SMTP authentication");
                upsertSmtpSetting(conn, "smtp_tls", String.valueOf(smtpTlsEnabled),
                    "Enable STARTTLS for SMTP");
                upsertSmtpSetting(conn, "smtp_username", smtpUserFinal,
                    "SMTP username or sender account");
                upsertSmtpSetting(conn, "smtp_password", smtpPassFinal,
                    "SMTP password or app password");
                upsertSmtpSetting(conn, "smtp_from", smtpFromFinal,
                    "From email address used by system");

                insertAdminAuditLog(conn, userId, "UPDATE SMTP SETTINGS",
                    "Admin " + adminDisplayId + " kemas kini tetapan email pengirim SMTP.",
                    request.getRemoteAddr());

                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&smtp_saved=1#smtpSettingsCard");
                return;
                }

            if (templateAction != null && !templateAction.isBlank()) {
                TemplateService.ensureTemplateTables(conn);
                String tmplType  = trim(request.getParameter("template_type"));  // "email" or "notif"
                String tmplKey   = trim(request.getParameter("template_key"));
                String tmplName  = trim(request.getParameter("template_name"));
                String tmplDesc  = trim(request.getParameter("template_description"));

                if (tmplKey == null || tmplKey.isBlank()) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_error=missing_key#templatePanel");
                    return;
                }

                if ("save_email".equalsIgnoreCase(templateAction)) {
                    String tmplSubject = trim(request.getParameter("template_subject"));
                    String tmplBody    = trim(request.getParameter("template_body"));
                    if (tmplSubject == null || tmplSubject.isBlank() || tmplBody == null || tmplBody.isBlank()) {
                        response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_error=missing_fields#templatePanel");
                        return;
                    }
                    tmplSubject = TemplateService.normalizeTemplateInput(tmplSubject);
                    tmplBody = TemplateService.normalizeTemplateInput(tmplBody);
                    tmplBody = normalizeEmailTemplateBodyForAdminInput(tmplBody);
                    TemplateService.saveEmailTemplate(conn, tmplKey,
                            tmplName == null ? tmplKey : tmplName,
                            tmplSubject, tmplBody,
                            tmplDesc, userId);
                    insertAdminAuditLog(conn, userId, "UPDATE EMAIL TEMPLATE",
                            "Admin " + adminDisplayId + " kemas kini template e-mel: " + tmplKey,
                            request.getRemoteAddr());
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_saved=1#templatePanel");
                    return;
                }

                if ("save_notif".equalsIgnoreCase(templateAction)) {
                    String tmplMessage = trim(request.getParameter("template_message"));
                    if (tmplMessage == null || tmplMessage.isBlank()) {
                        response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_error=missing_fields#templatePanel");
                        return;
                    }
                    tmplMessage = TemplateService.normalizeTemplateInput(tmplMessage);
                    TemplateService.saveNotifTemplate(conn, tmplKey,
                            tmplName == null ? tmplKey : tmplName,
                            tmplMessage,
                            tmplDesc, userId);
                    insertAdminAuditLog(conn, userId, "UPDATE NOTIF TEMPLATE",
                            "Admin " + adminDisplayId + " kemas kini template notifikasi: " + tmplKey,
                            request.getRemoteAddr());
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_saved=1#templatePanel");
                    return;
                }

                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&template_error=invalid_action#templatePanel");
                return;
            }

            String statusConfigAction = trim(request.getParameter("status_config_action"));
            if (statusConfigAction != null && !statusConfigAction.isBlank()) {
                if (!"save_status".equalsIgnoreCase(statusConfigAction)) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&status_config_error=invalid_action#statusConfigPanel");
                    return;
                }
                String scKey         = trim(request.getParameter("sc_key"));
                String scLabel       = trim(request.getParameter("sc_label"));
                String scBg          = trim(request.getParameter("sc_bg"));
                String scText        = trim(request.getParameter("sc_text"));
                String scDesc        = trim(request.getParameter("sc_description"));
                String scSortStr     = trim(request.getParameter("sc_sort_order"));
                if (scKey == null || scKey.isBlank() || scLabel == null || scLabel.isBlank()) {
                    response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&status_config_error=missing_fields#statusConfigPanel");
                    return;
                }
                int scSort = 99;
                try { if (scSortStr != null) scSort = Integer.parseInt(scSortStr); } catch (NumberFormatException ignored) {}
                if (scBg   == null || scBg.isBlank())   scBg   = "#e0f2fe";
                if (scText == null || scText.isBlank()) scText = "#0369a1";
                StatusConfigService.ensureStatusConfigTable(conn);
                StatusConfigService.saveStatusConfig(conn, scKey, scLabel, scBg, scText, scDesc, scSort, userId);
                insertAdminAuditLog(conn, userId, "UPDATE STATUS CONFIG",
                        "Admin " + adminDisplayId + " kemas kini konfigurasi status: " + scKey,
                        request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&status_config_saved=1#statusConfigPanel");
                return;
            }

            if (kppAction != null && !kppAction.isBlank()) {
                Long submissionId = parseLong(request.getParameter("kpp_submission_id"));
                String kppSearch = trim(request.getParameter("kpp_q"));
                boolean showArchived = "1".equals(request.getParameter("kpp_show_archived"));
                String redirectBase = request.getContextPath() + "/dashboard";
                StringBuilder redirectQueryBuilder = new StringBuilder();
                if (kppSearch != null && !kppSearch.isBlank()) {
                    redirectQueryBuilder.append("kpp_q=")
                            .append(java.net.URLEncoder.encode(kppSearch, StandardCharsets.UTF_8));
                }
                if (showArchived) {
                    if (redirectQueryBuilder.length() > 0) {
                        redirectQueryBuilder.append("&");
                    }
                    redirectQueryBuilder.append("kpp_show_archived=1");
                }
                String redirectQuery = redirectQueryBuilder.length() == 0 ? "" : "?" + redirectQueryBuilder;

                if (submissionId == null) {
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }

                if ("archive".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.archiveKppGuestSubmission(conn, submissionId);
                        insertAdminAuditLog(conn, userId, "ARCHIVE KPP SUBMISSION",
                            "Admin " + adminDisplayId + " arkib borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }
                if ("unarchive".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.unarchiveKppGuestSubmission(conn, submissionId);
                        insertAdminAuditLog(conn, userId, "UNARCHIVE KPP SUBMISSION",
                            "Admin " + adminDisplayId + " keluarkan arkib borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }
                if ("delete".equalsIgnoreCase(kppAction)) {
                    DashboardDataService.deleteKppGuestSubmission(conn, submissionId);
                        insertAdminAuditLog(conn, userId, "DELETE KPP SUBMISSION",
                            "Admin " + adminDisplayId + " padam borang KPP ID " + submissionId,
                            request.getRemoteAddr());
                    response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                    return;
                }

                response.sendRedirect(redirectBase + redirectQuery + "#kpp-submissions");
                return;
            }

            if (action == null || action.isBlank()) {
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            if ("create_announcement".equals(action)) {
                if (title == null || title.isBlank() || content == null || content.isBlank()) {
                    request.setAttribute("announcement_error", "Tajuk dan kandungan pengumuman wajib diisi.");
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }

                String imageUrl;
                try {
                    imageUrl = storeAnnouncementImage(request, null);
                } catch (IllegalStateException | ServletException | IOException ex) {
                    LOGGER.warning("Announcement image upload failed: " + ex.getMessage());
                    request.setAttribute("announcement_error", resolveUploadErrorMessage(ex));
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.createAnnouncement(conn, title, content, imageUrl, isActive, userId);
                insertAdminAuditLog(conn, userId, "CREATE ANNOUNCEMENT",
                    "Admin " + adminDisplayId + " cipta pengumuman: " + title,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&announcement_saved=1#announcementPanel");
                return;
            }

            if ("update_announcement".equals(action)) {
                Integer announcementId = parseInteger(request.getParameter("announcement_id"));
                if (announcementId == null) {
                    request.setAttribute("announcement_error", "ID pengumuman tidak sah.");
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }

                if (title == null || title.isBlank() || content == null || content.isBlank()) {
                    request.setAttribute("announcement_error", "Tajuk dan kandungan pengumuman wajib diisi.");
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    request.setAttribute("announcement_edit_id", announcementId);
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }

                String imageUrl;
                try {
                    imageUrl = storeAnnouncementImage(request, existingImageUrl);
                } catch (IllegalStateException | ServletException | IOException ex) {
                    LOGGER.warning("Announcement image update failed: " + ex.getMessage());
                    request.setAttribute("announcement_error", resolveUploadErrorMessage(ex));
                    request.setAttribute("announcement_form_title", title == null ? "" : title);
                    request.setAttribute("announcement_form_content", content == null ? "" : content);
                    request.setAttribute("announcement_form_active", isActive);
                    request.setAttribute("announcement_form_image_url", existingImageUrl == null ? "" : existingImageUrl);
                    request.setAttribute("announcement_edit_id", announcementId);
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.updateAnnouncement(conn, announcementId, title, content, imageUrl, isActive, userId);
                insertAdminAuditLog(conn, userId, "UPDATE ANNOUNCEMENT",
                    "Admin " + adminDisplayId + " kemas kini pengumuman #" + announcementId + ": " + title,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&announcement_saved=1#announcementPanel");
                return;
            }

            if ("delete_announcement".equals(action)) {
                Integer announcementId = parseInteger(request.getParameter("announcement_id"));
                if (announcementId == null) {
                    request.setAttribute("announcement_error", "ID pengumuman tidak sah.");
                    loadAdminSettings(conn, request);
                    request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
                    return;
                }
                DashboardDataService.deleteAnnouncement(conn, announcementId);
                insertAdminAuditLog(conn, userId, "DELETE ANNOUNCEMENT",
                    "Admin " + adminDisplayId + " padam pengumuman #" + announcementId,
                    request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/dashboard?view=settings&announcement_deleted=1#announcementPanel");
                return;
            }

            request.setAttribute("announcement_error", "Tindakan pengumuman tidak sah.");
            loadAdminSettings(conn, request);
            request.getRequestDispatcher("/admin-settings.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    private void loadAdminDashboard(Connection conn, HttpServletRequest request) throws SQLException {
        String search = trim(request.getParameter("q"));
        String status = toStatusOptionValue(trim(request.getParameter("status")));
        String dateFrom = trim(request.getParameter("date_from"));
        String dateTo = trim(request.getParameter("date_to"));
        String kppSearch = trim(request.getParameter("kpp_q"));
        boolean includeArchivedKpp = "1".equals(request.getParameter("kpp_show_archived"));
        HttpSession session = request.getSession(false);
        Integer currentAdminUserId = session == null ? null : (Integer) session.getAttribute("user_id");
        request.setAttribute("current_admin_display_id",
                DashboardDataService.resolveDisplayUserId(conn, currentAdminUserId, "ADMIN"));

        Map<String, Integer> stats = DashboardDataService.loadAdminStats(conn);
        for (Map.Entry<String, Integer> entry : stats.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        // Additional admin performance metrics (not all may exist in schema, use best-effort queries)
        try {
            int adminQueryCount = DashboardDataService.countApplicationsByStatuses(conn, "KUERI");
            int adminInAction = DashboardDataService.countApplicationsByStatuses(conn, "IN_PROGRESS", "UNDER_REVIEW");
            int adminRecommendation = DashboardDataService.countApplicationsByAdminNotesPattern(conn, "%syor%")
                    + DashboardDataService.countApplicationsByAdminNotesPattern(conn, "%recommend%");

            request.setAttribute("admin_query_count", adminQueryCount);
            request.setAttribute("admin_in_action_count", adminInAction);
            request.setAttribute("admin_recommendation_count", adminRecommendation);

            // Map additional friendly names expected by JSP
            request.setAttribute("terima_count", stats.getOrDefault("approved_count", 0));
            request.setAttribute("lulus_count", stats.getOrDefault("approved_count", 0));
            request.setAttribute("tidak_lulus_count", stats.getOrDefault("rejected_count", 0));
        } catch (SQLException e) {
            // best-effort: don't break dashboard rendering
            LOGGER.warning("Failed to compute extra admin metrics: " + e.getMessage());
            request.setAttribute("admin_query_count", 0);
            request.setAttribute("admin_in_action_count", 0);
            request.setAttribute("admin_recommendation_count", 0);
            request.setAttribute("terima_count", stats.getOrDefault("approved_count", 0));
            request.setAttribute("lulus_count", stats.getOrDefault("approved_count", 0));
            request.setAttribute("tidak_lulus_count", stats.getOrDefault("rejected_count", 0));
        }

        request.setAttribute("search_query", search == null ? "" : search);
        request.setAttribute("selected_status", status == null ? "" : status);
        request.setAttribute("date_from", dateFrom == null ? "" : dateFrom);
        request.setAttribute("date_to", dateTo == null ? "" : dateTo);
        request.setAttribute("pending_applications",
                DashboardDataService.loadApplications(conn, search, status, dateFrom, dateTo, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("director_action_pending_count",
            DashboardDataService.countDirectorActionPendingForAdmin(conn));
        request.setAttribute("update_application_reviews",
            DashboardDataService.loadUpdateApplicationsForReview(conn, search, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("update_application_review_count",
            DashboardDataService.countUpdateApplicationsForReview(conn));
        request.setAttribute("profile_review_requests",
            DashboardDataService.loadPendingProfileReviews(conn, search, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("profile_review_count",
            DashboardDataService.countPendingProfileReviews(conn));
        request.setAttribute("filtered_application_count",
                DashboardDataService.countApplications(conn, search, status, dateFrom, dateTo));
        request.setAttribute("registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, false, 0));
        request.setAttribute("new_registered_users_list",
            DashboardDataService.loadRegisteredUsers(conn, null, true, 0));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("kpp_search_query", kppSearch == null ? "" : kppSearch);
        request.setAttribute("kpp_show_archived", includeArchivedKpp);
        request.setAttribute("kpp_guest_submissions",
            DashboardDataService.loadKppGuestSubmissions(conn, 50, kppSearch, includeArchivedKpp));
        request.setAttribute("presentation_invites", DashboardDataService.loadPresentationInvitesForAdmin(conn, 60));
        request.setAttribute("kpp_contacts", DashboardDataService.loadKppContacts(conn));
        Map<String, String> smtpSettings = loadSmtpSettings(conn);
        request.setAttribute("smtp_setting_host", coalesceSmtpValue(smtpSettings.get("smtp_host"), getContextParam(request, "smtp.host", "")));
        request.setAttribute("smtp_setting_port", coalesceSmtpValue(smtpSettings.get("smtp_port"), getContextParam(request, "smtp.port", "587")));
        request.setAttribute("smtp_setting_auth", coalesceSmtpValue(smtpSettings.get("smtp_auth"), getContextParam(request, "smtp.auth", "true")));
        request.setAttribute("smtp_setting_tls", coalesceSmtpValue(smtpSettings.get("smtp_tls"), getContextParam(request, "smtp.tls", "true")));
        request.setAttribute("smtp_setting_username", coalesceSmtpValue(smtpSettings.get("smtp_username"), getContextParam(request, "smtp.username", "")));
        request.setAttribute("smtp_setting_from", coalesceSmtpValue(smtpSettings.get("smtp_from"), getContextParam(request, "smtp.from", "")));
        List<Map<String, Object>> adminAuditLogs = DashboardDataService.loadRecentAdminAuditLogs(conn, 0);
        request.setAttribute("admin_audit_logs", filterSensitiveAduanAuditLogs(adminAuditLogs));

        ensureStaffComplaintTable(conn);
        request.setAttribute("staff_complaint_new_count", countStaffComplaintsByStatus(conn, "NEW"));
        request.setAttribute("staff_complaints", loadStaffComplaints(conn, 30));

        loadAnnouncementManagementData(conn, request);

        // Template management
        try {
            TemplateService.ensureTemplateTables(conn);
            request.setAttribute("email_templates", TemplateService.loadAllEmailTemplates(conn));
            request.setAttribute("notif_templates", TemplateService.loadAllNotifTemplates(conn));
        } catch (SQLException e) {
            LOGGER.warning("Failed to load templates for admin dashboard: " + e.getMessage());
            request.setAttribute("email_templates", java.util.Collections.emptyList());
            request.setAttribute("notif_templates", java.util.Collections.emptyList());
        }

        // Status configuration
        try {
            StatusConfigService.ensureStatusConfigTable(conn);
            request.setAttribute("status_configs", StatusConfigService.loadAll(conn));
            request.setAttribute("status_label_map", StatusConfigService.loadLabelMap(conn));
        } catch (SQLException e) {
            LOGGER.warning("Failed to load status configs: " + e.getMessage());
            request.setAttribute("status_configs", java.util.Collections.emptyList());
            request.setAttribute("status_label_map", java.util.Collections.emptyMap());
        }
    }

    private void loadAdminSettings(Connection conn, HttpServletRequest request) throws SQLException {
        HttpSession session = request.getSession(false);
        Integer currentAdminUserId = session == null ? null : (Integer) session.getAttribute("user_id");
        request.setAttribute("current_admin_display_id",
                DashboardDataService.resolveDisplayUserId(conn, currentAdminUserId, "ADMIN"));

        Map<String, String> smtpSettings = loadSmtpSettings(conn);
        request.setAttribute("smtp_setting_host", coalesceSmtpValue(smtpSettings.get("smtp_host"), getContextParam(request, "smtp.host", "")));
        request.setAttribute("smtp_setting_port", coalesceSmtpValue(smtpSettings.get("smtp_port"), getContextParam(request, "smtp.port", "587")));
        request.setAttribute("smtp_setting_auth", coalesceSmtpValue(smtpSettings.get("smtp_auth"), getContextParam(request, "smtp.auth", "true")));
        request.setAttribute("smtp_setting_tls", coalesceSmtpValue(smtpSettings.get("smtp_tls"), getContextParam(request, "smtp.tls", "true")));
        request.setAttribute("smtp_setting_username", coalesceSmtpValue(smtpSettings.get("smtp_username"), getContextParam(request, "smtp.username", "")));
        request.setAttribute("smtp_setting_from", coalesceSmtpValue(smtpSettings.get("smtp_from"), getContextParam(request, "smtp.from", "")));

        loadAnnouncementManagementData(conn, request);

        try {
            TemplateService.ensureTemplateTables(conn);
            request.setAttribute("email_templates", TemplateService.loadAllEmailTemplates(conn));
            request.setAttribute("notif_templates", TemplateService.loadAllNotifTemplates(conn));
        } catch (SQLException e) {
            LOGGER.warning("Failed to load templates for admin settings: " + e.getMessage());
            request.setAttribute("email_templates", java.util.Collections.emptyList());
            request.setAttribute("notif_templates", java.util.Collections.emptyList());
        }

        try {
            StatusConfigService.ensureStatusConfigTable(conn);
            request.setAttribute("status_configs", StatusConfigService.loadAll(conn));
            request.setAttribute("status_label_map", StatusConfigService.loadLabelMap(conn));
        } catch (SQLException e) {
            LOGGER.warning("Failed to load status configs for admin settings: " + e.getMessage());
            request.setAttribute("status_configs", java.util.Collections.emptyList());
            request.setAttribute("status_label_map", java.util.Collections.emptyMap());
        }
    }

    private void loadAnnouncementManagementData(Connection conn, HttpServletRequest request) throws SQLException {
        List<Map<String, Object>> announcements = DashboardDataService.loadAllAnnouncements(conn, DASHBOARD_ANNOUNCEMENT_LIMIT);
        request.setAttribute("announcements", announcements);

        Integer editId = parseInteger(request.getParameter("announcement_id"));
        if (editId != null) {
            Map<String, Object> editing = DashboardDataService.loadAnnouncementById(conn, editId);
            if (!editing.isEmpty()) {
                request.setAttribute("announcement_editing", editing);
            }
        }

        if (request.getAttribute("announcement_form_title") == null) {
            request.setAttribute("announcement_form_title", "");
        }
        if (request.getAttribute("announcement_form_content") == null) {
            request.setAttribute("announcement_form_content", "");
        }
        if (request.getAttribute("announcement_form_active") == null) {
            request.setAttribute("announcement_form_active", Boolean.TRUE);
        }
        if (request.getAttribute("announcement_form_image_url") == null) {
            request.setAttribute("announcement_form_image_url", "");
        }
    }

    private boolean isUserProfileApproved(Connection conn, int userId) throws SQLException {
        Map<String, Object> summary = DashboardDataService.loadUserSummary(conn, userId);
        String reviewStatus = summary.get("profile_review_status") == null
                ? "DRAFT"
                : String.valueOf(summary.get("profile_review_status"));
        return "APPROVED".equalsIgnoreCase(reviewStatus);
    }

    private void handleProfileReviewAction(Connection conn, HttpServletRequest request, HttpServletResponse response,
            int profileUserId, String action, String reviewNotes, Integer adminUserId, String adminDisplayId)
            throws SQLException, IOException {
        Map<String, Object> userSummary = DashboardDataService.loadUserSummary(conn, profileUserId);
        if (userSummary.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_error=missing_user#profileReviewPanel");
            return;
        }

        String userEmail = userSummary.get("email") == null ? "" : String.valueOf(userSummary.get("email"));
        String fullName = userSummary.get("full_name") == null ? "" : String.valueOf(userSummary.get("full_name"));
        String displayId = DashboardDataService.resolveDisplayUserId(conn, profileUserId, "USER");
        String normalizedAction = action == null ? "" : action.trim().toLowerCase(java.util.Locale.ROOT);

        if ("approve".equals(normalizedAction) || "accept".equals(normalizedAction) || "activate".equals(normalizedAction)) {
            DashboardDataService.updateUserProfileReviewStatus(conn, profileUserId, "APPROVED", adminUserId, null);
            Map<String, String> approveVars = new java.util.HashMap<>();
            approveVars.put("display_id", displayId);
            String approveNotif = TemplateService.renderNotif(conn, "NOTIF_PROFILE_APPROVED", approveVars,
                    "Maklumat profil anda telah diterima. Akaun anda kini boleh mengakses dashboard dan fungsi sistem.");
            DashboardDataService.insertNotification(conn, profileUserId, approveNotif, "PROFILE_REVIEW");
            sendProfileReviewEmail(conn, userEmail, fullName, true, null, displayId);
            insertAdminAuditLog(conn, adminUserId, "APPROVE USER PROFILE",
                    "Admin " + adminDisplayId + " luluskan semakan profil pengguna " + displayId,
                    request.getRemoteAddr());
            response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_saved=1#profileReviewPanel");
            return;
        }

        if ("reject".equals(normalizedAction) || "cancel".equals(normalizedAction)) {
            if (reviewNotes == null || reviewNotes.isBlank()) {
                response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_error=missing_reason#profileReviewPanel");
                return;
            }

            DashboardDataService.updateUserProfileReviewStatus(conn, profileUserId, "REJECTED", adminUserId, reviewNotes);
            Map<String, String> rejectVars = new java.util.HashMap<>();
            rejectVars.put("review_notes", reviewNotes);
            String rejectNotif = TemplateService.renderNotif(conn, "NOTIF_PROFILE_REJECTED", rejectVars,
                    "Maklumat profil anda ditolak. Sebab: " + reviewNotes);
            DashboardDataService.insertNotification(conn, profileUserId, rejectNotif, "PROFILE_REVIEW");
            sendProfileReviewEmail(conn, userEmail, fullName, false, reviewNotes, displayId);
            insertAdminAuditLog(conn, adminUserId, "REJECT USER PROFILE",
                    "Admin " + adminDisplayId + " tolak semakan profil pengguna " + displayId + ". Sebab: " + reviewNotes,
                    request.getRemoteAddr());
            response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_saved=1#profileReviewPanel");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/dashboard?profile_review_error=invalid_action#profileReviewPanel");
    }

    private void sendProfileReviewEmail(Connection conn, String toEmail, String fullName,
            boolean approved, String reviewNotes, String displayId) {
        if (toEmail == null || toEmail.isBlank()) {
            return;
        }

        try {
            Map<String, String> smtpSettings = loadSmtpSettings(conn);
            String smtpHost = coalesceSmtpValue(smtpSettings.get("smtp_host"), "");
            if (smtpHost == null || smtpHost.isBlank()) {
                return;
            }

            int smtpPort = Integer.parseInt(coalesceSmtpValue(smtpSettings.get("smtp_port"), "587"));
            boolean smtpAuth = parseBoolean(coalesceSmtpValue(smtpSettings.get("smtp_auth"), "true"), true);
            boolean smtpTls = parseBoolean(coalesceSmtpValue(smtpSettings.get("smtp_tls"), "true"), true);
            String smtpUser = coalesceSmtpValue(smtpSettings.get("smtp_username"), "");
            String smtpPass = coalesceSmtpValue(smtpSettings.get("smtp_password"), "");
            String smtpFrom = coalesceSmtpValue(smtpSettings.get("smtp_from"), smtpUser);

            if (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank())) {
                return;
            }

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            Map<String, String> profVars = new java.util.HashMap<>();
            profVars.put("full_name", fullName == null ? "" : escapeHtml(fullName));
            profVars.put("display_id", displayId == null ? "" : escapeHtml(displayId));
            profVars.put("review_notes", reviewNotes == null ? "" : escapeHtml(reviewNotes));

            String fallbackSubject = approved ? "Semakan Profil Diluluskan - SPPA" : "Semakan Profil Ditolak - SPPA";
            String fallbackMsg = approved
                    ? "<p>Salam " + escapeHtml(fullName) + ",</p>"
                            + "<p>Semakan profil anda telah <strong>diluluskan</strong>. Akaun " + escapeHtml(displayId)
                            + " kini boleh mengakses dashboard dan fungsi sistem.</p>"
                    : "<p>Salam " + escapeHtml(fullName) + ",</p>"
                            + "<p>Semakan profil anda telah <strong>ditolak</strong>.</p>"
                            + "<p>Sebab penolakan: " + escapeHtml(reviewNotes == null ? "" : reviewNotes) + "</p>"
                            + "<p>Sila kemas kini profil anda dan hantar semula untuk semakan.</p>";

            String emailTemplateKey = approved ? "PROFILE_REVIEW_APPROVED" : "PROFILE_REVIEW_REJECTED";
            String subject = TemplateService.renderEmailSubject(conn, emailTemplateKey, profVars, fallbackSubject);
            String message = TemplateService.renderEmailBody(conn, emailTemplateKey, profVars, fallbackMsg);
            emailUtil.sendHtml(toEmail, subject, message);
        } catch (Exception e) {
            LOGGER.warning("Failed to send profile review email to " + toEmail + ": " + e.getMessage());
        }
    }

    private void loadAdminComplaintCenter(Connection conn, HttpServletRequest request) throws SQLException {
        ensureStaffComplaintTable(conn);
        request.setAttribute("staff_complaint_new_count", countStaffComplaintsByStatus(conn, "NEW"));
        request.setAttribute("staff_complaints", loadStaffComplaints(conn, 60));
    }

    private boolean isStaffComplaintStatusAllowed(String status) {
        return "NEW".equals(status)
                || "UNDER_REVIEW".equals(status)
                || "IN_PROGRESS".equals(status)
                || "RESOLVED".equals(status);
    }

    private void ensureStaffComplaintTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS staff_complaints ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "staff_user_id INT NOT NULL, "
                + "staff_username VARCHAR(100) NOT NULL, "
                + "staff_email VARCHAR(255) NOT NULL, "
                + "department VARCHAR(150) NOT NULL, "
                + "complaint_category VARCHAR(100) NOT NULL, "
                + "complaint_title VARCHAR(200) NOT NULL, "
                + "complaint_details TEXT NOT NULL, "
                + "incident_date DATE NULL, "
                + "incident_location VARCHAR(255) NULL, "
                + "urgency VARCHAR(30) NOT NULL, "
                + "preferred_contact VARCHAR(120) NULL, "
                + "status VARCHAR(20) NOT NULL DEFAULT 'NEW', "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.execute();
        }
    }

    private int countStaffComplaintsByStatus(Connection conn, String status) throws SQLException {
        String sql = "SELECT COUNT(*) FROM staff_complaints WHERE UPPER(status) = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    private List<Map<String, Object>> loadStaffComplaints(Connection conn, int limit) throws SQLException {
        List<Map<String, Object>> results = new ArrayList<>();
        String sql = "SELECT id, staff_username, staff_email, department, complaint_category, complaint_title, "
            + "complaint_details, urgency, status, created_at "
                + "FROM staff_complaints "
            + "ORDER BY created_at DESC, id DESC "
                + "LIMIT ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, Math.max(1, limit));
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id", rs.getLong("id"));
                    row.put("staff_username", rs.getString("staff_username"));
                    row.put("staff_email", rs.getString("staff_email"));
                    row.put("department", rs.getString("department"));
                    row.put("complaint_category", rs.getString("complaint_category"));
                    row.put("complaint_title", rs.getString("complaint_title"));
                    row.put("complaint_details", rs.getString("complaint_details"));
                    row.put("urgency", rs.getString("urgency"));
                    row.put("status", rs.getString("status"));
                    Timestamp createdAt = rs.getTimestamp("created_at");
                    row.put("created_at", createdAt);
                    results.add(row);
                }
            }
        }
        return results;
    }

    private void updateStaffComplaintStatus(Connection conn, Long complaintId, String status) throws SQLException {
        String sql = "UPDATE staff_complaints SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setLong(2, complaintId);
            stmt.executeUpdate();
        }
    }

    private List<Map<String, Object>> filterSensitiveAduanAuditLogs(List<Map<String, Object>> logs) {
        List<Map<String, Object>> filtered = new ArrayList<>();
        if (logs == null || logs.isEmpty()) {
            return filtered;
        }
        for (Map<String, Object> log : logs) {
            String action = String.valueOf(log.get("action") == null ? "" : log.get("action"));
            String details = String.valueOf(log.get("details") == null ? "" : log.get("details"));
            String combined = (action + " " + details).toLowerCase(java.util.Locale.ROOT);
            if (combined.contains("aduan")
                    || combined.contains("staff_complaint")
                    || combined.contains("access_aduan")
                    || combined.contains("update_staff_complaint_status")) {
                continue;
            }
            filtered.add(log);
        }
        return filtered;
    }

    private void loadUserDashboard(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        Map<String, Object> user = DashboardDataService.loadUserSummary(conn, userId);
        for (Map.Entry<String, Object> entry : user.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        int totalApplications = DashboardDataService.countUserApplications(conn, userId);
        int pageSize = 10;
        int page = 1;
        try {
            String pageParam = request.getParameter("appPage");
            if (pageParam != null && !pageParam.isBlank()) {
                page = Math.max(1, Integer.parseInt(pageParam.trim()));
            }
        } catch (NumberFormatException ignored) { }
        int totalPages = (int) Math.ceil((double) totalApplications / pageSize);
        if (totalPages < 1) totalPages = 1;
        if (page > totalPages) page = totalPages;

        request.setAttribute("application_count", totalApplications);
        request.setAttribute("pending_count", DashboardDataService.countPendingUserApplications(conn, userId));
        request.setAttribute("applications", DashboardDataService.loadUserApplicationsPaged(conn, userId, page, pageSize));
        request.setAttribute("current_page", page);
        request.setAttribute("total_pages", totalPages);
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("product_count", DashboardDataService.countProducts(conn, null, null));
        request.setAttribute("account_status", user.get("status"));
        request.setAttribute("last_login", request.getSession(false) != null ? request.getSession(false).getAttribute("login_time") : null);
        request.setAttribute("unread_notification_count", DashboardDataService.countUnreadNotifications(conn, userId));
        Map<String, String> appRuntimeSettings = loadAppRuntimeSettings(conn);
        boolean decisionPopupEnabled = parseBoolean(
            coalesceSmtpValue(appRuntimeSettings.get("user_dashboard_decision_popup_enabled"), "true"),
            true);
        request.setAttribute("user_decision_popup_enabled", decisionPopupEnabled);
        request.setAttribute("user_decision_popup_approve_icon",
            coalesceSmtpValue(appRuntimeSettings.get("user_dashboard_decision_popup_approve_icon"), "/icon/stamp.gif"));
        request.setAttribute("user_decision_popup_reject_icon",
            coalesceSmtpValue(appRuntimeSettings.get("user_dashboard_decision_popup_reject_icon"), "/icon/exit.png"));
        request.setAttribute("user_decision_popup_approve_button_text",
            coalesceSmtpValue(appRuntimeSettings.get("user_dashboard_decision_popup_approve_button_text"), "Lihat Perakuan"));
        Map<String, Object> decisionPopup = decisionPopupEnabled
            ? DashboardDataService.loadLatestUnreadDecisionNotification(conn, userId)
            : null;
        request.setAttribute("decision_popup", decisionPopup);
        Map<String, Object> presentationPopup = DashboardDataService.loadLatestUnreadNotificationByType(conn, userId, "PRESENTATION");
        request.setAttribute("presentation_popup", presentationPopup);
        request.setAttribute("active_presentation_invite", DashboardDataService.loadLatestActivePresentationInviteByUser(conn, userId));
        request.setAttribute("presentation_invite_history", DashboardDataService.loadPresentationInviteHistoryByUser(conn, userId, 40));
        request.setAttribute("notifications", DashboardDataService.loadUserNotifications(conn, userId, 10));
        DashboardDataService.markAllNotificationsRead(conn, userId);
        request.setAttribute("announcements",
            DashboardDataService.loadActiveAnnouncements(conn, HOMEPAGE_ANNOUNCEMENT_LIMIT));
        request.setAttribute("status_history",
            DashboardDataService.loadUserApplicationStatusHistory(conn, userId));

        // Additional applicant metrics
        try {
            int userInProgress = DashboardDataService.countUserApplicationsByStatus(conn, userId, "IN_PROGRESS")
                    + DashboardDataService.countUserApplicationsByStatus(conn, userId, "UNDER_REVIEW");
                int presentationCount = DashboardDataService.countPendingPresentationInvitesByUser(conn, userId);
            int userApproved = DashboardDataService.countUserApplicationsByStatus(conn, userId, "APPROVED");

            request.setAttribute("user_in_progress_count", userInProgress);
            request.setAttribute("presentation_count", presentationCount);
            request.setAttribute("user_approved_count", userApproved);
        } catch (SQLException e) {
            LOGGER.warning("Failed to compute applicant extra metrics: " + e.getMessage());
            request.setAttribute("user_in_progress_count", 0);
            request.setAttribute("presentation_count", 0);
            request.setAttribute("user_approved_count", 0);
        }
    }

    // Simpan respon kehadiran pembentangan dari pemohon (USER portal)
    // kemudian hantar notifikasi kepada semua ADMIN untuk tindakan susulan.
    private void handleUserPresentationResponse(HttpServletRequest request,
            HttpServletResponse response,
            HttpSession session,
            String presentationResponseAction) throws IOException {
        Integer userId = (Integer) session.getAttribute("user_id");
        if (userId == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Long inviteId = parseLong(request.getParameter("presentation_invite_id"));
        if (inviteId == null) {
            response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=invalid");
            return;
        }

        String normalized = presentationResponseAction.trim().toUpperCase(java.util.Locale.ROOT);
        String representativeName = trim(request.getParameter("presentation_rep_name"));
        String attendeeCountRaw = trim(request.getParameter("presentation_attendee_count"));
        String absenceReason = trim(request.getParameter("presentation_absence_reason"));

        Integer attendeeCount = null;
        if (attendeeCountRaw != null && !attendeeCountRaw.isBlank()) {
            try {
                attendeeCount = Integer.parseInt(attendeeCountRaw);
            } catch (NumberFormatException ignored) {
                attendeeCount = null;
            }
        }

        if ("HADIR".equals(normalized)) {
            if (representativeName == null || representativeName.isBlank() || attendeeCount == null || attendeeCount <= 0) {
                response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=missing_hadir");
                return;
            }
        } else if ("TIDAK_HADIR".equals(normalized)) {
            if (absenceReason == null || absenceReason.isBlank()) {
                response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=missing_absence");
                return;
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=invalid");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            boolean updated = DashboardDataService.respondToPresentationInvite(
                    conn,
                    inviteId,
                    userId,
                    normalized,
                    representativeName,
                    attendeeCount,
                    absenceReason);
            if (!updated) {
                response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=not_found");
                return;
            }

            Map<String, Object> invite = DashboardDataService.loadPresentationInviteById(conn, inviteId);
            String appCode = "PPP";
            if (invite != null && invite.get("application_id") instanceof Number) {
                appCode = "PPP" + String.format("%03d", ((Number) invite.get("application_id")).intValue());
            }

            String responseMessage;
                Map<String, String> notifVars = new HashMap<>();
                notifVars.put("app_ref", appCode);
            if ("HADIR".equals(normalized)) {
                notifVars.put("representative_name", representativeName == null ? "-" : representativeName);
                notifVars.put("attendee_count", String.valueOf(attendeeCount));
                responseMessage = TemplateService.renderNotif(
                    conn,
                    "NOTIF_PRESENTATION_RESPONSE_ATTEND",
                    notifVars,
                    "Adalah dimaklumkan bahawa pemohon telah mengesahkan kehadiran bagi sesi pembentangan "
                        + appCode + ". Wakil: " + representativeName + ". Bilangan peserta: " + attendeeCount + ".");
            } else {
                String finalAbsenceReason = absenceReason == null || absenceReason.isBlank() ? "-" : absenceReason;
                notifVars.put("absence_reason", finalAbsenceReason);
                responseMessage = TemplateService.renderNotif(
                    conn,
                    "NOTIF_PRESENTATION_RESPONSE_ABSENT",
                    notifVars,
                    "Adalah dimaklumkan bahawa pemohon tidak dapat hadir bagi sesi pembentangan "
                        + appCode + ". Sebab: " + finalAbsenceReason
                        + ". Sila pertimbangkan penjadualan semula.");
            }

            List<Map<String, Object>> adminRecipients = DashboardDataService.loadAdminRecipients(conn);
            for (Map<String, Object> recipient : adminRecipients) {
                Object adminIdObj = recipient.get("id");
                if (!(adminIdObj instanceof Number)) {
                    continue;
                }
                int adminId = ((Number) adminIdObj).intValue();
                DashboardDataService.insertNotification(conn, adminId, responseMessage, "PRESENTATION");
            }

            response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=ok");
        } catch (SQLException e) {
            LOGGER.severe("Failed to save presentation response: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/dashboard?presentation_response=error");
        }
    }

    // Endpoint JSON untuk tindakan "Hantar Email" dalam panel KPP di admin-dashboard.jsp.
    // Fungsi ini sahkan payload, semak SMTP, hantar emel secara berkelompok,
    // dan jadualkan reminder selepas hantar berjaya.
    private void handleKppEmailSend(HttpServletRequest request, HttpServletResponse response, JsonObject requestBody)
            throws IOException {
        response.setContentType("application/json;charset=UTF-8");

        JsonArray emails = requestBody != null && requestBody.has("emails") && requestBody.get("emails").isJsonArray()
                ? requestBody.getAsJsonArray("emails")
                : new JsonArray();
        if (emails.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(jsonMessage(false, "Tiada email KPP untuk dihantar.", 0, 0));
            return;
        }

        SmtpConfig smtpConfig;
        try (Connection smtpConn = DatabaseConfig.getConnection()) {
            smtpConfig = loadSmtpConfig(smtpConn, request);
        } catch (SQLException e) {
            LOGGER.warning("Failed to load SMTP settings for KPP email send: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonMessage(false, "Tetapan SMTP tidak dapat dibaca daripada sistem.", 0, emails.size()));
            return;
        }

        String smtpHost = smtpConfig.host;
        if (smtpHost.isBlank()) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonMessage(false, "SMTP belum dikonfigurasi. Sila isi tetapan email pengirim.", 0, emails.size()));
            return;
        }

        int smtpPort = smtpConfig.port;
        boolean smtpAuth = smtpConfig.auth;
        boolean smtpTls = smtpConfig.tls;
        String smtpUser = smtpConfig.username;
        String smtpPass = smtpConfig.password;
        String smtpFrom = smtpConfig.fromAddress;

        if (isPlaceholderSmtp(smtpHost, smtpUser, smtpPass, smtpFrom)
            || (smtpAuth && (smtpUser.isBlank() || smtpPass.isBlank()))) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(jsonMessage(false,
                "SMTP belum dikonfigurasi dengan betul. Sila semak SMTP host, username, password dan from address.",
                0,
                emails.size()));
            return;
        }

        EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
        int sentCount = 0;
        int failedCount = 0;
        List<SentKppReminderMetadata> sentReminderMetadata = new ArrayList<>();

        for (JsonElement emailElement : emails) {
            if (emailElement == null || !emailElement.isJsonObject()) {
                failedCount++;
                continue;
            }

            JsonObject emailObject = emailElement.getAsJsonObject();
            String to = getJsonString(emailObject, "to");
            String subject = getJsonString(emailObject, "subject");
            String body = getJsonString(emailObject, "body");
            String actionType = getJsonString(emailObject, "actionType");
            String applicationRef = getJsonString(emailObject, "applicationRef");
            String recipientName = getJsonString(emailObject, "recipientName");
            String guestLink = extractFirstUrl(body);

            if (to.isBlank() || subject.isBlank() || body.isBlank()) {
                failedCount++;
                continue;
            }

            // Try to load subject/body from DB template based on actionType
            String kppTemplateKey = resolveKppTemplateKey(actionType);
            if (kppTemplateKey != null) {
                try (Connection tConn = DatabaseConfig.getConnection()) {
                    Map<String, String> kppVars = buildKppTemplateVariables(tConn, applicationRef, recipientName, guestLink);
                    String dbSubject = TemplateService.renderEmailSubject(tConn, kppTemplateKey, kppVars, null);
                    String dbBody    = TemplateService.renderEmailBody(tConn, kppTemplateKey, kppVars, null);
                    if (dbSubject != null && !dbSubject.isBlank()) subject = dbSubject;
                    if (dbBody    != null && !dbBody.isBlank())    body    = dbBody;
                } catch (Exception ex) {
                    LOGGER.warning("Failed to load KPP template " + kppTemplateKey + ": " + ex.getMessage());
                }
            }

            String htmlBody = looksLikeHtml(body) ? body : toHtmlEmailBody(body);
            boolean sent = emailUtil.sendHtml(to, subject, htmlBody);
            if (sent) {
                sentCount++;
                sentReminderMetadata.add(new SentKppReminderMetadata(to, actionType, applicationRef, guestLink, subject));
            } else {
                failedCount++;
            }
        }

        boolean success = sentCount > 0 && failedCount == 0;
        if (sentCount == 0) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            String failureMessage = "Semua email KPP gagal dihantar.";
            if (smtpHost.toLowerCase(java.util.Locale.ROOT).contains("office365")
                    || smtpHost.toLowerCase(java.util.Locale.ROOT).contains("outlook")) {
                failureMessage = "Semua email KPP gagal dihantar. Untuk Outlook/Microsoft 365, pastikan SMTP AUTH diaktifkan pada mailbox dan kelayakan smtp.username/smtp.password adalah betul.";
            }
            response.getWriter().write(jsonMessage(false, failureMessage, sentCount, failedCount));
            return;
        }

        String message = failedCount == 0
                ? ("Berjaya menghantar " + sentCount + " email KPP.")
                : ("Berjaya menghantar " + sentCount + " email KPP. " + failedCount + " email gagal dihantar.");

        HttpSession session = request.getSession(false);
        Integer adminId = session == null ? null : (Integer) session.getAttribute("user_id");
        try (Connection conn = DatabaseConfig.getConnection()) {
                KppReminderService.ensureReminderTable(conn);
                int scheduledCount = 0;
                for (SentKppReminderMetadata metadata : sentReminderMetadata) {
                    scheduledCount += KppReminderService.scheduleReminderSeries(
                            conn,
                            metadata.recipientEmail(),
                            metadata.actionType(),
                            metadata.applicationRef(),
                            metadata.guestLink(),
                            metadata.subject()
                    );
                }
                insertAdminAuditLog(conn, adminId, "SEND KPP EMAIL",
                    "Admin " + DashboardDataService.resolveDisplayUserId(conn, adminId, "ADMIN")
                            + " hantar email KPP. Berjaya: " + sentCount + ", gagal: " + failedCount
                            + ", reminder dijadualkan: " + scheduledCount,
                    request.getRemoteAddr());
        } catch (SQLException e) {
            LOGGER.warning("Failed to write SEND KPP EMAIL audit log: " + e.getMessage());
        }

        response.getWriter().write(jsonMessage(success, message, sentCount, failedCount));
    }

    private static void insertAdminAuditLog(Connection conn, Integer adminId, String action,
            String details, String ip) {
        if (adminId == null) {
            return;
        }
        try {
            DashboardDataService.ensureAuditLogTable(conn);
            String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, adminId);
                ps.setString(2, action);
                ps.setString(3, details);
                ps.setString(4, ip);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to write audit log [" + action + "]: " + e.getMessage());
        }
    }

    private static void notifyAdminUsers(Connection conn, String message, String type) {
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT id FROM users WHERE role = 'ADMIN'")) {
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    int adminId = rs.getInt("id");
                    DashboardDataService.insertNotification(conn, adminId, message, type);
                }
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to notify admin users: " + e.getMessage());
        }
    }

    // Proses tindakan Pengarah (Terima/Tolak/Gantung/Batal) dari dashboard Pengarah.
    // Dipanggil dari doPost apabila parameter director_action diterima.
    public static void processDirectorAction(HttpServletRequest request, HttpServletResponse response,
            HttpSession session, String directorAction, String redirectLocation) throws IOException {
        if (!"accept_application".equalsIgnoreCase(directorAction)
                && !"reject_application".equalsIgnoreCase(directorAction)
                && !"suspend_application".equalsIgnoreCase(directorAction)
                && !"cancel_application".equalsIgnoreCase(directorAction)) {
            response.sendRedirect(request.getContextPath() + redirectLocation);
            return;
        }

        Integer directorId = (Integer) session.getAttribute("user_id");
        Integer applicationId = parseInteger(request.getParameter("application_id"));
        if (applicationId == null) {
            LOGGER.warning("Director action rejected: missing application_id for action=" + directorAction);
            response.sendRedirect(buildRedirectUrl(request, redirectLocation, "director_error=missing_application"));
            return;
        }

        LOGGER.info("Director action request received: action=" + directorAction + ", applicationId=" + applicationId + ", directorId=" + directorId);

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureApplicationWorkflowSchema(conn);
            String lockSql = "SELECT status, reviewed_by, director_review_type, user_id FROM applications WHERE id = ? LIMIT 1";
            String currentStatus = null;
            Integer reviewedBy = null;
            String directorReviewType = null;
            Integer applicantUserId = null;
            try (PreparedStatement lockStmt = conn.prepareStatement(lockSql)) {
                lockStmt.setInt(1, applicationId);
                try (ResultSet rs = lockStmt.executeQuery()) {
                    if (rs.next()) {
                        currentStatus = rs.getString("status");
                        reviewedBy = (Integer) rs.getObject("reviewed_by");
                        directorReviewType = rs.getString("director_review_type");
                        Object uid = rs.getObject("user_id");
                        if (uid != null) applicantUserId = rs.getInt("user_id");
                    }
                }
            }

            if (!"MENUNGGU_TINDAKAN_PENGARAH".equalsIgnoreCase(currentStatus)) {
                LOGGER.warning("Director action rejected: applicationId=" + applicationId + " currentStatus=" + currentStatus + ", reviewedBy=" + reviewedBy);
                response.sendRedirect(buildRedirectUrl(request, redirectLocation, "director_error=invalid_state"));
                return;
            }

            String directorNotes = trim(request.getParameter("director_notes"));
                boolean requiresNotes = "reject_application".equalsIgnoreCase(directorAction)
                    || "suspend_application".equalsIgnoreCase(directorAction)
                    || "cancel_application".equalsIgnoreCase(directorAction)
                    || "query_application".equalsIgnoreCase(directorAction);
            if (requiresNotes && (directorNotes == null || directorNotes.isBlank())) {
                response.sendRedirect(buildRedirectUrl(request, redirectLocation, "director_error=missing_notes"));
                return;
            }

            boolean isFinalReview = "FINAL".equalsIgnoreCase(directorReviewType);
            String appRef = "PPP" + String.format("%03d", applicationId);

            String nextStatus;
            String resultKey;
            String statusHistoryNote;
            String auditAction;
            String auditText;
            boolean notifyAdmin;

            if ("accept_application".equalsIgnoreCase(directorAction)) {
                if (isFinalReview) {
                    // Scenario 2 - Lulus: permohonan kembali ke Dashboard Admin untuk pengeluaran sijil
                    nextStatus = "MENUNGGU_SETERUSNYA_DILULUSKAN";
                    resultKey = "final_approved";
                    statusHistoryNote = "Diluluskan oleh Pengarah (Keputusan Akhir). Menunggu tindakan Admin untuk pengeluaran sijil.";
                    auditAction = "DIRECTOR FINAL APPROVE APPLICATION";
                    auditText = "lulus (keputusan akhir)";
                } else {
                    // Scenario 1 - Terima: jana ID permohonan, hantar ke Dashboard Admin
                    nextStatus = "DILULUSKAN_PENGARAH";
                    resultKey = "initial_accepted";
                    statusHistoryNote = "Diluluskan Pengarah (Semakan Awal). ID Permohonan: " + appRef + ". Dihantar ke Dashboard Admin.";
                    auditAction = "DIRECTOR ACCEPT APPLICATION";
                    auditText = "terima (semakan awal)";
                }
                notifyAdmin = true;
            } else if ("reject_application".equalsIgnoreCase(directorAction)) {
                nextStatus = "REJECTED";
                resultKey = isFinalReview ? "final_rejected" : "initial_rejected";
                statusHistoryNote = (isFinalReview ? "Digagalkan oleh Pengarah (Keputusan Akhir). Dimaklumkan kepada pemohon."
                        : "Ditolak oleh Pengarah (Semakan Awal).") + " Ulasan: " + directorNotes;
                auditAction = isFinalReview ? "DIRECTOR FINAL REJECT APPLICATION" : "DIRECTOR REJECT APPLICATION";
                auditText = "gagal";
                notifyAdmin = false;
            } else if ("suspend_application".equalsIgnoreCase(directorAction)) {
                nextStatus = "SUSPENDED";
                resultKey = isFinalReview ? "final_suspended" : "initial_suspended";
                statusHistoryNote = (isFinalReview ? "Digantung oleh Pengarah (Keputusan Akhir). Dimaklumkan kepada pemohon."
                        : "Digantung oleh Pengarah (Semakan Awal).") + " Ulasan: " + directorNotes;
                auditAction = isFinalReview ? "DIRECTOR FINAL SUSPEND APPLICATION" : "DIRECTOR SUSPEND APPLICATION";
                auditText = "gantung";
                notifyAdmin = false;
            } else if ("query_application".equalsIgnoreCase(directorAction)) {
                nextStatus = "KUERI";
                resultKey = isFinalReview ? "final_queried" : "initial_queried";
                statusHistoryNote = (isFinalReview ? "Dikuiri oleh Pengarah (Keputusan Akhir). Dimaklumkan kepada pemohon untuk tindakan lanjut."
                        : "Dikuiri oleh Pengarah (Semakan Awal).") + " Ulasan: " + directorNotes;
                auditAction = isFinalReview ? "DIRECTOR FINAL QUERY APPLICATION" : "DIRECTOR QUERY APPLICATION";
                auditText = "kuiri";
                notifyAdmin = false;
            } else {
                // cancel_application
                nextStatus = "ARCHIVED";
                resultKey = isFinalReview ? "final_cancelled" : "initial_cancelled";
                statusHistoryNote = (isFinalReview ? "Dibatalkan oleh Pengarah (Keputusan Akhir). Dimaklumkan kepada pemohon."
                        : "Dibatalkan oleh Pengarah (Semakan Awal).") + " Ulasan: " + directorNotes;
                auditAction = isFinalReview ? "DIRECTOR FINAL CANCEL APPLICATION" : "DIRECTOR CANCEL APPLICATION";
                auditText = "batal";
                notifyAdmin = false;
            }

            String updateSql = "UPDATE applications SET status = ?, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = ?, admin_notes = ? WHERE id = ? AND UPPER(TRIM(status)) = 'MENUNGGU_TINDAKAN_PENGARAH'";
            try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                updateStmt.setString(1, nextStatus);
                updateStmt.setInt(2, directorId);
                updateStmt.setString(3, directorNotes);
                updateStmt.setInt(4, applicationId);
                int updatedRows = updateStmt.executeUpdate();
                if (updatedRows != 1) {
                    throw new SQLException("Expected to update 1 application row but updated " + updatedRows);
                }
            }

            DashboardDataService.recordStatusHistory(conn, applicationId, currentStatus, nextStatus, directorId, statusHistoryNote);

            String directorDisplayId = DashboardDataService.resolveDisplayUserId(conn, directorId, "DIRECTOR");
            insertAdminAuditLog(
                    conn,
                    directorId,
                    auditAction,
                    "Pengarah " + directorDisplayId + " " + auditText + " permohonan " + appRef + ". " + (directorNotes == null ? "" : directorNotes),
                    request.getRemoteAddr());

            if (notifyAdmin) {
                Map<String, String> adminNotifVars = new HashMap<>();
                adminNotifVars.put("app_ref", appRef);
                String adminFallback;
                if ("MENUNGGU_SETERUSNYA_DILULUSKAN".equals(nextStatus)) {
                    adminNotifVars.put("next_step", "Sila teruskan tindakan akhir bagi pengeluaran sijil melalui dashboard Admin.");
                    adminFallback = "Adalah dimaklumkan bahawa keputusan akhir Pengarah bagi permohonan "
                            + appRef + " telah direkodkan. Sila teruskan tindakan akhir bagi pengeluaran sijil melalui dashboard Admin.";
                } else {
                    adminNotifVars.put("next_step", "Permohonan kini berada dalam semakan Admin untuk tindakan lanjut.");
                    adminFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                            + " telah diterima oleh Pengarah dan kini berada dalam semakan Admin untuk tindakan lanjut.";
                }
                String notifMsg = isFinalReview
                        ? TemplateService.renderNotif(conn, "NOTIF_DIRECTOR_DECISION",
                                adminNotifVars, adminFallback)
                        : TemplateService.renderNotif(conn, "NOTIF_DIRECTOR_ACCEPT",
                                adminNotifVars, adminFallback);
                notifyAdminUsers(conn, notifMsg, "INFO");
            }

            if (applicantUserId != null) {
                // Notify applicant dashboard
                String applicantFallback;
                if ("DILULUSKAN_PENGARAH".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " telah diluluskan oleh Pengarah dan dihantar kepada Admin untuk semakan seterusnya.";
                } else if ("MENUNGGU_SETERUSNYA_DILULUSKAN".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " telah diluluskan oleh Pengarah dan kini menunggu tindakan akhir Admin.";
                } else if ("REJECTED".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " tidak diluluskan oleh Pengarah. Sila semak dashboard untuk ulasan keputusan.";
                } else if ("SUSPENDED".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " telah digantung oleh Pengarah. Sila semak dashboard untuk ulasan keputusan.";
                } else if ("KUERI".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " telah dikuiri oleh Pengarah. Sila semak ulasan dan kemas kini permohonan anda melalui dashboard.";
                } else if ("ARCHIVED".equals(nextStatus)) {
                    applicantFallback = "Adalah dimaklumkan bahawa permohonan " + appRef
                        + " telah dibatalkan oleh Pengarah. Sila semak dashboard untuk ulasan keputusan.";
                } else {
                    applicantFallback = "Adalah dimaklumkan bahawa status permohonan " + appRef
                        + " telah dikemas kini oleh Pengarah. Sila semak dashboard untuk status terkini.";
                }

                Map<String, String> applicantNotifVars = new HashMap<>();
                applicantNotifVars.put("app_ref", appRef);
                applicantNotifVars.put("next_step", applicantFallback.replaceFirst("^Adalah dimaklumkan bahawa ", ""));
                String applicantNotifMsg = TemplateService.renderNotif(conn, "NOTIF_DIRECTOR_DECISION",
                    applicantNotifVars, applicantFallback);
                try {
                    DashboardDataService.insertNotification(conn, applicantUserId, applicantNotifMsg, "INFO");
                } catch (Exception notifEx) {
                    LOGGER.warning("Failed to insert applicant notification for " + appRef + ": " + notifEx.getMessage());
                }
                // Send email to applicant
                sendApplicantStatusEmailForDirectorAction(request, conn, applicationId, nextStatus, directorNotes, appRef);
            }

            response.sendRedirect(buildRedirectUrl(request, redirectLocation, "director_updated=1&director_result=" + resultKey));
            return;
        } catch (SQLException ex) {
            LOGGER.warning("Failed to process director action: " + ex.getMessage());
            response.sendRedirect(buildRedirectUrl(request, redirectLocation, "director_error=save_failed"));
            return;
        }
    }

    private static void sendApplicantStatusEmailForDirectorAction(
            HttpServletRequest request, Connection conn, int applicationId,
            String newStatus, String directorNotes, String appRef) {
        try {
            // Load SMTP settings from DB then fall back to context params
            String smtpHostDb = null, smtpPortDb = null, smtpAuthDb = null, smtpTlsDb = null;
            String smtpUserDb = null, smtpPassDb = null, smtpFromDb = null;
            try (PreparedStatement sp = conn.prepareStatement(
                    "SELECT setting_key, setting_value FROM smtp_settings WHERE enabled = 1");
                 ResultSet srs = sp.executeQuery()) {
                while (srs.next()) {
                    String key = srs.getString("setting_key");
                    String val = srs.getString("setting_value");
                    if (val == null || val.isBlank()) continue;
                    switch (key) {
                        case "smtp_host":     smtpHostDb = val; break;
                        case "smtp_port":     smtpPortDb = val; break;
                        case "smtp_auth":     smtpAuthDb = val; break;
                        case "smtp_tls":      smtpTlsDb  = val; break;
                        case "smtp_username": smtpUserDb = val; break;
                        case "smtp_password": smtpPassDb = val; break;
                        case "smtp_from":     smtpFromDb = val; break;
                        default: break;
                    }
                }
            } catch (Exception ignore) { /* smtp_settings table may not have been created yet */ }

            jakarta.servlet.ServletContext ctx = request.getServletContext();
            String smtpHost = (smtpHostDb != null) ? smtpHostDb : ctx.getInitParameter("smtp.host");
            if (smtpHost == null || smtpHost.isBlank()) {
                LOGGER.info("Applicant email skipped: SMTP host not configured.");
                return;
            }
            int smtpPort = 587;
            try { smtpPort = Integer.parseInt(smtpPortDb != null ? smtpPortDb : ctx.getInitParameter("smtp.port")); }
            catch (Exception ignored) { /* use default */ }
            boolean smtpAuth = Boolean.parseBoolean(smtpAuthDb != null ? smtpAuthDb : "true");
            boolean smtpTls  = Boolean.parseBoolean(smtpTlsDb  != null ? smtpTlsDb  : "true");
            String smtpUser  = smtpUserDb != null ? smtpUserDb : ctx.getInitParameter("smtp.username");
            String smtpPass  = smtpPassDb != null ? smtpPassDb : ctx.getInitParameter("smtp.password");
            String smtpFrom  = smtpFromDb != null ? smtpFromDb : smtpUser;
            if (smtpUser == null) smtpUser = "";
            if (smtpPass == null) smtpPass = "";
            if (smtpFrom == null || smtpFrom.isBlank()) smtpFrom = smtpUser;

            // Load applicant info
            String applicantEmail = null, applicantName = null, productName = null;
            try (PreparedStatement ap = conn.prepareStatement(
                    "SELECT u.email, u.full_name, a.product_name FROM applications a "
                    + "JOIN users u ON u.id = a.user_id WHERE a.id = ? LIMIT 1")) {
                ap.setInt(1, applicationId);
                try (ResultSet ars = ap.executeQuery()) {
                    if (ars.next()) {
                        applicantEmail = ars.getString("email");
                        applicantName  = ars.getString("full_name");
                        productName    = ars.getString("product_name");
                    }
                }
            }
            if (applicantEmail == null || applicantEmail.isBlank()) return;

            String notes = (directorNotes != null && !directorNotes.isBlank())
                    ? "<p><strong>Catatan:</strong> " + directorNotes + "</p>" : "";
            String templateKey;
            String fallbackSubject;
            String fallbackBody;
            if ("DILULUSKAN_PENGARAH".equals(newStatus)) {
                templateKey = "APPLICATION_UNDER_REVIEW";
                fallbackSubject = "Permohonan " + appRef + " - Diluluskan Pengarah";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") telah <strong>diluluskan oleh Pengarah</strong> dan kini dihantar kepada Admin untuk semakan seterusnya.</p>"
                        + "<p>Anda akan dimaklumkan semula selepas keputusan berikutnya dibuat.</p>";
            } else if ("MENUNGGU_SETERUSNYA_DILULUSKAN".equals(newStatus)) {
                templateKey = "APPLICATION_UNDER_REVIEW";
                fallbackSubject = "Permohonan " + appRef + " - Keputusan Akhir Pengarah";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") telah <strong>diluluskan oleh Pengarah (keputusan akhir)</strong> dan menunggu tindakan akhir Admin.</p>"
                        + "<p>Anda akan dimaklumkan sebaik sahaja proses pengeluaran sijil selesai.</p>";
            } else if ("REJECTED".equals(newStatus)) {
                templateKey = "APPLICATION_REJECTED";
                fallbackSubject = "Permohonan " + appRef + " - Tidak Berjaya";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") telah <strong>ditolak</strong> oleh Pengarah.</p>"
                        + notes + "<p>Hubungi kami untuk maklumat lanjut.</p>";
            } else if ("SUSPENDED".equals(newStatus)) {
                templateKey = "APPLICATION_SUSPENDED";
                fallbackSubject = "Permohonan " + appRef + " - Digantung";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") telah <strong>digantung</strong> oleh Pengarah.</p>"
                        + notes + "<p>Hubungi kami untuk maklumat lanjut.</p>";
            } else if ("KUERI".equals(newStatus)) {
                templateKey = "APPLICATION_UNDER_REVIEW";
                fallbackSubject = "Permohonan " + appRef + " - Kuiri Pengarah";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") memerlukan <strong>maklum balas lanjut</strong> daripada anda.</p>"
                        + notes + "<p>Sila semak dashboard pemohon anda untuk tindakan lanjut.</p>";
            } else {
                templateKey = "APPLICATION_ARCHIVED";
                fallbackSubject = "Permohonan " + appRef + " - Dibatalkan";
                fallbackBody = "<p>Salam " + (applicantName != null ? applicantName : "Pemohon") + ",</p>"
                        + "<p>Permohonan <strong>" + appRef + "</strong> ("
                        + (productName != null ? productName : "") + ") telah <strong>dibatalkan</strong> oleh Pengarah.</p>"
                        + notes + "<p>Hubungi kami untuk maklumat lanjut.</p>";
            }

            java.util.Map<String, String> vars = new java.util.HashMap<>();
            vars.put("app_ref", appRef);
            vars.put("applicant_name", applicantName != null ? applicantName : "");
            vars.put("product_name", productName != null ? productName : "");
            vars.put("admin_notes", directorNotes != null ? directorNotes : "");
            String emailSubject = TemplateService.renderEmailSubject(conn, templateKey, vars, fallbackSubject);
            String emailBody    = TemplateService.renderEmailBody(conn, templateKey, vars, fallbackBody);

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            emailUtil.sendHtml(applicantEmail, emailSubject, emailBody);
        } catch (Exception ex) {
            LOGGER.warning("Failed to send applicant email for director action on application #" + applicationId + ": " + ex.getMessage());
        }
    }

    private static String buildRedirectUrl(HttpServletRequest request, String base, String queryString) {
        if (base == null || base.isBlank()) {
            base = "/dashboard";
        }
        String target = request.getContextPath() + base;
        if (queryString != null && !queryString.isBlank()) {
            target += base.contains("?") ? "&" : "?";
            target += queryString;
        }
        return target;
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }

    private boolean validateUserPassword(Connection conn, Integer userId, String inputPassword) throws SQLException {
        if (conn == null || userId == null || inputPassword == null || inputPassword.isBlank()) {
            return false;
        }

        String sql = "SELECT password_hash FROM users WHERE id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                String storedPassword = rs.getString("password_hash");
                return passwordMatches(inputPassword, storedPassword);
            }
        }
    }

    private boolean passwordMatches(String inputPassword, String storedPassword) {
        if (storedPassword == null || storedPassword.isBlank()) {
            return false;
        }
        if (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$")) {
            String normalizedHash = storedPassword.replaceFirst("^\\$2[by]\\$", "\\$2a\\$");
            try {
                return BCrypt.checkpw(inputPassword, normalizedHash);
            } catch (IllegalArgumentException e) {
                LOGGER.warning("BCrypt check failed (invalid hash format): " + e.getMessage());
                return false;
            }
        }

        String hashedInput = sha256Hex(inputPassword);
        return storedPassword.equalsIgnoreCase(hashedInput) || storedPassword.equals(inputPassword);
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                String part = Integer.toHexString(0xff & b);
                if (part.length() == 1) {
                    hex.append('0');
                }
                hex.append(part);
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    }

    private JsonObject parseJsonRequestBody(HttpServletRequest request) throws IOException {
        String body = request.getReader().lines().collect(java.util.stream.Collectors.joining());
        if (body == null || body.isBlank()) {
            return new JsonObject();
        }

        try {
            JsonElement root = JsonParser.parseString(body);
            if (root != null && root.isJsonObject()) {
                return root.getAsJsonObject();
            }
        } catch (Exception ignored) {
            // Fall through to empty object.
        }
        return new JsonObject();
    }

    private String getJsonString(JsonObject object, String key) {
        if (object == null || key == null || key.isBlank() || !object.has(key)) {
            return "";
        }

        JsonElement element = object.get(key);
        if (element == null || element.isJsonNull()) {
            return "";
        }

        String value = element.isJsonPrimitive() ? element.getAsString() : element.toString();
        return value == null ? "" : value.trim();
    }

    private String toHtmlEmailBody(String plainText) {
        String normalized = plainText == null ? "" : plainText;
        normalized = normalized.replace("\r\n", "\n").replace("\r", "\n").trim();

        // Extract URLs first before escaping
        Pattern urlPattern = Pattern.compile("(https?://\\S+)", Pattern.CASE_INSENSITIVE);
        Matcher matcher = urlPattern.matcher(normalized);
        Map<String, String> links = new LinkedHashMap<>();
        StringBuffer marked = new StringBuffer();
        int index = 0;
        while (matcher.find()) {
            String rawUrl = matcher.group(1);
            String cleanedUrl = trimTrailingUrlPunctuation(rawUrl);
            String suffix = rawUrl.substring(cleanedUrl.length());
            String key = "__SPPA_LINK_" + index++ + "__";
            links.put(key, cleanedUrl);
            matcher.appendReplacement(marked, Matcher.quoteReplacement(key + suffix));
        }
        matcher.appendTail(marked);
        String textWithMarkedLinks = marked.toString();

        // Split into paragraphs and wrap each in <p> tags
        String[] paragraphs = textWithMarkedLinks.split("\\n\\s*\\n");
        StringBuilder html = new StringBuilder();
        for (String paragraph : paragraphs) {
            String text = paragraph == null ? "" : paragraph.trim();
            if (text.isEmpty()) {
                continue;
            }
            if (html.length() > 0) {
                html.append("\n");
            }
            // Escape HTML but preserve paragraph structure
            String escaped = escapeHtml(text);
            // Handle line breaks within paragraph (convert \n to <br>)
            String withBr = escaped.replace("\n", "<br>");
            html.append("<p>")
                    .append(withBr)
                    .append("</p>");
        }

        // Replace marked links with actual HTML anchors
        String result = html.toString();
        for (Map.Entry<String, String> entry : links.entrySet()) {
            String url = entry.getValue();
            String escapedUrl = escapeHtml(url);
            String anchor = "<a href=\"" + escapedUrl + "\" target=\"_blank\" rel=\"noopener noreferrer\">Klik Di Sini</a>";
            result = result.replace(entry.getKey(), anchor);
        }

        return "<div style=\"font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:14px;line-height:1.6;color:#183244;\">"
                + result
                + "</div>";
    }

    private Map<String, String> buildKppTemplateVariables(Connection conn,
            String applicationRef,
            String recipientName,
            String guestLink) throws SQLException {
        Map<String, String> vars = new LinkedHashMap<>();
        vars.put("recipient_name", recipientName == null || recipientName.isBlank() ? "tuan/puan" : escapeHtml(recipientName));
        vars.put("application", applicationRef == null ? "" : escapeHtml(applicationRef));
        vars.put("link", guestLink == null ? "" : escapeHtml(guestLink));
        vars.put("link_html", buildHtmlLink(guestLink, "Klik di sini"));
        vars.put("no_rujukan_surat", applicationRef == null ? "" : escapeHtml(applicationRef));
        vars.put("tarikh_surat", "-");
        vars.put("applicant_name", "-");
        vars.put("product_name", "-");
        vars.put("brand", "-");
        vars.put("presentation_date", "-");
        vars.put("application_type_label", "BAHARU");
        vars.put("application_type_label_lower", "baharu");

        Integer applicationId = extractApplicationIdFromReference(applicationRef);
        if (applicationId == null) {
            return vars;
        }

        String sql = "SELECT u.full_name, a.product_name, a.product_description, "
                + "DATE_FORMAT(a.submitted_at, '%d/%m/%Y') AS letter_date, "
                + "COALESCE(ad.application_type, 'BAHARU') AS application_type "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String productSummary = rs.getString("product_description");
                    vars.put("tarikh_surat", escapeHtml(rs.getString("letter_date")));
                    vars.put("applicant_name", escapeHtml(rs.getString("full_name")));
                    vars.put("product_name", escapeHtml(rs.getString("product_name")));
                    vars.put("brand", escapeHtml(extractSummaryField(productSummary, "Jenama:")));
                    String applicationTypeLabel = normalizeApplicationTypeLabel(rs.getString("application_type"));
                    vars.put("application_type_label", escapeHtml(applicationTypeLabel));
                    vars.put("application_type_label_lower", escapeHtml(applicationTypeLabel.toLowerCase(java.util.Locale.forLanguageTag("ms-MY"))));
                }
            }
        }

        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT DATE_FORMAT(presentation_date, '%d/%m/%Y') AS presentation_date "
                        + "FROM presentation_invites WHERE application_id = ? ORDER BY updated_at DESC, id DESC LIMIT 1")) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String date = rs.getString("presentation_date");
                    if (date != null && !date.isBlank()) {
                        vars.put("presentation_date", escapeHtml(date));
                    }
                }
            }
        }

        return vars;
    }

    private Integer extractApplicationIdFromReference(String applicationRef) {
        if (applicationRef == null || applicationRef.isBlank()) {
            return null;
        }
        String normalized = applicationRef.trim().toUpperCase(java.util.Locale.ROOT);
        if (!normalized.startsWith("PPP")) {
            return null;
        }
        try {
            return Integer.parseInt(normalized.substring(3));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String normalizeApplicationTypeLabel(String applicationType) {
        String normalized = applicationType == null ? "" : applicationType.trim().toUpperCase(java.util.Locale.ROOT);
        if ("PEMBAHARUAN".equals(normalized)) {
            return "PEMBAHARUAN";
        }
        if ("KEMASKINI".equals(normalized)) {
            return "KEMASKINI PERMOHONAN";
        }
        return "BAHARU";
    }

    private String extractSummaryField(String summary, String label) {
        if (summary == null || summary.isBlank() || label == null || label.isBlank()) {
            return "-";
        }
        int start = summary.indexOf(label);
        if (start < 0) {
            return "-";
        }
        String remainder = summary.substring(start + label.length()).trim();
        int separator = remainder.indexOf("|");
        String value = separator >= 0 ? remainder.substring(0, separator) : remainder;
        value = value.trim();
        return value.isEmpty() ? "-" : value;
    }

    private String buildHtmlLink(String url, String label) {
        if (url == null || url.isBlank()) {
            return escapeHtml(label == null ? "Klik di sini" : label);
        }
        String safeLabel = escapeHtml(label == null || label.isBlank() ? "Klik di sini" : label);
        return "<a href=\"" + escapeHtml(url) + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + safeLabel + "</a>";
    }

    private boolean looksLikeHtml(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        String normalized = text.toLowerCase(java.util.Locale.ROOT);
        return normalized.contains("<p")
                || normalized.contains("<br")
                || normalized.contains("<div")
                || normalized.contains("<a ")
                || normalized.contains("<strong")
                || normalized.contains("<ul")
                || normalized.contains("<ol")
                || normalized.contains("<table");
    }

    private String resolveKppTemplateKey(String actionType) {
        if (actionType == null || actionType.isBlank()) return null;
        switch (actionType.trim().toUpperCase(java.util.Locale.ROOT)) {
            case "KSPP":            return "KPP_TINDAKAN_KSPP";
            case "UJPPP":           return "KPP_TINDAKAN_UJPPP";
            case "KSPP_UJPPP":      return "KPP_TINDAKAN_KSPP_UJPPP";
            case "SIASATAN_ADUAN":  return "KPP_TINDAKAN_SIASATAN_ADUAN";
            default:                return null;
        }
    }

    private String trimTrailingUrlPunctuation(String url) {
        if (url == null) {
            return "";
        }
        int end = url.length();
        while (end > 0) {
            char c = url.charAt(end - 1);
            if (c == '.' || c == ',' || c == ';' || c == ')' || c == ']' || c == '!' || c == '?') {
                end--;
                continue;
            }
            break;
        }
        return end <= 0 ? url : url.substring(0, end);
    }

    private String extractFirstUrl(String text) {
        if (text == null || text.isBlank()) {
            return "";
        }
        Pattern urlPattern = Pattern.compile("(https?://\\S+)", Pattern.CASE_INSENSITIVE);
        Matcher matcher = urlPattern.matcher(text);
        if (!matcher.find()) {
            return "";
        }
        return trimTrailingUrlPunctuation(matcher.group(1));
    }

    private String jsonMessage(boolean success, String message, int sentCount, int failedCount) {
        JsonObject result = new JsonObject();
        result.addProperty("success", success);
        result.addProperty("message", message == null ? "" : message);
        result.addProperty("sentCount", sentCount);
        result.addProperty("failedCount", failedCount);
        return result.toString();
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private String coalesceSmtpValue(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null ? "" : fallback.trim();
    }

    private boolean parseBoolean(String raw, boolean defaultValue) {
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        String normalized = raw.trim().toLowerCase(java.util.Locale.ROOT);
        if ("true".equals(normalized) || "1".equals(normalized) || "yes".equals(normalized) || "on".equals(normalized)) {
            return true;
        }
        if ("false".equals(normalized) || "0".equals(normalized) || "no".equals(normalized) || "off".equals(normalized)) {
            return false;
        }
        return defaultValue;
    }

    private int parsePositiveIntOrDefault(String raw, int defaultValue) {
        Integer parsed = parseInteger(raw);
        if (parsed == null || parsed <= 0) {
            return defaultValue;
        }
        return parsed;
    }

    private SmtpConfig loadSmtpConfig(Connection conn, HttpServletRequest request) throws SQLException {
        Map<String, String> smtpSettings = loadSmtpSettings(conn);
        String host = coalesceSmtpValue(smtpSettings.get("smtp_host"), getContextParam(request, "smtp.host", ""));
        int port = parsePositiveIntOrDefault(
                coalesceSmtpValue(smtpSettings.get("smtp_port"), getContextParam(request, "smtp.port", "587")),
                587);
        boolean auth = parseBoolean(
                coalesceSmtpValue(smtpSettings.get("smtp_auth"), getContextParam(request, "smtp.auth", "true")),
                true);
        boolean tls = parseBoolean(
                coalesceSmtpValue(smtpSettings.get("smtp_tls"), getContextParam(request, "smtp.tls", "true")),
                true);
        String username = coalesceSmtpValue(smtpSettings.get("smtp_username"), getContextParam(request, "smtp.username", ""));
        String password = coalesceSmtpValue(smtpSettings.get("smtp_password"), getContextParam(request, "smtp.password", ""));
        String fromAddress = coalesceSmtpValue(smtpSettings.get("smtp_from"), getContextParam(request, "smtp.from", username));
        if (fromAddress.isBlank()) {
            fromAddress = username;
        }
        return new SmtpConfig(host, port, username, password, fromAddress, auth, tls);
    }

    // Ambil tetapan SMTP aktif dari DB supaya penghantaran emel ikut konfigurasi semasa admin.
    private Map<String, String> loadSmtpSettings(Connection conn) throws SQLException {
        ensureSmtpSettingsTable(conn);
        Map<String, String> settings = new LinkedHashMap<>();
        String sql = "SELECT setting_key, setting_value FROM smtp_settings WHERE enabled = 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                String key = rs.getString("setting_key");
                String value = rs.getString("setting_value");
                if (key != null && !key.isBlank()) {
                    settings.put(key.trim(), value == null ? "" : value.trim());
                }
            }
        }
        return settings;
    }

    private Map<String, String> loadAppRuntimeSettings(Connection conn) throws SQLException {
        ensureAppRuntimeSettingsTable(conn);
        Map<String, String> settings = new LinkedHashMap<>();
        String sql = "SELECT setting_key, setting_value FROM app_runtime_settings WHERE enabled = 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                String key = rs.getString("setting_key");
                String value = rs.getString("setting_value");
                if (key != null && !key.isBlank()) {
                    settings.put(key.trim(), value == null ? "" : value.trim());
                }
            }
        }
        return settings;
    }

    private void ensureSmtpSettingsTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS smtp_settings ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "setting_key VARCHAR(100) NOT NULL,"
                + "setting_value VARCHAR(255) NOT NULL,"
                + "enabled TINYINT(1) NOT NULL DEFAULT 1,"
                + "description VARCHAR(255),"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_smtp_setting_key (setting_key),"
                + "INDEX idx_smtp_enabled (enabled)"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.execute();
        }
    }

    private void ensureAppRuntimeSettingsTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS app_runtime_settings ("
                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                + "setting_key VARCHAR(100) NOT NULL,"
                + "setting_value VARCHAR(255) NOT NULL,"
                + "enabled TINYINT(1) NOT NULL DEFAULT 1,"
                + "description VARCHAR(255),"
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                + "UNIQUE KEY uniq_app_runtime_setting_key (setting_key),"
                + "INDEX idx_app_runtime_enabled (enabled)"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.execute();
        }
    }

    private void upsertSmtpSetting(Connection conn, String key, String value, String description) throws SQLException {
        String sql = "INSERT INTO smtp_settings (setting_key, setting_value, enabled, description) "
                + "VALUES (?, ?, 1, ?) "
                + "ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), enabled = 1, "
                + "description = VALUES(description), updated_at = CURRENT_TIMESTAMP";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, key);
            stmt.setString(2, value == null ? "" : value);
            stmt.setString(3, description);
            stmt.executeUpdate();
        }
    }

    private static final class SmtpConfig {
        private final String host;
        private final int port;
        private final String username;
        private final String password;
        private final String fromAddress;
        private final boolean auth;
        private final boolean tls;

        private SmtpConfig(String host, int port, String username, String password,
                String fromAddress, boolean auth, boolean tls) {
            this.host = host == null ? "" : host;
            this.port = port;
            this.username = username == null ? "" : username;
            this.password = password == null ? "" : password;
            this.fromAddress = fromAddress == null ? "" : fromAddress;
            this.auth = auth;
            this.tls = tls;
        }
    }

    private String normalizeEmailTemplateBodyForAdminInput(String body) {
        if (body == null) {
            return "";
        }

        String normalized = body.replace("\r\n", "\n").replace("\r", "\n").trim();
        if (normalized.isEmpty() || containsHtmlTag(normalized)) {
            return normalized;
        }

        String[] paragraphs = normalized.split("\\n\\s*\\n");
        StringBuilder html = new StringBuilder();
        for (String paragraph : paragraphs) {
            String text = paragraph == null ? "" : paragraph.trim();
            if (text.isEmpty()) {
                continue;
            }
            if (html.length() > 0) {
                html.append("\n");
            }
            html.append("<p>")
                    .append(escapeHtml(text).replace("\n", "<br>"))
                    .append("</p>");
        }

        return html.length() == 0 ? normalized : html.toString();
    }

    private boolean containsHtmlTag(String value) {
        if (value == null || value.isBlank()) {
            return false;
        }
        return value.matches("(?s).*<\\s*/?\\s*[a-zA-Z][^>]*>.*");
    }

    private String escapeHtml(String text) {
        if (text == null) {
            return "";
        }
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private boolean isPlaceholderSmtp(String smtpHost, String smtpUser, String smtpPass, String smtpFrom) {
        String host = smtpHost == null ? "" : smtpHost.trim().toLowerCase(java.util.Locale.ROOT);
        String user = smtpUser == null ? "" : smtpUser.trim().toLowerCase(java.util.Locale.ROOT);
        String pass = smtpPass == null ? "" : smtpPass.trim().toLowerCase(java.util.Locale.ROOT);
        String from = smtpFrom == null ? "" : smtpFrom.trim().toLowerCase(java.util.Locale.ROOT);

        return host.contains("example")
                || user.contains("your-email")
                || pass.contains("your-app-password")
            || pass.contains("change_me")
                || from.contains("your-email");
    }

    private static Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private Long parseLong(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String toStatusOptionValue(String status) {
        if (status == null || status.isBlank()) {
            return "";
        }
        String normalized = status.trim().toUpperCase(java.util.Locale.ROOT).replace(' ', '_');
        if ("APPROVED".equals(normalized) || "DILULUSKAN".equals(normalized)) {
            return "DILULUSKAN";
        }
        if ("REJECTED".equals(normalized) || "DITOLAK".equals(normalized)) {
            return "DITOLAK";
        }
        if ("SUSPENDED".equals(normalized) || "DIGANTUNG".equals(normalized)) {
            return "DIGANTUNG";
        }
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized)) {
            return "DIARKIB";
        }
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized)) {
            return "DALAM_SEMAKAN";
        }
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized)) {
            return "DALAM_PROSES";
        }
        return normalized;
    }

    private record SentKppReminderMetadata(
            String recipientEmail,
            String actionType,
            String applicationRef,
            String guestLink,
            String subject
    ) {
    }

    private void handleKppSubmissionDownload(Connection conn, long submissionId, HttpServletResponse response)
            throws SQLException, IOException {
        Map<String, Object> row = DashboardDataService.loadKppGuestSubmissionById(conn, submissionId);
        if (row == null || row.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Borang KPP tidak ditemui.");
            return;
        }

        String actionType = safePdfValue(row.get("action_type"));
        String filePrefix;
        if ("KSPP".equalsIgnoreCase(actionType)) {
            filePrefix = "BORANG-KSPP";
        } else if ("UJPPP".equalsIgnoreCase(actionType)) {
            filePrefix = "BORANG-UJPPP";
        } else {
            filePrefix = "BORANG-KSPP-UJPPP";
        }
        String fileName = filePrefix + "-" + submissionId + "-" + System.currentTimeMillis() + ".pdf";
        byte[] pdfBytes;
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            writeKppSubmissionPdf(row, output);
            pdfBytes = output.toByteArray();
        } catch (DocumentException e) {
            LOGGER.severe("Failed to generate KPP submission PDF: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal menjana PDF borang KPP.");
            return;
        }

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
        response.setContentLength(pdfBytes.length);
        response.getOutputStream().write(pdfBytes);
    }

    private void writeKppSubmissionPdf(Map<String, Object> row, ByteArrayOutputStream output)
            throws DocumentException, IOException {
        Document document = new Document(PageSize.A4, 36, 36, 36, 36);
        PdfWriter.getInstance(document, output);
        document.open();

        BaseFont baseFont = BaseFont.createFont("Helvetica", BaseFont.CP1252, false);
        Font titleFont = new Font(baseFont, 15, Font.BOLD);
        Font borangFont = new Font(baseFont, 12, Font.BOLD | Font.UNDERLINE);
        Font sectionFont = new Font(baseFont, 11, Font.BOLD);
        Font labelFont = new Font(baseFont, 9, Font.BOLD);
        Font bodyFont = new Font(baseFont, 9, Font.NORMAL);

        String actionType = safePdfValue(row.get("action_type"));
        boolean showKspp = "KSPP".equalsIgnoreCase(actionType) || "KSPP_UJPPP".equalsIgnoreCase(actionType);
        boolean showUjppp = "UJPPP".equalsIgnoreCase(actionType) || "KSPP_UJPPP".equalsIgnoreCase(actionType);
        String payload = String.valueOf(row.get("form_payload") == null ? "" : row.get("form_payload"));
        JsonObject payloadObject = parsePayloadObject(payload);

        String borangTitle;
        if (showKspp && showUjppp) {
            borangTitle = "BORANG KSPP / BORANG UJPPP";
        } else if (showKspp) {
            borangTitle = "BORANG KSPP";
        } else if (showUjppp) {
            borangTitle = "BORANG UJPPP";
        } else {
            borangTitle = "BORANG KPP";
        }
        document.addTitle(borangTitle);
        document.add(new Paragraph(borangTitle, titleFont));
        document.add(new Paragraph(" ", bodyFont));

        Map<String, String> respondentFields = new LinkedHashMap<>();
        respondentFields.put("Nama Penuh", getPayloadValue(payloadObject, "f_respondent_name"));
        respondentFields.put("Cawangan / Jabatan Air Daerah", getPayloadValue(payloadObject, "f_respondent_branch"));
        respondentFields.put("Jawatan Hakiki & Gred", getPayloadValue(payloadObject, "f_respondent_position_grade"));
        respondentFields.put("Gelaran Jawatan", getPayloadValue(payloadObject, "f_respondent_title"));
        respondentFields.put("No. Telefon", getPayloadValue(payloadObject, "f_phone"));
        respondentFields.put("Emel Rasmi Kerajaan", getPayloadValue(payloadObject, "f_respondent_official_email"));
        respondentFields.put("Tempoh Berkhidmat", getPayloadValue(payloadObject, "f_respondent_service_period"));
        addSectionTable(document, "Bahagian A: Maklumat Responden", respondentFields, sectionFont, labelFont, bodyFont);

        if (showKspp) {
            document.add(new Paragraph("BORANG KSPP", borangFont));
            document.add(new Paragraph(" ", bodyFont));

            Map<String, String> ksppB = new LinkedHashMap<>();
            ksppB.put("Nama Produk", getPayloadValue(payloadObject, "f_kspp_product_name"));
            ksppB.put("Jenama", getPayloadValue(payloadObject, "f_kspp_brand"));
            ksppB.put("Perihal Produk (Model/Kelas/Saiz)", getPayloadValue(payloadObject, "f_kspp_product_desc"));
            ksppB.put("Tarikh Mula & Siap", getPayloadValue(payloadObject, "f_kspp_start_end_date"));
            ksppB.put("% Siap", getPayloadValue(payloadObject, "f_kspp_completion_percent"));
            addSectionTable(document,
                    "Bahagian B: Maklumat Produk",
                    ksppB,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ksppC = new LinkedHashMap<>();
            ksppC.put("Nama Pembekal", getPayloadValue(payloadObject, "f_kspp_supplier_name"));
            ksppC.put("Nama Produk", getPayloadValue(payloadObject, "f_kspp_supplier_product_name"));
            ksppC.put("Jenama", getPayloadValue(payloadObject, "f_kspp_supplier_brand"));
            ksppC.put("Perihal Produk (Model/Kelas/Saiz/dll)", getPayloadValue(payloadObject, "f_kspp_supplier_product_desc"));
            addSectionTable(document,
                    "Bahagian C: Maklumat Pembekal dan Produk",
                    ksppC,
                    sectionFont,
                    labelFont,
                    bodyFont);

            addKsppQuestionSection(document, payloadObject, sectionFont, labelFont, bodyFont);

            Map<String, String> ksppE = new LinkedHashMap<>();
            ksppE.put("Keputusan Ulasan", getPayloadValue(payloadObject, "f_kspp_review_decision"));
            ksppE.put("Tarikh", getPayloadValue(payloadObject, "f_kspp_review_date"));
            ksppE.put("Ulasan", getPayloadValue(payloadObject, "f_kspp_review_note"));
            ksppE.put("Nama", getPayloadValue(payloadObject, "f_kspp_sign_name"));
            addSectionTable(document,
                    "Bahagian E: Ulasan Terhadap Pembaharuan Perakuan Pendaftaran Pembekal dan Produk Bekalan Air",
                    ksppE,
                    sectionFont,
                    labelFont,
                    bodyFont);
        }

        if (showUjppp) {
            if (showKspp) {
                // KSPP_UJPPP: add UJPPP title before its sections
                Paragraph ujpppBorangTitle = new Paragraph("BORANG UJPPP", borangFont);
                ujpppBorangTitle.setAlignment(Element.ALIGN_CENTER);
                document.add(ujpppBorangTitle);
                document.add(new Paragraph(" ", bodyFont));
            }
            document.add(new Paragraph("BORANG UJPPP", borangFont));
            document.add(new Paragraph(" ", bodyFont));

            Map<String, String> ujpppA = new LinkedHashMap<>();
            ujpppA.put("Jenis Permohonan (Baharu / Pembaharuan)", getPayloadValue(payloadObject, "f_ujppp_application_type"));
            ujpppA.put("Nama Syarikat Pembekal, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_supplier_company_info"));
            ujpppA.put("Nama Syarikat Pembuat / Pengilang, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_manufacturer_company_info"));
            ujpppA.put("Nama Syarikat Prinsipal / Pemilik Produk, Alamat Pejabat & No. Telefon", getPayloadValue(payloadObject, "f_ujppp_principal_company_info"));
            addSectionTable(document,
                    "Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal",
                    ujpppA,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ujpppB = new LinkedHashMap<>();
            ujpppB.put("Kategori", getPayloadValue(payloadObject, "f_ujppp_category"));
            ujpppB.put("Nama Produk", getPayloadValue(payloadObject, "f_ujppp_product_name"));
            ujpppB.put("Jenama", getPayloadValue(payloadObject, "f_ujppp_brand"));
            ujpppB.put("Piawaian / Standard", getPayloadValue(payloadObject, "f_ujppp_standard"));
            ujpppB.put("Badan Persijilan & No. Lesen Persijilan Barangan (Sah sehingga)", getPayloadValue(payloadObject, "f_ujppp_certification_body"));
            ujpppB.put("Badan Persijilan & No. Laporan Pengujian (Tarikh dikeluarkan)", getPayloadValue(payloadObject, "f_ujppp_test_report"));
            ujpppB.put("Perihal Produk (Model / Siri / Deskripsi)", getPayloadValue(payloadObject, "f_ujppp_product_desc"));
            ujpppB.put("Tempoh Jaminan Produk (Tahun)", getPayloadValue(payloadObject, "f_ujppp_warranty_year"));
            addSectionTable(document,
                    "Bahagian B: Maklumat Produk",
                    ujpppB,
                    sectionFont,
                    labelFont,
                    bodyFont);

            Map<String, String> ujpppC = new LinkedHashMap<>();
            ujpppC.put("Tarikh", getPayloadValue(payloadObject, "f_ujppp_review_date"));
            ujpppC.put("Syor (diterima/ditolak/digantung/dibatal)", getPayloadValue(payloadObject, "f_ujppp_review_recommendation"));
            addSectionTable(document,
                    "Bahagian C: Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Selaku Pengguna Produk",
                    ujpppC,
                    sectionFont,
                    labelFont,
                    bodyFont);
        }

        if (!showKspp && !showUjppp) {
            List<String> payloadLines = extractPayloadLines(payload);
            if (payloadLines.isEmpty()) {
                document.add(new Paragraph("Tiada kandungan borang.", bodyFont));
            } else {
                document.add(new Paragraph("Butiran Borang", sectionFont));
                document.add(new Paragraph(" ", bodyFont));
                for (String line : payloadLines) {
                    document.add(new Paragraph(line, bodyFont));
                }
            }
        }

        document.close();
    }

    private void addKsppQuestionSection(Document document,
                                        JsonObject payloadObject,
                                        Font sectionFont,
                                        Font labelFont,
                                        Font bodyFont) throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100f);
        table.setWidths(new float[]{0.5f, 4f, 2f});
        table.setSpacingBefore(8f);

        // Section title row spanning all 3 columns
        PdfPCell titleCell = new PdfPCell(new Phrase("BAHAGIAN D : PRESTASI PEMBEKAL DAN PRODUK", sectionFont));
        titleCell.setColspan(3);
        titleCell.setPadding(6f);
        titleCell.setBackgroundColor(new java.awt.Color(220, 230, 241));
        table.addCell(titleCell);

        // Nota row
        PdfPCell notaCell = new PdfPCell(new Phrase("Nota : # Sila nyatakan (Ya / Tidak / Tidak Berkenaan)", bodyFont));
        notaCell.setColspan(3);
        notaCell.setPadding(5f);
        table.addCell(notaCell);

        // Column headers
        PdfPCell noHeader = new PdfPCell(new Phrase("NO", labelFont));
        noHeader.setPadding(5f);
        noHeader.setHorizontalAlignment(Element.ALIGN_CENTER);
        noHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(noHeader);

        PdfPCell perkaraHeader = new PdfPCell(new Phrase("PERKARA", labelFont));
        perkaraHeader.setPadding(5f);
        perkaraHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(perkaraHeader);

        PdfPCell catatanHeader = new PdfPCell(new Phrase("# CATATAN", labelFont));
        catatanHeader.setPadding(5f);
        catatanHeader.setBackgroundColor(new java.awt.Color(240, 240, 240));
        table.addCell(catatanHeader);

        for (int i = 1; i <= KSPP_QUESTIONS.length; i++) {
            String answer = getPayloadValue(payloadObject, "f_kspp_q" + i);
            String note = getPayloadValue(payloadObject, "f_kspp_q" + i + "_note");

            PdfPCell noCell = new PdfPCell(new Phrase(String.valueOf(i), bodyFont));
            noCell.setPadding(5f);
            noCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(noCell);

            PdfPCell perkaraCell = new PdfPCell(new Phrase(KSPP_QUESTIONS[i - 1], bodyFont));
            perkaraCell.setPadding(5f);
            table.addCell(perkaraCell);

            String catatanText = (answer != null && !answer.isEmpty() ? answer : "-");
            if (note != null && !note.isEmpty()) {
                catatanText += "\n" + note;
            }
            PdfPCell catatanCell = new PdfPCell(new Phrase(catatanText, bodyFont));
            catatanCell.setPadding(5f);
            table.addCell(catatanCell);
        }

        document.add(table);
        document.add(new Paragraph(" ", bodyFont));
    }

    private void addSectionTable(Document document,
                                 String sectionTitle,
                                 Map<String, String> fields,
                                 Font sectionFont,
                                 Font labelFont,
                                 Font bodyFont) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100f);
        table.setWidths(new float[]{2f, 3f});
        table.setSpacingBefore(8f);

        // Section title as header row spanning both columns
        PdfPCell titleCell = new PdfPCell(new Phrase(sectionTitle.toUpperCase(), sectionFont));
        titleCell.setColspan(2);
        titleCell.setPadding(6f);
        titleCell.setBackgroundColor(new java.awt.Color(220, 230, 241));
        table.addCell(titleCell);

        for (Map.Entry<String, String> entry : fields.entrySet()) {
            PdfPCell labelCell = new PdfPCell(new Phrase(entry.getKey(), labelFont));
            labelCell.setPadding(6f);
            table.addCell(labelCell);

            PdfPCell valueCell = new PdfPCell(new Phrase(safePdfValue(entry.getValue()), bodyFont));
            valueCell.setPadding(6f);
            table.addCell(valueCell);
        }

        document.add(table);
        document.add(new Paragraph(" ", bodyFont));
    }

    private JsonObject parsePayloadObject(String payload) {
        if (payload == null || payload.isBlank()) {
            return new JsonObject();
        }

        try {
            JsonElement root = JsonParser.parseString(payload);
            if (root != null && root.isJsonObject()) {
                return root.getAsJsonObject();
            }
        } catch (Exception ignored) {
            // Fall back to empty object; fallback block will still print raw payload when needed.
        }

        return new JsonObject();
    }

    private String getPayloadValue(JsonObject payloadObject, String key) {
        if (payloadObject == null || key == null || key.isBlank() || !payloadObject.has(key)) {
            return "-";
        }

        JsonElement element = payloadObject.get(key);
        if (element == null || element.isJsonNull()) {
            return "-";
        }

        if (element.isJsonPrimitive()) {
            String value = element.getAsString();
            return value == null || value.trim().isEmpty() ? "-" : value.trim();
        }

        String value = element.toString();
        return value == null || value.trim().isEmpty() ? "-" : value.trim();
    }

    private List<String> extractPayloadLines(String payload) {
        List<String> lines = new ArrayList<>();
        if (payload == null || payload.isBlank()) {
            return lines;
        }

        try {
            JsonElement root = JsonParser.parseString(payload);
            flattenJsonPayload(root, "", lines);
        } catch (Exception ex) {
            lines.add(payload);
        }
        return lines;
    }

    private void flattenJsonPayload(JsonElement element, String path, List<String> lines) {
        if (element == null || element.isJsonNull()) {
            return;
        }

        if (element.isJsonPrimitive()) {
            String label = path == null || path.isBlank() ? "Nilai" : prettifyPath(path);
            lines.add(label + ": " + element.getAsString());
            return;
        }

        if (element.isJsonArray()) {
            JsonArray array = element.getAsJsonArray();
            if (array.isEmpty()) {
                if (path != null && !path.isBlank()) {
                    lines.add(prettifyPath(path) + ": -");
                }
                return;
            }
            for (int i = 0; i < array.size(); i++) {
                String nextPath = (path == null || path.isBlank()) ? "Item " + (i + 1) : path + " > Item " + (i + 1);
                flattenJsonPayload(array.get(i), nextPath, lines);
            }
            return;
        }

        JsonObject object = element.getAsJsonObject();
        for (Map.Entry<String, JsonElement> entry : object.entrySet()) {
            String nextPath = (path == null || path.isBlank()) ? entry.getKey() : path + " > " + entry.getKey();
            flattenJsonPayload(entry.getValue(), nextPath, lines);
        }
    }

    private String prettifyPath(String path) {
        if (path == null || path.isBlank()) {
            return "";
        }
        String normalized = path.replace('_', ' ');
        String[] parts = normalized.split(" > ");
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < parts.length; i++) {
            String part = parts[i].trim();
            if (part.isEmpty()) {
                continue;
            }
            if (builder.length() > 0) {
                builder.append(" > ");
            }
            builder.append(Character.toUpperCase(part.charAt(0)));
            if (part.length() > 1) {
                builder.append(part.substring(1));
            }
        }
        return builder.toString();
    }

    private String safePdfValue(Object value) {
        if (value == null) {
            return "-";
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? "-" : text;
    }

    private String storeAnnouncementImage(HttpServletRequest request, String existingImageUrl) throws IOException, ServletException {
        Part imagePart = request.getPart("announcement_image");
        if (imagePart == null || imagePart.getSize() <= 0) {
            return normalizeAnnouncementImageUrl(existingImageUrl);
        }

        if (imagePart.getSize() > ANNOUNCEMENT_MAX_IMAGE_SIZE_BYTES) {
            throw new ServletException("Saiz gambar terlalu besar. Maksimum 10MB.");
        }

        String submitted = imagePart.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return existingImageUrl;
        }

        String original = Paths.get(submitted).getFileName().toString();
        String extension = "";
        int dot = original.lastIndexOf('.');
        if (dot > -1 && dot < original.length() - 1) {
            extension = original.substring(dot).toLowerCase();
        }

        if (!(".png".equals(extension) || ".jpg".equals(extension) || ".jpeg".equals(extension) || ".webp".equals(extension))) {
            throw new ServletException("Format gambar tidak disokong. Guna PNG, JPG, JPEG, atau WEBP.");
        }

        Path uploadDir = resolveAnnouncementUploadDir();
        Files.createDirectories(uploadDir);

        String fileName = "ann-" + UUID.randomUUID() + extension;
        Path destination = uploadDir.resolve(fileName);
        try (InputStream input = imagePart.getInputStream()) {
            Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
        }

        return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
    }

    private String resolveUploadErrorMessage(Exception exception) {
        String message = exception.getMessage();
        if (message != null) {
            String lower = message.toLowerCase();
            if (lower.contains("size") || lower.contains("large") || lower.contains("exceed") || lower.contains("lebih besar")) {
                return "Saiz gambar terlalu besar. Had maksimum ialah 10MB.";
            }
            if (lower.contains("format gambar tidak disokong")) {
                return message;
            }
        }
        return "Gagal muat naik gambar. Gunakan format PNG/JPG/JPEG/WEBP dan pastikan saiz tidak melebihi 10MB.";
    }

    private Path resolveAnnouncementUploadDir() throws ServletException {
        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null && !catalinaBase.isBlank()) {
            return Paths.get(catalinaBase, "uploads", "sistemppa", "announcements");
        }

        String userDir = System.getProperty("user.dir");
        if (userDir != null && !userDir.isBlank()) {
            return Paths.get(userDir, "runtime", "uploads", "sistemppa", "announcements");
        }

        throw new ServletException("Path upload gambar tidak tersedia.");
    }

    private String normalizeAnnouncementImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return imageUrl;
        }

        String normalized = imageUrl.trim().replace('\\', '/');
        if (normalized.startsWith("http://") || normalized.startsWith("https://") || normalized.startsWith("data:")) {
            return normalized;
        }

        if (normalized.contains(ANNOUNCEMENT_IMAGE_ENDPOINT)) {
            int index = normalized.indexOf(ANNOUNCEMENT_IMAGE_ENDPOINT);
            return normalized.substring(index);
        }

        int uploadManagedIndex = normalized.toLowerCase(java.util.Locale.ROOT).indexOf("/uploads/sistemppa/announcements/");
        if (uploadManagedIndex >= 0) {
            String fileName = normalized.substring(uploadManagedIndex + "/uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int uploadRelativeIndex = normalized.toLowerCase(java.util.Locale.ROOT).indexOf("uploads/sistemppa/announcements/");
        if (uploadRelativeIndex >= 0) {
            String fileName = normalized.substring(uploadRelativeIndex + "uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int legacyIndex = normalized.indexOf("/assets/images/announcements/");
        if (legacyIndex >= 0) {
            String fileName = normalized.substring(legacyIndex + "/assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        int relativeLegacyIndex = normalized.indexOf("assets/images/announcements/");
        if (relativeLegacyIndex >= 0) {
            String fileName = normalized.substring(relativeLegacyIndex + "assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                return ANNOUNCEMENT_IMAGE_ENDPOINT + fileName;
            }
        }

        if (normalized.startsWith("/")) {
            return normalized;
        }

        return "/" + normalized;
    }
}


package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;
import java.util.logging.Logger;

public class DashboardServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());
    private static final int ADMIN_APPLICATION_LIMIT = 50;
    private static final int DASHBOARD_PRODUCT_LIMIT = 8;

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

        try (Connection conn = DatabaseConfig.getConnection()) {
            if ("ADMIN".equals(role)) {
                loadAdminDashboard(conn, request);
                request.getRequestDispatcher("/admin-dashboard.jsp").forward(request, response);
                return;
            }

            loadUserDashboard(conn, userId, request);
            request.getRequestDispatcher("/user-dashboard.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Database error: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    private void loadAdminDashboard(Connection conn, HttpServletRequest request) throws SQLException {
        String search = trim(request.getParameter("q"));
        String status = trim(request.getParameter("status"));

        Map<String, Integer> stats = DashboardDataService.loadAdminStats(conn);
        for (Map.Entry<String, Integer> entry : stats.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        request.setAttribute("search_query", search == null ? "" : search);
        request.setAttribute("selected_status", status == null ? "" : status);
        request.setAttribute("pending_applications",
                DashboardDataService.loadApplications(conn, search, status, ADMIN_APPLICATION_LIMIT));
        request.setAttribute("filtered_application_count",
                DashboardDataService.countApplications(conn, search, status));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
    }

    private void loadUserDashboard(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        Map<String, Object> user = DashboardDataService.loadUserSummary(conn, userId);
        for (Map.Entry<String, Object> entry : user.entrySet()) {
            request.setAttribute(entry.getKey(), entry.getValue());
        }

        request.setAttribute("application_count", DashboardDataService.countUserApplications(conn, userId));
        request.setAttribute("applications", DashboardDataService.loadUserApplications(conn, userId));
        request.setAttribute("product_catalog",
                DashboardDataService.loadProducts(conn, null, null, DASHBOARD_PRODUCT_LIMIT));
        request.setAttribute("product_count", DashboardDataService.countProducts(conn, null, null));
        request.setAttribute("account_status", user.get("status"));
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}

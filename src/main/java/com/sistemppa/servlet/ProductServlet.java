package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas ProductServlet.
 * Dipanggil melalui URL:  /products (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
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
import java.util.logging.Logger;

public class ProductServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ProductServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String search = trim(request.getParameter("q"));
        String productType = trim(request.getParameter("type"));

        try (Connection conn = DatabaseConfig.getConnection()) {
            request.setAttribute("products", DashboardDataService.loadProducts(conn, search, productType, 0));
            request.setAttribute("product_types", DashboardDataService.loadProductTypes(conn));
            request.setAttribute("product_total", DashboardDataService.countProducts(conn, search, productType));
            request.setAttribute("search_query", search == null ? "" : search);
            request.setAttribute("selected_type", productType == null ? "" : productType);
            request.getRequestDispatcher("/products.jsp").forward(request, response);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load product catalog: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to load product catalog");
        }
    }

    private String trim(String value) {
        return value != null ? value.trim() : null;
    }
}


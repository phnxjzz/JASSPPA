package com.sistemppa.config;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DatabaseConfig.
 * Dipanggil semasa aplikasi start-up untuk konfigurasi sistem.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.logging.Logger;

public class DatabaseConfig {
    private static final Logger LOGGER = Logger.getLogger(DatabaseConfig.class.getName());
    private static HikariDataSource dataSource;

    static {
        HikariConfig config = new HikariConfig();
        config.setDriverClassName("com.mysql.cj.jdbc.Driver");

        // Read connection details from environment variables.
        // For local development set DATABASE_URL, DATABASE_USER, DATABASE_PASSWORD
        // in your shell profile or Tomcat setenv.bat/setenv.sh.
        String dbUrl  = System.getenv("DATABASE_URL");
        String dbUser = System.getenv("DATABASE_USER");
        String dbPass = System.getenv("DATABASE_PASSWORD");

        if (dbUrl == null || dbUrl.isEmpty()) {
            LOGGER.warning("DATABASE_URL env var not set â€“ falling back to localhost dev defaults. "
                    + "Set DATABASE_URL / DATABASE_USER / DATABASE_PASSWORD for production.");
            dbUrl  = "jdbc:mysql://localhost:3306/sistemppa";
        }
        if (dbUser == null || dbUser.isEmpty()) {
            dbUser = "root";
        }
        if (dbPass == null) {
            dbPass = "";
        }
        
        config.setJdbcUrl(dbUrl);
        config.setUsername(dbUser);
        config.setPassword(dbPass);
        config.setMaximumPoolSize(20);
        config.setMinimumIdle(5);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setAutoCommit(true);
        
        dataSource = new HikariDataSource(config);
    }

    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    public static void closeDataSource() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
        }
    }
}


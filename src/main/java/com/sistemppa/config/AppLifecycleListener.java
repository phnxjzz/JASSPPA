package com.sistemppa.config;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas AppLifecycleListener.
 * Dipanggil semasa aplikasi start-up untuk konfigurasi sistem.
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.mysql.cj.jdbc.AbandonedConnectionCleanupThread;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Enumeration;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AppLifecycleListener implements ServletContextListener {
    private static final Logger LOGGER = Logger.getLogger(AppLifecycleListener.class.getName());

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        DatabaseConfig.closeDataSource();

        // Stop MySQL cleanup thread to avoid classloader leak warnings on redeploy.
        try {
            AbandonedConnectionCleanupThread.checkedShutdown();
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Failed to shut down MySQL cleanup thread", e);
        }

        //Unregister JDBC drivers loaded by webapp classloader
        ClassLoader webappClassLoader = Thread.currentThread().getContextClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver driver = drivers.nextElement();
            if (driver.getClass().getClassLoader() == webappClassLoader) {
                try {
                    DriverManager.deregisterDriver(driver);
                } catch(SQLException e) {
                    LOGGER.log(Level.WARNING, "Failed to deregister JDBC driver:" + driver, e);
                }
            }
        }
    }
}
            


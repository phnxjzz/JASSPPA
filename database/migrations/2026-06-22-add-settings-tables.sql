USE sistemppa;

CREATE TABLE IF NOT EXISTS kpp_email_reminder_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_kpp_setting_key (setting_key),
    INDEX idx_kpp_enabled (enabled)
);

CREATE TABLE IF NOT EXISTS smtp_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_smtp_setting_key (setting_key),
    INDEX idx_smtp_enabled (enabled)
);

CREATE TABLE IF NOT EXISTS app_runtime_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_app_runtime_setting_key (setting_key),
    INDEX idx_app_runtime_enabled (enabled)
);

CREATE TABLE IF NOT EXISTS security_job_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_security_job_setting_key (setting_key),
    INDEX idx_security_job_enabled (enabled)
);

CREATE TABLE IF NOT EXISTS reminder_schedule_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reminder_code VARCHAR(100) NOT NULL,
    reminder_time TIME NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_reminder_schedule_code (reminder_code),
    INDEX idx_reminder_schedule_enabled (enabled)
);

CREATE TABLE IF NOT EXISTS kpp_reminder_queue (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_email VARCHAR(255) NOT NULL,
    action_type VARCHAR(64),
    application_ref VARCHAR(128),
    guest_link TEXT,
    source_subject VARCHAR(255),
    reminder_no TINYINT NOT NULL,
    due_at TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    sent_at TIMESTAMP NULL,
    last_error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_kpp_reminder_unique (recipient_email, action_type, application_ref, reminder_no),
    KEY idx_kpp_reminder_due (status, due_at),
    KEY idx_kpp_reminder_lookup (recipient_email, action_type, application_ref)
);

CREATE TABLE IF NOT EXISTS certificate_application_snapshots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    certificate_number VARCHAR(60),
    issued_at DATE,
    valid_until DATE,
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    product_description TEXT,
    company_name VARCHAR(255),
    company_address TEXT,
    contact_number VARCHAR(20),
    email VARCHAR(100),
    application_type ENUM('BAHARU', 'PEMBAHARUAN') NULL,
    supplier_name VARCHAR(255),
    supplier_address TEXT,
    supplier_phone VARCHAR(50),
    manufacturer_name VARCHAR(255),
    manufacturer_address TEXT,
    manufacturer_phone VARCHAR(50),
    principal_name VARCHAR(255),
    principal_address TEXT,
    principal_phone VARCHAR(50),
    standard_name VARCHAR(255),
    certification_license VARCHAR(255),
    certification_valid_until DATE,
    test_report_reference VARCHAR(255),
    test_report_date DATE,
    warranty_years DECIMAL(5,2),
    sabah_rep_name VARCHAR(255),
    sabah_rep_address TEXT,
    sabah_rep_phone VARCHAR(50),
    declaration_name VARCHAR(255),
    declaration_position VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_certificate_snapshot_application (application_id),
    KEY idx_certificate_snapshot_number (certificate_number),
    CONSTRAINT fk_certificate_snapshot_application
        FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS certificate_number_sequences (
    sequence_year INT PRIMARY KEY,
    last_sequence INT NOT NULL DEFAULT -1,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO kpp_email_reminder_settings (setting_key, setting_value, enabled, description)
VALUES
    ('reminder_days_before_due', '7', 1, 'Send reminder before due date by number of days'),
    ('reminder_send_time', '08:00', 1, 'Daily time to send KPP reminder emails (HH:MM)'),
    ('reminder_email_subject_prefix', '[SPPA KPP Reminder]', 1, 'Subject prefix for reminder emails'),
    ('reminder_total', '3', 1, 'Total number of reminder emails to schedule'),
    ('reminder_gap_days', '4', 1, 'Number of days between reminder emails')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = NOW();

INSERT INTO smtp_settings (setting_key, setting_value, enabled, description)
VALUES
    ('smtp_host', 'smtp.gmail.com', 1, 'SMTP host server'),
    ('smtp_port', '587', 1, 'SMTP host port'),
    ('smtp_auth', 'true', 1, 'Enable SMTP authentication'),
    ('smtp_tls', 'true', 1, 'Enable STARTTLS for SMTP'),
    ('smtp_username', '', 1, 'SMTP username or sender account'),
    ('smtp_password', '', 1, 'SMTP password or app password'),
    ('smtp_from', '', 1, 'From email address used by system')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = NOW();

INSERT INTO app_runtime_settings (setting_key, setting_value, enabled, description)
VALUES
    ('app_base_url', 'http://localhost:8081/sistemppa', 1, 'Public base URL for links in email and redirects')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = NOW();

INSERT INTO security_job_settings (setting_key, setting_value, enabled, description)
VALUES
    ('kpp_reminder_job_key', 'CHANGE_ME_INTERNAL_KPP_REMINDER_KEY', 1, 'Internal key for triggering KPP reminder job endpoint')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = NOW();

INSERT INTO reminder_schedule_settings (reminder_code, reminder_time, enabled, description)
VALUES
    ('kpp_email_reminder', '08:00:00', 1, 'Default daily reminder schedule time for KPP email reminders')
ON DUPLICATE KEY UPDATE
    reminder_time = VALUES(reminder_time),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = NOW();

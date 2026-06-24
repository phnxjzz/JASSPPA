-- Sistem Pendaftaran Produk Air (SPPA) Database Schema

CREATE DATABASE IF NOT EXISTS sistemppa;
USE sistemppa;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'USER', 'STAFF') NOT NULL DEFAULT 'USER',
    role_seq INT,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255),
    status ENUM('ACTIVE', 'SUSPENDED', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    UNIQUE KEY uniq_role_role_seq (role, role_seq),
    INDEX idx_status (status)
);

-- Applications Table (Permohonan)
CREATE TABLE IF NOT EXISTS applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    product_description TEXT,
    company_name VARCHAR(255) NOT NULL,
    company_address TEXT NOT NULL,
    contact_number VARCHAR(20),
    email VARCHAR(100),
    status ENUM('DRAFT', 'NEW', 'UNDER_REVIEW', 'IN_PROGRESS', 'APPROVED', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'NEW',
    admin_notes TEXT,
    submitted_at TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_submitted_at (submitted_at)
);

CREATE TABLE IF NOT EXISTS application_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    application_type ENUM('BAHARU', 'PEMBAHARUAN') NOT NULL,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_address TEXT NOT NULL,
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
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_application_detail (application_id)
);

-- Certificate Snapshot Table
-- Stores a full copy of approved application/application_details values used by certificate output.
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

-- Certificate Number Sequence Table
-- Maintains yearly running number for certificate format: JANS.YEAR.000
CREATE TABLE IF NOT EXISTS certificate_number_sequences (
    sequence_year INT PRIMARY KEY,
    last_sequence INT NOT NULL DEFAULT -1,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS application_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    stored_path TEXT NOT NULL,
    content_type VARCHAR(100),
    file_size BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    INDEX idx_application_id (application_id),
    INDEX idx_document_type (document_type)
);

CREATE TABLE IF NOT EXISTS application_archives (
    application_id INT NOT NULL PRIMARY KEY,
    archived_by INT,
    archive_notes VARCHAR(500),
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (archived_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_archived_at (archived_at)
);

-- Products Table (Produk Air Terdaftar)
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    no INT UNIQUE NOT NULL,
    page INT NOT NULL,
    supplier_agent TEXT NOT NULL,
    supplier_valid_until DATE,
    product_materials VARCHAR(255) NOT NULL,
    product_type VARCHAR(100) NOT NULL,
    classification VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    attachment_urls LONGTEXT,
    source_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_no (no),
    INDEX idx_brand (brand),
    INDEX idx_product_type (product_type)
);

-- Audit Log Table (Untuk pentadbir melihat aktiviti)
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- KPP Auto Reminder Settings Table
-- Any system setting should be stored in its own dedicated table.
-- This table is specifically for KPP reminder email configuration.
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

-- SMTP Settings Table (email transport settings)
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

-- Application Runtime Settings Table (app-level URLs and runtime parameters)
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

-- Security and Job Settings Table (tokens/keys/job-level controls)
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

-- Reminder Schedule Settings Table (single-purpose table for reminder time control)
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

-- KPP Reminder Queue Table (previously created on first runtime use)
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

-- Insert default admin user
INSERT INTO users (username, email, password_hash, role, full_name, status)
VALUES ('admin', 'admin@sistemppa.gov.my', SHA2('admin123', 256), 'ADMIN', 'Administrator', 'ACTIVE')
ON DUPLICATE KEY UPDATE updated_at=NOW();

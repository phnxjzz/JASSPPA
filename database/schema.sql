-- Sistem Pendaftaran Produk Air (SPPA) Database Schema

CREATE DATABASE IF NOT EXISTS sistemppa;
USE sistemppa;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'USER') NOT NULL DEFAULT 'USER',
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255),
    status ENUM('ACTIVE', 'SUSPENDED', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
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
    status ENUM('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'PENDING',
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

-- Insert default admin user
INSERT INTO users (username, email, password_hash, role, full_name, status)
VALUES ('admin', 'admin@sistemppa.gov.my', SHA2('admin123', 256), 'ADMIN', 'Administrator', 'ACTIVE')
ON DUPLICATE KEY UPDATE updated_at=NOW();

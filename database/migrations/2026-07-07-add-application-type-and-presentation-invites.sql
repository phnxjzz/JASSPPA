USE sistemppa;

-- 1) Normalize application type enum to include KEMASKINI.
ALTER TABLE application_details
    MODIFY COLUMN application_type ENUM('KEMASKINI', 'BAHARU', 'PEMBAHARUAN') NOT NULL;

ALTER TABLE certificate_application_snapshots
    MODIFY COLUMN application_type ENUM('KEMASKINI', 'BAHARU', 'PEMBAHARUAN') NULL;

-- 2) Split detail tables by application type.
CREATE TABLE IF NOT EXISTS application_details_baharu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
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
    UNIQUE KEY uniq_application_detail_baharu (application_id)
);

CREATE TABLE IF NOT EXISTS application_details_pembaharuan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
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
    UNIQUE KEY uniq_application_detail_pembaharuan (application_id)
);

CREATE TABLE IF NOT EXISTS application_details_kemaskini (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
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
    UNIQUE KEY uniq_application_detail_kemaskini (application_id)
);

-- 3) Table for managing presentation invitation feedback.
CREATE TABLE IF NOT EXISTS presentation_invites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    user_id INT NOT NULL,
    invited_by INT NULL,
    presentation_date DATE NOT NULL,
    presentation_time VARCHAR(10) NOT NULL,
    presentation_venue VARCHAR(255) NOT NULL,
    applicant_memo TEXT NULL,
    kpp_emails TEXT NULL,
    kpp_memo TEXT NULL,
    invite_status VARCHAR(50) NOT NULL DEFAULT 'MENUNGGU_MAKLUM_BALAS',
    applicant_response VARCHAR(30) NULL,
    applicant_rep_name VARCHAR(180) NULL,
    applicant_attendee_count INT NULL,
    applicant_absence_reason TEXT NULL,
    reschedule_count INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    responded_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_presentation_invites_user (user_id, is_active),
    INDEX idx_presentation_invites_app (application_id),
    INDEX idx_presentation_invites_status (invite_status),
    CONSTRAINT fk_presentation_invites_app FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    CONSTRAINT fk_presentation_invites_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_presentation_invites_admin FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 4) Initial backfill from existing unified application_details table.
INSERT INTO application_details_baharu (
    application_id, supplier_name, supplier_address, supplier_phone,
    manufacturer_name, manufacturer_address, manufacturer_phone,
    principal_name, principal_address, principal_phone,
    standard_name, certification_license, certification_valid_until,
    test_report_reference, test_report_date, warranty_years,
    sabah_rep_name, sabah_rep_address, sabah_rep_phone,
    declaration_name, declaration_position
)
SELECT
    ad.application_id, ad.supplier_name, ad.supplier_address, ad.supplier_phone,
    ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone,
    ad.principal_name, ad.principal_address, ad.principal_phone,
    ad.standard_name, ad.certification_license, ad.certification_valid_until,
    ad.test_report_reference, ad.test_report_date, ad.warranty_years,
    ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone,
    ad.declaration_name, ad.declaration_position
FROM application_details ad
WHERE ad.application_type = 'BAHARU'
ON DUPLICATE KEY UPDATE
    supplier_name = VALUES(supplier_name),
    supplier_address = VALUES(supplier_address),
    supplier_phone = VALUES(supplier_phone),
    manufacturer_name = VALUES(manufacturer_name),
    manufacturer_address = VALUES(manufacturer_address),
    manufacturer_phone = VALUES(manufacturer_phone),
    principal_name = VALUES(principal_name),
    principal_address = VALUES(principal_address),
    principal_phone = VALUES(principal_phone),
    standard_name = VALUES(standard_name),
    certification_license = VALUES(certification_license),
    certification_valid_until = VALUES(certification_valid_until),
    test_report_reference = VALUES(test_report_reference),
    test_report_date = VALUES(test_report_date),
    warranty_years = VALUES(warranty_years),
    sabah_rep_name = VALUES(sabah_rep_name),
    sabah_rep_address = VALUES(sabah_rep_address),
    sabah_rep_phone = VALUES(sabah_rep_phone),
    declaration_name = VALUES(declaration_name),
    declaration_position = VALUES(declaration_position),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO application_details_pembaharuan (
    application_id, supplier_name, supplier_address, supplier_phone,
    manufacturer_name, manufacturer_address, manufacturer_phone,
    principal_name, principal_address, principal_phone,
    standard_name, certification_license, certification_valid_until,
    test_report_reference, test_report_date, warranty_years,
    sabah_rep_name, sabah_rep_address, sabah_rep_phone,
    declaration_name, declaration_position
)
SELECT
    ad.application_id, ad.supplier_name, ad.supplier_address, ad.supplier_phone,
    ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone,
    ad.principal_name, ad.principal_address, ad.principal_phone,
    ad.standard_name, ad.certification_license, ad.certification_valid_until,
    ad.test_report_reference, ad.test_report_date, ad.warranty_years,
    ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone,
    ad.declaration_name, ad.declaration_position
FROM application_details ad
WHERE ad.application_type = 'PEMBAHARUAN'
ON DUPLICATE KEY UPDATE
    supplier_name = VALUES(supplier_name),
    supplier_address = VALUES(supplier_address),
    supplier_phone = VALUES(supplier_phone),
    manufacturer_name = VALUES(manufacturer_name),
    manufacturer_address = VALUES(manufacturer_address),
    manufacturer_phone = VALUES(manufacturer_phone),
    principal_name = VALUES(principal_name),
    principal_address = VALUES(principal_address),
    principal_phone = VALUES(principal_phone),
    standard_name = VALUES(standard_name),
    certification_license = VALUES(certification_license),
    certification_valid_until = VALUES(certification_valid_until),
    test_report_reference = VALUES(test_report_reference),
    test_report_date = VALUES(test_report_date),
    warranty_years = VALUES(warranty_years),
    sabah_rep_name = VALUES(sabah_rep_name),
    sabah_rep_address = VALUES(sabah_rep_address),
    sabah_rep_phone = VALUES(sabah_rep_phone),
    declaration_name = VALUES(declaration_name),
    declaration_position = VALUES(declaration_position),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO application_details_kemaskini (
    application_id, supplier_name, supplier_address, supplier_phone,
    manufacturer_name, manufacturer_address, manufacturer_phone,
    principal_name, principal_address, principal_phone,
    standard_name, certification_license, certification_valid_until,
    test_report_reference, test_report_date, warranty_years,
    sabah_rep_name, sabah_rep_address, sabah_rep_phone,
    declaration_name, declaration_position
)
SELECT
    ad.application_id, ad.supplier_name, ad.supplier_address, ad.supplier_phone,
    ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone,
    ad.principal_name, ad.principal_address, ad.principal_phone,
    ad.standard_name, ad.certification_license, ad.certification_valid_until,
    ad.test_report_reference, ad.test_report_date, ad.warranty_years,
    ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone,
    ad.declaration_name, ad.declaration_position
FROM application_details ad
WHERE ad.application_type = 'KEMASKINI'
ON DUPLICATE KEY UPDATE
    supplier_name = VALUES(supplier_name),
    supplier_address = VALUES(supplier_address),
    supplier_phone = VALUES(supplier_phone),
    manufacturer_name = VALUES(manufacturer_name),
    manufacturer_address = VALUES(manufacturer_address),
    manufacturer_phone = VALUES(manufacturer_phone),
    principal_name = VALUES(principal_name),
    principal_address = VALUES(principal_address),
    principal_phone = VALUES(principal_phone),
    standard_name = VALUES(standard_name),
    certification_license = VALUES(certification_license),
    certification_valid_until = VALUES(certification_valid_until),
    test_report_reference = VALUES(test_report_reference),
    test_report_date = VALUES(test_report_date),
    warranty_years = VALUES(warranty_years),
    sabah_rep_name = VALUES(sabah_rep_name),
    sabah_rep_address = VALUES(sabah_rep_address),
    sabah_rep_phone = VALUES(sabah_rep_phone),
    declaration_name = VALUES(declaration_name),
    declaration_position = VALUES(declaration_position),
    updated_at = CURRENT_TIMESTAMP;

-- 5) Keep split tables in sync with current application_details writes.
DROP TRIGGER IF EXISTS trg_application_details_ai_sync_type_table;
DROP TRIGGER IF EXISTS trg_application_details_au_sync_type_table;
DROP TRIGGER IF EXISTS trg_application_details_ad_sync_type_table;

DELIMITER $$

CREATE TRIGGER trg_application_details_ai_sync_type_table
AFTER INSERT ON application_details
FOR EACH ROW
BEGIN
    DELETE FROM application_details_baharu WHERE application_id = NEW.application_id;
    DELETE FROM application_details_pembaharuan WHERE application_id = NEW.application_id;
    DELETE FROM application_details_kemaskini WHERE application_id = NEW.application_id;

    IF NEW.application_type = 'BAHARU' THEN
        INSERT INTO application_details_baharu (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    ELSEIF NEW.application_type = 'PEMBAHARUAN' THEN
        INSERT INTO application_details_pembaharuan (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    ELSEIF NEW.application_type = 'KEMASKINI' THEN
        INSERT INTO application_details_kemaskini (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    END IF;
END$$

CREATE TRIGGER trg_application_details_au_sync_type_table
AFTER UPDATE ON application_details
FOR EACH ROW
BEGIN
    DELETE FROM application_details_baharu WHERE application_id = NEW.application_id;
    DELETE FROM application_details_pembaharuan WHERE application_id = NEW.application_id;
    DELETE FROM application_details_kemaskini WHERE application_id = NEW.application_id;

    IF NEW.application_type = 'BAHARU' THEN
        INSERT INTO application_details_baharu (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    ELSEIF NEW.application_type = 'PEMBAHARUAN' THEN
        INSERT INTO application_details_pembaharuan (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    ELSEIF NEW.application_type = 'KEMASKINI' THEN
        INSERT INTO application_details_kemaskini (
            application_id, supplier_name, supplier_address, supplier_phone,
            manufacturer_name, manufacturer_address, manufacturer_phone,
            principal_name, principal_address, principal_phone,
            standard_name, certification_license, certification_valid_until,
            test_report_reference, test_report_date, warranty_years,
            sabah_rep_name, sabah_rep_address, sabah_rep_phone,
            declaration_name, declaration_position
        ) VALUES (
            NEW.application_id, NEW.supplier_name, NEW.supplier_address, NEW.supplier_phone,
            NEW.manufacturer_name, NEW.manufacturer_address, NEW.manufacturer_phone,
            NEW.principal_name, NEW.principal_address, NEW.principal_phone,
            NEW.standard_name, NEW.certification_license, NEW.certification_valid_until,
            NEW.test_report_reference, NEW.test_report_date, NEW.warranty_years,
            NEW.sabah_rep_name, NEW.sabah_rep_address, NEW.sabah_rep_phone,
            NEW.declaration_name, NEW.declaration_position
        );
    END IF;
END$$

CREATE TRIGGER trg_application_details_ad_sync_type_table
AFTER DELETE ON application_details
FOR EACH ROW
BEGIN
    DELETE FROM application_details_baharu WHERE application_id = OLD.application_id;
    DELETE FROM application_details_pembaharuan WHERE application_id = OLD.application_id;
    DELETE FROM application_details_kemaskini WHERE application_id = OLD.application_id;
END$$

DELIMITER ;

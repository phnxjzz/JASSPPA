USE sistemppa;

-- ============================================================
-- Email Templates Table
-- ============================================================
CREATE TABLE IF NOT EXISTS email_templates (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    template_key VARCHAR(100) NOT NULL,
    name        VARCHAR(200) NOT NULL,
    subject     VARCHAR(500) NOT NULL,
    body        MEDIUMTEXT NOT NULL,
    description VARCHAR(500) NULL,
    variables   VARCHAR(1000) NULL COMMENT 'Comma-separated list of available placeholders',
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    updated_by  INT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_email_template_key (template_key),
    INDEX idx_email_template_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Notification Templates Table
-- ============================================================
CREATE TABLE IF NOT EXISTS notification_templates (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    template_key VARCHAR(100) NOT NULL,
    name        VARCHAR(200) NOT NULL,
    message     TEXT NOT NULL,
    description VARCHAR(500) NULL,
    variables   VARCHAR(1000) NULL COMMENT 'Comma-separated list of available placeholders',
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    updated_by  INT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_notif_template_key (template_key),
    INDEX idx_notif_template_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Seed: Email Templates (default content)
-- ============================================================
INSERT INTO email_templates (template_key, name, subject, body, description, variables) VALUES

('EMAIL_VERIFICATION',
 'Pengesahan E-mel Pendaftaran',
 'Pengesahan E-mel – Sistem Pendaftaran Pembekal dan Produk Bekalan Air',
 '<p>Salam {{full_name}},</p><p>Terima kasih kerana mendaftar. Sila klik pautan di bawah untuk mengaktifkan akaun anda:</p><p><a href="{{verify_url}}">{{verify_url}}</a></p><p>Pautan ini akan tamat dalam 24 jam.</p><p>Jika anda tidak mendaftar, abaikan e-mel ini.</p>',
 'Dihantar kepada pemohon baharu selepas pendaftaran akaun untuk mengesahkan e-mel.',
 '{{full_name}}, {{verify_url}}'
),

('APPLICATION_RECEIVED',
 'Permohonan Diterima',
 'Permohonan {{app_ref}} DITERIMA – SPPA',
 '<p>Salam {{full_name}},</p><p>Permohonan anda untuk produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah <strong>DITERIMA</strong> dan akan diambil tindakan.</p><p>Terima kasih.</p>',
 'Dihantar kepada pemohon apabila status permohonan ditukar kepada PERMOHONAN DITERIMA.',
 '{{full_name}}, {{product_name}}, {{app_ref}}'
),

('APPLICATION_APPROVED',
 'Permohonan Diluluskan',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Sukacita dimaklumkan bahawa permohonan ini adalah diluluskan dan didaftarkan untuk kegunaan Jabatan tertakluk kepada syarat serta ketetapan yang sedang berkuat kuasa.</p><p>No. Perakuan Pendaftaran: <strong>{{cert_ref}}</strong></p><p>Tuan/puan boleh log masuk ke sistem untuk melihat dan mencetak perakuan pendaftaran yang berkaitan.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan diluluskan.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{cert_ref}}'
),

('APPLICATION_REJECTED',
 'Permohonan Ditolak',
 'Permohonan {{app_ref}} DITOLAK – SPPA',
 '<p>Salam {{full_name}},</p><p>Kami memaklumkan bahawa permohonan anda untuk produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah <strong>DITOLAK</strong>.</p><p>Sebab penolakan: {{admin_notes}}</p><p>Sila hubungi pentadbir jika anda memerlukan maklumat lanjut.</p><p>Terima kasih.</p>',
 'Dihantar kepada pemohon apabila permohonan ditolak.',
 '{{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
),

('APPLICATION_SUSPENDED',
 'Permohonan Digantung',
 'Permohonan {{app_ref}} DIGANTUNG – SPPA',
 '<p>Salam {{full_name}},</p><p>Permohonan anda untuk produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah <strong>DIGANTUNG</strong>.</p><p>Ulasan Pengarah: {{admin_notes}}</p><p>Sila hubungi pentadbir jika anda memerlukan maklumat lanjut.</p><p>Terima kasih.</p>',
 'Dihantar kepada pemohon apabila permohonan digantung.',
 '{{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
),

('APPLICATION_ARCHIVED',
 'Permohonan Dibatalkan/Diarkib',
 'Permohonan {{app_ref}} DIBATALKAN – SPPA',
 '<p>Salam {{full_name}},</p><p>Permohonan anda untuk produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah <strong>DIBATALKAN</strong>.</p><p>Ulasan Pengarah: {{admin_notes}}</p><p>Sila hubungi pentadbir jika anda memerlukan maklumat lanjut.</p><p>Terima kasih.</p>',
 'Dihantar kepada pemohon apabila permohonan diarkib atau dibatalkan.',
 '{{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
),

('DIRECTOR_ACTION_REQUEST',
 'Permintaan Tindakan Akhir kepada Pengarah',
 'Tindakan Akhir Diperlukan - {{app_ref}} - SPPA',
 '<p>Salam Pengarah,</p><p>Permohonan {{app_ref}} telah dihantar oleh Admin {{admin_display_id}} untuk tindakan akhir.</p><p>Butiran ringkas:</p><ul><li>Pemohon: {{applicant_name}}</li><li>Syarikat: {{company_name}}</li><li>Produk: {{product_name}}</li><li>Kategori: {{product_category}}</li><li>Status: {{status}}</li></ul><p>Sila buka modul Pengarah melalui pautan di bawah:</p><p><a href="{{dashboard_url}}">Buka Dashboard Pengarah</a></p><p>Terima kasih.</p>',
 'Dihantar kepada Pengarah apabila Admin menekan butang Tindakan Akhir.',
 '{{app_ref}}, {{admin_display_id}}, {{applicant_name}}, {{company_name}}, {{product_name}}, {{product_category}}, {{status}}, {{dashboard_url}}'
),

('PRESENTATION_APPLICANT',
 'Makluman Pembentangan kepada Pemohon',
 'Makluman Pembentangan Permohonan {{app_ref}} - SPPA',
 '<p>Salam {{full_name}},</p><p>Permohonan anda untuk produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) kini dalam status <strong>DALAM PROSES</strong>.</p><p>Berikut adalah makluman pembentangan:</p><pre style="font-family:Arial,Helvetica,sans-serif;white-space:pre-wrap;margin:0;padding:12px;border:1px solid #d7dbe0;border-radius:8px;background:#f8fafc;">{{presentation_message}}</pre><p>Sila pastikan kehadiran mengikut maklumat di atas.</p><p>Terima kasih.</p>',
 'Dihantar kepada pemohon apabila status ditukar kepada DALAM PROSES bersama maklumat pembentangan.',
 '{{full_name}}, {{product_name}}, {{app_ref}}, {{presentation_message}}'
),

('PRESENTATION_KPP_INVITE',
 'Jemputan Pembentangan kepada KPP',
 'Jemputan Pembentangan Permohonan {{app_ref}} - SPPPBA',
 '<p>Salam sejahtera,</p><p>Tuan/Puan dijemput untuk pembentangan permohonan {{app_ref}}.</p><p><strong>Tarikh:</strong> {{presentation_date}}<br><strong>Masa:</strong> {{presentation_time}}<br><strong>Tempat:</strong> {{presentation_venue}}</p>{{memo_section}}<p>Terima kasih.</p>',
 'Dihantar kepada ahli KPP yang dijemput untuk hadir pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}, {{memo_section}}'
),

('PROFILE_REVIEW_APPROVED',
 'Semakan Profil Diluluskan',
 'Semakan Profil Diluluskan - SPPA',
 '<p>Salam {{full_name}},</p><p>Semakan profil anda telah <strong>diluluskan</strong>. Akaun {{display_id}} kini boleh mengakses dashboard dan fungsi sistem.</p>',
 'Dihantar kepada pemohon apabila profil mereka diluluskan oleh Admin.',
 '{{full_name}}, {{display_id}}'
),

('PROFILE_REVIEW_REJECTED',
 'Semakan Profil Ditolak',
 'Semakan Profil Ditolak - SPPA',
 '<p>Salam {{full_name}},</p><p>Semakan profil anda telah <strong>ditolak</strong>.</p><p>Sebab penolakan: {{review_notes}}</p><p>Sila kemas kini profil anda dan hantar semula untuk semakan.</p>',
 'Dihantar kepada pemohon apabila profil mereka ditolak oleh Admin.',
 '{{full_name}}, {{display_id}}, {{review_notes}}'
)

ON DUPLICATE KEY UPDATE
    name       = VALUES(name),
    subject    = VALUES(subject),
    body       = VALUES(body),
    description= VALUES(description),
    variables  = VALUES(variables);

-- ============================================================
-- Seed: Notification Templates (default content)
-- ============================================================
INSERT INTO notification_templates (template_key, name, message, description, variables) VALUES

('NOTIF_APPLICATION_APPROVED',
 'Notifikasi: Permohonan Diluluskan',
 'Permohonan {{app_ref}} anda telah DILULUSKAN. Perakuan Pendaftaran {{cert_ref}} telah dikeluarkan.',
 'Notifikasi dalam sistem kepada pemohon apabila permohonan diluluskan.',
 '{{app_ref}}, {{cert_ref}}'
),

('NOTIF_APPLICATION_RECEIVED',
 'Notifikasi: Permohonan Diterima',
 'Permohonan {{app_ref}} anda telah DITERIMA dan akan diambil tindakan.',
 'Notifikasi dalam sistem kepada pemohon apabila permohonan diterima untuk semakan.',
 '{{app_ref}}'
),

('NOTIF_APPLICATION_REJECTED',
 'Notifikasi: Permohonan Ditolak',
 'Permohonan {{app_ref}} anda telah DITOLAK.{{notes_section}}',
 'Notifikasi dalam sistem kepada pemohon apabila permohonan ditolak.',
 '{{app_ref}}, {{notes_section}}'
),

('NOTIF_APPLICATION_SUSPENDED',
 'Notifikasi: Permohonan Digantung',
 'Permohonan {{app_ref}} anda telah DIGANTUNG.',
 'Notifikasi dalam sistem kepada pemohon apabila permohonan digantung.',
 '{{app_ref}}'
),

('NOTIF_APPLICATION_STATUS_GENERIC',
 'Notifikasi: Kemaskini Status Permohonan',
 'Status permohonan {{app_ref}} telah dikemas kini kepada {{status}}.',
 'Notifikasi generik apabila status permohonan berubah kepada status lain.',
 '{{app_ref}}, {{status}}'
),

('NOTIF_PRESENTATION_APPLICANT',
 'Notifikasi Pembentangan: Makluman kepada Pemohon',
 'Pemohon dimaklumkan untuk bersedia dan menghadiri sesi Pembentangan Produk Air yang didaftarkan.\nTarikh: {{presentation_date}}\nMasa: {{presentation_time}}\nTempat: {{presentation_venue}}',
 'Notifikasi dalam sistem kepada pemohon berserta maklumat pembentangan.',
 '{{presentation_date}}, {{presentation_time}}, {{presentation_venue}}'
),

('NOTIF_PRESENTATION_KPP',
 'Notifikasi Pembentangan: Jemputan kepada KPP',
 'Jemputan pembentangan produk bagi permohonan {{app_ref}}\nTarikh: {{presentation_date}}\nMasa: {{presentation_time}}\nTempat: {{presentation_venue}}',
 'Notifikasi dalam sistem kepada ahli KPP yang dijemput untuk pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}'
),

('NOTIF_PROFILE_APPROVED',
 'Notifikasi: Profil Diluluskan',
 'Maklumat profil anda telah diterima. Akaun anda kini boleh mengakses dashboard dan fungsi sistem.',
 'Notifikasi dalam sistem kepada pemohon apabila profil mereka diluluskan.',
 ''
),

('NOTIF_PROFILE_REJECTED',
 'Notifikasi: Profil Ditolak',
 'Maklumat profil anda ditolak. Sebab: {{review_notes}}',
 'Notifikasi dalam sistem kepada pemohon apabila profil mereka ditolak.',
 '{{review_notes}}'
),

('NOTIF_DIRECTOR_DECISION',
 'Notifikasi: Keputusan Pengarah kepada Admin',
 'Keputusan akhir Pengarah bagi {{app_ref}} telah direkodkan.',
 'Notifikasi dalam sistem kepada Admin apabila Pengarah selesai mengambil tindakan.',
 '{{app_ref}}'
)

ON DUPLICATE KEY UPDATE
    name       = VALUES(name),
    message    = VALUES(message),
    description= VALUES(description),
    variables  = VALUES(variables);

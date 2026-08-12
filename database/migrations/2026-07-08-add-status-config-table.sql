USE sistemppa;

-- ============================================================
-- Application Status Configuration Table
-- ============================================================
CREATE TABLE IF NOT EXISTS application_status_config (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    status_key      VARCHAR(100) NOT NULL COMMENT 'Internal enum value stored in applications.status',
    display_label   VARCHAR(200) NOT NULL COMMENT 'Label displayed to users (Malay)',
    badge_bg_color  VARCHAR(30)  NOT NULL DEFAULT '#e0f2fe' COMMENT 'CSS background color for status pill',
    badge_text_color VARCHAR(30) NOT NULL DEFAULT '#0369a1' COMMENT 'CSS text color for status pill',
    description     VARCHAR(500) NULL     COMMENT 'Admin description of this status',
    sort_order      INT          NOT NULL DEFAULT 99,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    updated_by      INT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_status_key (status_key),
    INDEX idx_status_active (is_active),
    INDEX idx_status_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Seed: all application statuses with Malay display labels
-- ============================================================
INSERT INTO application_status_config
    (status_key, display_label, badge_bg_color, badge_text_color, description, sort_order)
VALUES
    ('NEW',                             'BAHARU',                    '#dbeafe', '#1e40af', 'Permohonan baharu yang belum diproses.',                          1),
    ('DRAFT',                           'DRAF',                      '#e8f0fb', '#1b4f8f', 'Permohonan dalam draf, belum dihantar.',                          2),
    ('UNDER_REVIEW',                    'PERMOHONAN DITERIMA',       '#e0f2fe', '#0369a1', 'Permohonan diterima dan sedang dalam semakan awal.',              3),
    ('IN_PROGRESS',                     'DALAM PROSES',              '#ede9fe', '#7c3aed', 'Permohonan sedang dalam proses tindakan.',                        4),
    ('MENUNGGU_TINDAKAN_PENGARAH',      'MENUNGGU TINDAKAN PENGARAH','#fef9c3', '#854d0e', 'Dihantar kepada Pengarah untuk tindakan akhir.',                  5),
    ('MENUNGGU_SETERUSNYA_DILULUSKAN',  'MENUNGGU SETERUSNYA',       '#fde8d8', '#9a3412', 'Pengarah telah meluluskan; menunggu tindakan seterusnya Admin.',  6),
    ('MENUNGGU_SETERUSNYA_GAGAL',       'MENUNGGU SETERUSNYA',       '#fde8d8', '#9a3412', 'Pengarah gagalkan; menunggu tindakan seterusnya Admin.',          7),
    ('MENUNGGU_SETERUSNYA_GANTUNG',     'MENUNGGU SETERUSNYA',       '#fde8d8', '#9a3412', 'Pengarah gantungkan; menunggu tindakan seterusnya Admin.',        8),
    ('MENUNGGU_SETERUSNYA_BATAL',       'MENUNGGU SETERUSNYA',       '#fde8d8', '#9a3412', 'Pengarah batalkan; menunggu tindakan seterusnya Admin.',          9),
    ('APPROVED',                        'DILULUSKAN',                '#dff5e7', '#156b3c', 'Permohonan telah diluluskan sepenuhnya.',                        10),
    ('REJECTED',                        'DITOLAK',                   '#ffe1e4', '#9f1f2b', 'Permohonan telah ditolak.',                                      11),
    ('SUSPENDED',                       'DIGANTUNG',                 '#ececf2', '#4a4a60', 'Permohonan digantung sementara.',                                12),
    ('ARCHIVED',                        'DIARKIB',                   '#eef1f4', '#455867', 'Permohonan telah diarkibkan.',                                   13)
ON DUPLICATE KEY UPDATE
    display_label    = VALUES(display_label),
    badge_bg_color   = VALUES(badge_bg_color),
    badge_text_color = VALUES(badge_text_color),
    description      = VALUES(description),
    sort_order       = VALUES(sort_order);

USE sistemppa;

-- ============================================================
-- Add KPP Action Email Templates
-- These are used when admin sends tindakan KPP (KSPP / UJPPP / SIASATAN_ADUAN)
-- Placeholder: {{recipient_name}}, {{application}}, {{link}}
-- ============================================================

INSERT INTO email_templates (template_key, name, subject, body, description, variables) VALUES

('KPP_TINDAKAN_KSPP',
 'Tindakan KPP - Borang KSPP',
 'Tindakan Diperlukan: Borang KSPP - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p>
<p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p>
<p>Borang permohonan dirujuk: <strong>{{application}}</strong></p>
<p><strong>Tindakan diperlukan:</strong><br>
1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).</p>
<p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>
{{link}}</p>
<p>Terima kasih.</p>',
 'Dihantar kepada ahli KPP untuk mengisi Borang KSPP.',
 '{{recipient_name}}, {{application}}, {{link}}'
),

('KPP_TINDAKAN_UJPPP',
 'Tindakan KPP - Borang UJPPP',
 'Tindakan Diperlukan: Borang UJPPP - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p>
<p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p>
<p>Borang permohonan dirujuk: <strong>{{application}}</strong></p>
<p><strong>Tindakan diperlukan:</strong><br>
1) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).</p>
<p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>
{{link}}</p>
<p>Terima kasih.</p>',
 'Dihantar kepada ahli KPP untuk mengisi Borang UJPPP.',
 '{{recipient_name}}, {{application}}, {{link}}'
),

('KPP_TINDAKAN_KSPP_UJPPP',
 'Tindakan KPP - Borang KSPP & UJPPP',
 'Tindakan Diperlukan: Borang KSPP & UJPPP - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p>
<p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p>
<p>Borang permohonan dirujuk: <strong>{{application}}</strong></p>
<p><strong>Tindakan diperlukan:</strong><br>
1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).<br>
2) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).</p>
<p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>
{{link}}</p>
<p>Terima kasih.</p>',
 'Dihantar kepada ahli KPP untuk mengisi Borang KSPP dan UJPPP sekaligus.',
 '{{recipient_name}}, {{application}}, {{link}}'
),

('KPP_TINDAKAN_SIASATAN_ADUAN',
 'Tindakan KPP - Borang Siasatan Aduan',
 'Tindakan Diperlukan: Siasatan Aduan - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p>
<p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p>
<p>Borang permohonan dirujuk: <strong>{{application}}</strong></p>
<p><strong>Tindakan diperlukan:</strong><br>
1) Sila isi Borang Siasatan Aduan Pembekal dan Produk Air.</p>
<p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>
{{link}}</p>
<p>Terima kasih.</p>',
 'Dihantar kepada ahli KPP untuk menjalankan siasatan aduan.',
 '{{recipient_name}}, {{application}}, {{link}}'
)

ON DUPLICATE KEY UPDATE
    name        = VALUES(name),
    subject     = VALUES(subject),
    body        = VALUES(body),
    description = VALUES(description),
    variables   = VALUES(variables);

USE sistemppa;

INSERT INTO email_templates (template_key, name, subject, body, description, variables) VALUES

('EMAIL_VERIFICATION',
 'Pengesahan E-mel Pendaftaran',
 'PENGESAHAN ALAMAT E-MEL SISTEM PENDAFTARAN PRODUK AIR',
 '<p>Tuan/Puan {{full_name}},</p><p><strong>PENGESAHAN ALAMAT E-MEL SISTEM PENDAFTARAN PRODUK AIR</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. Sukacita dimaklumkan bahawa pendaftaran akaun tuan/puan telah diterima. Bagi melengkapkan proses pengaktifan akaun, sila sahkan alamat e-mel melalui pautan berikut: {{verify_link_html}}</p><p>3. Pautan pengesahan ini sah selama dua puluh empat (24) jam dari tarikh emel ini dihantar. Jika tuan/puan tidak membuat pendaftaran, sila abaikan emel ini.</p><p>Sekian, terima kasih.</p><p>Urusetia<br>Sistem Pendaftaran Produk Air</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon baharu selepas pendaftaran akaun untuk mengesahkan e-mel.',
 '{{full_name}}, {{verify_url}}, {{verify_link_html}}'
),

('DIRECTOR_ACTION_REQUEST',
 'Permintaan Tindakan kepada Pengarah',
 'PERMOHONAN UNTUK TINDAKAN PENGARAH BAGI {{app_ref}}',
 '<p>Tuan/Puan Pengarah {{director_name}},</p><p><strong>PERMOHONAN UNTUK {{review_stage_label}} PENGARAH</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. {{action_intro}}</p><p>3. Butiran permohonan adalah seperti berikut:</p><p>Pemohon : {{applicant_name}}<br>Syarikat : {{company_name}}<br>Produk : {{product_name}}<br>Tarikh Hantar : {{submitted_at}}<br>No. Rujukan : {{app_ref}}</p><p>4. Sila akses modul Pengarah melalui pautan berikut untuk tindakan lanjut: {{dashboard_link_html}}</p><p>5. Pautan penuh sekiranya diperlukan: {{dashboard_url}}</p><p>Sekian, terima kasih.</p><p>Urusetia<br>Sistem Pendaftaran Produk Air</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada Pengarah apabila terdapat permohonan yang memerlukan tindakan atau tindakan akhir.',
 '{{director_name}}, {{review_stage_label}}, {{action_intro}}, {{app_ref}}, {{applicant_name}}, {{company_name}}, {{product_name}}, {{submitted_at}}, {{dashboard_link_html}}, {{dashboard_url}}'
),

('PRESENTATION_APPLICANT',
 'Undangan Pembentangan kepada Pemohon',
 'UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR BAGI {{app_ref}}',
 '<p>Tuan/Puan {{full_name}},</p><p><strong>UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR BAGI {{app_ref}}</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. Sukacita dimaklumkan bahawa permohonan bagi produk <strong>{{product_name}}</strong> telah dijadualkan untuk sesi pembentangan pada ketetapan berikut:</p><p>Tarikh : {{presentation_date}}<br>Masa : {{presentation_time}}<br>Tempat : {{presentation_venue}}</p><p>3. Maklumat tambahan berkaitan sesi pembentangan adalah seperti berikut:</p>{{presentation_message_html}}<p>4. Tuan/puan adalah dimohon untuk memastikan kehadiran mengikut ketetapan yang dinyatakan.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila dijemput ke sesi pembentangan.',
 '{{full_name}}, {{app_ref}}, {{product_name}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}, {{presentation_message}}, {{presentation_message_html}}'
),

('PRESENTATION_KPP_INVITE',
 'Jemputan Pembentangan kepada KPP',
 'JEMPUTAN SESI PEMBENTANGAN BAGI {{app_ref}}',
 '<p>Tuan/Puan,</p><p><strong>JEMPUTAN SESI PEMBENTANGAN BAGI {{app_ref}}</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. Tuan/puan adalah dijemput untuk menghadiri sesi pembentangan bagi permohonan berkenaan pada ketetapan berikut:</p><p>Tarikh : {{presentation_date}}<br>Masa : {{presentation_time}}<br>Tempat : {{presentation_venue}}</p>{{memo_section}}<p>3. Kerjasama dan kehadiran tuan/puan dalam sesi tersebut amat dihargai.</p><p>Sekian, terima kasih.</p><p>Urusetia<br>Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP yang dijemput untuk hadir pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}, {{memo_section}}'
),

('PROFILE_REVIEW_APPROVED',
 'Semakan Profil Diluluskan',
 'MAKLUMAN KEPUTUSAN SEMAKAN PROFIL AKAUN SISTEM PENDAFTARAN PRODUK AIR',
 '<p>Tuan/Puan {{full_name}},</p><p><strong>MAKLUMAN KEPUTUSAN SEMAKAN PROFIL AKAUN SISTEM PENDAFTARAN PRODUK AIR</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. Sukacita dimaklumkan bahawa semakan profil bagi akaun {{display_id}} telah diluluskan.</p><p>3. Sehubungan itu, akaun tuan/puan kini telah diaktifkan dan boleh digunakan untuk mengakses dashboard serta fungsi sistem yang berkaitan.</p><p>Sekian, terima kasih.</p><p>Urusetia<br>Sistem Pendaftaran Produk Air</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila profil mereka diluluskan oleh Admin.',
 '{{full_name}}, {{display_id}}'
),

('PROFILE_REVIEW_REJECTED',
 'Semakan Profil Ditolak',
 'MAKLUMAN KEPUTUSAN SEMAKAN PROFIL AKAUN SISTEM PENDAFTARAN PRODUK AIR',
 '<p>Tuan/Puan {{full_name}},</p><p><strong>MAKLUMAN KEPUTUSAN SEMAKAN PROFIL AKAUN SISTEM PENDAFTARAN PRODUK AIR</strong></p><p>Dengan hormatnya perkara di atas adalah dirujuk.</p><p>2. Adalah dimaklumkan bahawa semakan profil bagi akaun {{display_id}} tidak dapat diluluskan pada masa ini.</p><p>3. Catatan semakan adalah seperti berikut: {{review_notes}}</p><p>4. Tuan/puan dimohon untuk mengemas kini maklumat profil dan menghantar semula bagi tujuan semakan lanjut.</p><p>Sekian, terima kasih.</p><p>Urusetia<br>Sistem Pendaftaran Produk Air</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila profil mereka ditolak oleh Admin.',
 '{{full_name}}, {{display_id}}, {{review_notes}}'
),

('KPP_TINDAKAN_KSPP_UJPPP',
 'Tindakan KPP - Borang KSPP dan UJPPP',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}}) - Permohonan Semakan dan Ulasan Teknikal Produk',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong><br>- Permohonan Semakan dan Ulasan Teknikal Produk</p><p>Dengan hormatnya saya merujuk kepada surat {{applicant_name}} rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} berkaitan perkara di atas.</p><p>2. Dimaklumkan bahawa permohonan pendaftaran oleh {{applicant_name}} bagi produk {{product_name}} (jenama: {{brand}}) telah diterima untuk proses selanjutnya dan memerlukan semakan melalui Borang KSPP serta Borang UJPPP.</p><p>3. Sehubungan itu, mohon kerjasama pihak tuan/puan untuk membuat semakan dan mengemukakan ulasan teknikal berhubung produk tersebut melalui pautan berikut: {{link_html}}.</p><p>4. Sila kemukakan maklum balas dalam tempoh tujuh (7) hari dari tarikh emel ini. Sekiranya maklum balas tidak diterima dalam tempoh yang ditetapkan, emel peringatan akan dijana secara automatik pada setiap minggu sehingga maklum balas diterima.</p><p>Sekian, terima kasih.</p><p>Urusetia,<br>Jawatankuasa Pendaftaran dan Pembekal Produk Bekalan Air<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk mengisi Borang KSPP dan UJPPP sekaligus.',
 '{{application_type_label}}, {{applicant_name}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{product_name}}, {{brand}}, {{link_html}}'
),

('KPP_TINDAKAN_SIASATAN_ADUAN',
 'Tindakan KPP - Borang Siasatan Aduan',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}}) - Permohonan Siasatan Aduan',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong><br>- Permohonan Siasatan Aduan</p><p>Dengan hormatnya saya merujuk kepada surat {{applicant_name}} rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} berkaitan perkara di atas.</p><p>2. Dimaklumkan bahawa terdapat keperluan untuk pihak tuan/puan menjalankan siasatan aduan berkaitan permohonan bagi produk {{product_name}} (jenama: {{brand}}).</p><p>3. Sehubungan itu, mohon kerjasama pihak tuan/puan untuk menyemak butiran berkaitan dan melengkapkan tindakan melalui pautan berikut: {{link_html}}.</p><p>4. Sila kemukakan maklum balas dalam tempoh tujuh (7) hari dari tarikh emel ini. Sekiranya maklum balas tidak diterima dalam tempoh yang ditetapkan, emel peringatan akan dijana secara automatik pada setiap minggu sehingga maklum balas diterima.</p><p>Sekian, terima kasih.</p><p>Urusetia,<br>Jawatankuasa Pendaftaran dan Pembekal Produk Bekalan Air<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk menjalankan siasatan aduan.',
 '{{application_type_label}}, {{applicant_name}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{product_name}}, {{brand}}, {{link_html}}'
)

ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    subject = VALUES(subject),
    body = VALUES(body),
    description = VALUES(description),
    variables = VALUES(variables);
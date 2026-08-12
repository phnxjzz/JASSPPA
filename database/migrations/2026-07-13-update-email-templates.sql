USE sistemppa;

INSERT INTO email_templates (template_key, name, subject, body, description, variables) VALUES

('APPLICATION_RECEIVED',
 'Permohonan Diterima',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Sukacita dimaklumkan bahawa permohonan pendaftaran diterima untuk diproses ke peringkat seterusnya. Tuan/puan akan dihubungi sekiranya terdapat keperluan maklumat tambahan berkaitan permohonan ini.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan diterima untuk proses seterusnya.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}'
),

('APPLICATION_REJECTED',
 'Permohonan Ditolak',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Setelah semakan dibuat, pihak Jabatan mendapati bahawa produk yang dikemukakan tidak diperlukan bagi kegunaan semasa Jabatan. Sehubungan itu, permohonan ini adalah {{status_label_lower}} dan tidak akan diproses ke peringkat seterusnya.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan ditolak.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{status_label_lower}}'
),

('APPLICATION_SUSPENDED',
 'Permohonan Digantung',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Setelah semakan dibuat, pihak Jabatan mendapati bahawa produk yang dikemukakan tidak diperlukan bagi kegunaan semasa Jabatan. Sehubungan itu, permohonan ini adalah {{status_label_lower}} dan tidak akan diproses ke peringkat seterusnya.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan digantung.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{status_label_lower}}'
),

('APPLICATION_ARCHIVED',
 'Permohonan Dibatalkan/Diarkib',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Setelah semakan dibuat, pihak Jabatan mendapati bahawa produk yang dikemukakan tidak diperlukan bagi kegunaan semasa Jabatan. Sehubungan itu, permohonan ini adalah {{status_label_lower}} dan tidak akan diproses ke peringkat seterusnya.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan dibatalkan atau diarkibkan.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{status_label_lower}}'
),

('APPLICATION_APPROVED',
 'Permohonan Diluluskan',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>Sukacita dimaklumkan bahawa permohonan ini adalah diluluskan dan didaftarkan untuk kegunaan Jabatan tertakluk kepada syarat serta ketetapan yang sedang berkuat kuasa.</p><p>No. Perakuan Pendaftaran: <strong>{{cert_ref}}</strong></p><p>Tuan/puan boleh log masuk ke sistem untuk melihat dan mencetak perakuan pendaftaran yang berkaitan.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila permohonan diluluskan.',
 '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{cert_ref}}'
),

('PRESENTATION_APPLICANT',
 'Undangan Pembentangan kepada Pemohon',
 'UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR UNTUK PERMOHONAN {{application_type_label}} {{app_ref}}',
 '<p>No. Rujukan : {{no_rujukan_surat}}</p><p>Tarikh : {{tarikh_surat}}</p><p>{{full_name}}<br>{{alamat_pemohon}}</p><p>Tuan/Puan,</p><p>Nama Produk : {{product_name}}<br>Jenama : {{brand}}</p><p><strong>UNDANGAN KE SESI PEMBENTANGAN PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR UNTUK PERMOHONAN {{application_type_label}} {{app_ref}}</strong></p><p>Dengan hormatnya, saya merujuk perkara tersebut di atas.</p><p>2. Sukacita dimaklumkan bahawa syarikat tuan/puan adalah dijemput untuk membuat pembentangan berkaitan permohonan tersebut pada ketetapan seperti berikut:</p><p>Tarikh : {{presentation_date}} ({{presentation_day}})<br>Masa : {{presentation_time}}<br>Tempat : {{presentation_venue}}</p><p>Pembentangan produk adalah wajib bagi semua permohonan baharu serta pembaharuan yang telah tamat tempoh sah laku. Sila buat pengesahan kehadiran melalui pautan ini : {{attendance_link_html}}</p><p>Sekian dan terima kasih.</p><p>"MALAYSIA MADANI"<br>"BERKHIDMAT UNTUK NEGARA"</p><p>Saya yang menjalankan amanah</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila dijemput ke sesi pembentangan.',
 '{{no_rujukan_surat}}, {{tarikh_surat}}, {{full_name}}, {{alamat_pemohon}}, {{product_name}}, {{brand}}, {{application_type_label}}, {{app_ref}}, {{presentation_date}}, {{presentation_day}}, {{presentation_time}}, {{presentation_venue}}, {{attendance_link_html}}'
),

('PRESENTATION_RESCHEDULE_APPLICANT',
 'Penjadualan Semula Pembentangan kepada Pemohon',
 'PENJADUALAN SEMULA SESI PEMBENTANGAN PERMOHONAN',
 '<p>{{full_name}}<br>{{alamat_pemohon}}</p><p><strong>PENJADUALAN SEMULA SESI PEMBENTANGAN PERMOHONAN</strong></p><p>Dengan hormatnya perkara di atas dirujuk.</p><p>2. Adalah dimaklumkan bahawa pihak Jabatan telah menerima permohonan penangguhan sesi pembentangan daripada pihak syarikat tuan/puan.</p><p>3. Sehubungan itu, pihak Jabatan bersetuju untuk menetapkan semula sesi pembentangan seperti ketetapan berikut:</p><p>Tarikh : {{presentation_date}} ({{presentation_day}})<br>Masa : {{presentation_time}}<br>Tempat : {{presentation_venue}}</p><p>4. Syarikat tuan/puan adalah DIKEHENDAKI hadir pada tarikh dan masa yang telah ditetapkan. Sebarang permohonan penangguhan lanjut tidak akan dipertimbangkan.</p><p>Sekian dan terima kasih.</p><p>"MALAYSIA MADANI"<br>"BERKHIDMAT UNTUK NEGARA"</p><p>Saya yang menjalankan amanah</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada pemohon apabila sesi pembentangan dijadualkan semula.',
 '{{full_name}}, {{alamat_pemohon}}, {{presentation_date}}, {{presentation_day}}, {{presentation_time}}, {{presentation_venue}}'
),

('PRESENTATION_KPP_INVITE',
 'Jemputan Pembentangan kepada KPP',
 'Jemputan Pembentangan Permohonan {{app_ref}} - SPPPBA',
 '<p>Salam sejahtera,</p><p>Tuan/Puan dijemput untuk pembentangan permohonan {{app_ref}}.</p><p><strong>Tarikh:</strong> {{presentation_date}}<br><strong>Masa:</strong> {{presentation_time}}<br><strong>Tempat:</strong> {{presentation_venue}}</p>{{memo_section}}<p>Terima kasih.</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP yang dijemput untuk hadir pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}, {{memo_section}}'
),

('KPP_TINDAKAN_UJPPP',
 'Tindakan KPP - Borang UJPPP',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}}) - Permohonan Semakan dan Ulasan Teknikal Produk',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong><br>- Permohonan Semakan dan Ulasan Teknikal Produk</p><p>Dengan hormatnya saya merujuk kepada surat {{applicant_name}} rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} berkaitan perkara di atas.</p><p>2. Dimaklumkan bahawa pembentangan bagi permohonan pendaftaran oleh {{applicant_name}} bagi produk {{product_name}} (jenama: {{brand}}) telah diadakan pada {{presentation_date}}.</p><p>3. Sehubungan itu, mohon kerjasama pihak tuan/puan untuk membuat semakan dan mengemukakan ulasan teknikal berhubung produk tersebut bagi tujuan penyediaan syor untuk pertimbangan dalam Mesyuarat Jawatankuasa Pendaftaran Pembekal dan Produk yang akan datang. Dokumen permohonan berkaitan boleh disemak melalui pautan berikut: {{link_html}}.</p><p>4. Sila kemukakan maklum balas dalam tempoh tujuh (7) hari dari tarikh emel ini. Sekiranya maklum balas tidak diterima dalam tempoh yang ditetapkan, emel peringatan akan dijana secara automatik pada setiap minggu sehingga maklum balas diterima.</p><p>Sekian, terima kasih.</p><p>Urusetia,<br>Jawatankuasa Pendaftaran dan Pembekal Produk Bekalan Air<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk semakan dan ulasan teknikal UJPPP.',
 '{{application_type_label}}, {{applicant_name}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{product_name}}, {{brand}}, {{presentation_date}}, {{link_html}}'
),

('KPP_TINDAKAN_KSPP',
 'Tindakan KPP - Borang KSPP',
 'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}}) - Permohonan Semakan dan Ulasan Teknikal Produk',
 '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong><br>- Permohonan Semakan dan Ulasan Teknikal Produk</p><p>Dengan hormatnya saya merujuk kepada surat {{applicant_name}} rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} berkaitan perkara di atas.</p><p>2. Dimaklumkan bahawa permohonan {{application_type_label_lower}} pendaftaran oleh {{applicant_name}} bagi produk {{product_name}} (jenama: {{brand}}) telah diterima untuk proses selanjutnya.</p><p>3. Sehubungan itu, mohon kerjasama pihak tuan/puan untuk membuat semakan dan mengemukakan ulasan teknikal berhubung produk tersebut bagi tujuan penyediaan syor untuk pertimbangan dalam Mesyuarat Jawatankuasa Pendaftaran Pembekal dan Produk yang akan datang. Dokumen permohonan berkaitan boleh disemak melalui pautan berikut: {{link_html}}.</p><p>4. Sila kemukakan maklum balas dalam tempoh tujuh (7) hari dari tarikh emel ini. Sekiranya maklum balas tidak diterima dalam tempoh yang ditetapkan, emel peringatan akan dijana secara automatik pada setiap minggu sehingga maklum balas diterima.</p><p>Sekian, terima kasih.</p><p>Urusetia,<br>Jawatankuasa Pendaftaran dan Pembekal Produk Bekalan Air<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk Borang Kaji Selidik Prestasi Pembekal dan Produk.',
 '{{application_type_label}}, {{application_type_label_lower}}, {{applicant_name}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{product_name}}, {{brand}}, {{link_html}}'
),

('KPP_TINDAKAN_KSPP_UJPPP',
 'Tindakan KPP - Borang KSPP & UJPPP',
 'Tindakan Diperlukan: Borang KSPP & UJPPP - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p><p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p><p>Borang permohonan dirujuk: <strong>{{application}}</strong></p><p><strong>Tindakan diperlukan:</strong><br>1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).<br>2) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).</p><p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>{{link_html}}</p><p>Terima kasih.</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk mengisi Borang KSPP dan UJPPP sekaligus.',
 '{{recipient_name}}, {{application}}, {{link_html}}'
),

('KPP_TINDAKAN_SIASATAN_ADUAN',
 'Tindakan KPP - Borang Siasatan Aduan',
 'Tindakan Diperlukan: Siasatan Aduan - {{application}} - SPPPBA',
 '<p>Assalamualaikum dan salam sejahtera {{recipient_name}},</p><p>Admin SPPPBA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.</p><p>Borang permohonan dirujuk: <strong>{{application}}</strong></p><p><strong>Tindakan diperlukan:</strong><br>1) Sila isi Borang Siasatan Aduan Pembekal dan Produk Air.</p><p>Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:<br>{{link_html}}</p><p>Terima kasih.</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
 'Dihantar kepada ahli KPP untuk menjalankan siasatan aduan.',
 '{{recipient_name}}, {{application}}, {{link_html}}'
)

ON DUPLICATE KEY UPDATE
	name = VALUES(name),
	subject = VALUES(subject),
	body = VALUES(body),
	description = VALUES(description),
	variables = VALUES(variables);

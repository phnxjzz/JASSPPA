USE sistemppa;

INSERT INTO email_templates (template_key, name, subject, body, description, variables)
VALUES
(
  'APPLICATION_RECEIVED',
  'Permohonan Diterima',
  'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
  '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>2. Sukacita dimaklumkan bahawa permohonan bagi produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah diterima dan sedang diproses untuk tindakan seterusnya.</p><p>3. Tuan/puan akan dimaklumkan sekiranya terdapat keperluan maklumat tambahan berkaitan permohonan ini.</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
  'Dihantar kepada pemohon apabila permohonan diterima untuk proses seterusnya.',
  '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{full_name}}, {{product_name}}, {{app_ref}}'
),
(
  'APPLICATION_REJECTED',
  'Permohonan Ditolak',
  'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
  '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>2. Adalah dimaklumkan bahawa permohonan bagi produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) tidak dapat dipertimbangkan dan adalah ditolak.</p><p>3. Catatan semakan: {{admin_notes}}</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
  'Dihantar kepada pemohon apabila permohonan ditolak.',
  '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
),
(
  'APPLICATION_SUSPENDED',
  'Permohonan Digantung',
  'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
  '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>2. Adalah dimaklumkan bahawa permohonan bagi produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) digantung sementara untuk tindakan lanjut.</p><p>3. Catatan semakan: {{admin_notes}}</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
  'Dihantar kepada pemohon apabila permohonan digantung sementara.',
  '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
),
(
  'APPLICATION_ARCHIVED',
  'Permohonan Dibatalkan/Diarkib',
  'PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})',
  '<p><strong>PERMOHONAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR ({{application_type_label}})</strong></p><p>Dengan hormatnya saya merujuk surat tuan/puan rujukan {{no_rujukan_surat}} bertarikh {{tarikh_surat}} mengenai perkara di atas.</p><p>2. Adalah dimaklumkan bahawa permohonan bagi produk <strong>{{product_name}}</strong> (No. Rujukan: {{app_ref}}) telah dibatalkan.</p><p>3. Catatan semakan: {{admin_notes}}</p><p>Sekian, terima kasih.</p><p>Saya yang menjalankan amanah,</p><p><strong>(CHEE CHUN CHIEH)</strong><br>Pengarah<br>Jabatan Air Negeri Sabah</p><p>Surat ini merupakan cetakan komputer dan tidak memerlukan tandatangan.</p>',
  'Dihantar kepada pemohon apabila permohonan dibatalkan/diarkib.',
  '{{application_type_label}}, {{no_rujukan_surat}}, {{tarikh_surat}}, {{full_name}}, {{product_name}}, {{app_ref}}, {{admin_notes}}'
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  subject = VALUES(subject),
  body = VALUES(body),
  description = VALUES(description),
  variables = VALUES(variables);

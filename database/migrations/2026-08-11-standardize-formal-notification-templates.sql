INSERT INTO notification_templates (template_key, name, message, description, variables) VALUES
('NOTIF_APPLICATION_APPROVED',
 'Notifikasi: Permohonan Diluluskan',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah diluluskan. Perakuan Pendaftaran {{cert_ref}} telah dikeluarkan. Sila rujuk dashboard untuk maklumat lanjut.',
 'Notifikasi rasmi kepada pemohon apabila permohonan diluluskan.',
 '{{app_ref}}, {{cert_ref}}'
),
('NOTIF_APPLICATION_RECEIVED',
 'Notifikasi: Permohonan Diterima',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah diterima dan sedang menunggu tindakan semakan lanjut. Sila rujuk dashboard dari semasa ke semasa.',
 'Notifikasi rasmi kepada pemohon apabila permohonan diterima untuk semakan.',
 '{{app_ref}}'
),
('NOTIF_APPLICATION_REJECTED',
 'Notifikasi: Permohonan Ditolak',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah ditolak.{{notes_section}} Sila rujuk dashboard untuk tindakan selanjutnya.',
 'Notifikasi rasmi kepada pemohon apabila permohonan ditolak.',
 '{{app_ref}}, {{notes_section}}, {{admin_notes}}'
),
('NOTIF_APPLICATION_SUSPENDED',
 'Notifikasi: Permohonan Digantung',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah digantung. Sila rujuk dashboard untuk maklumat lanjut.',
 'Notifikasi rasmi kepada pemohon apabila permohonan digantung.',
 '{{app_ref}}'
),
('NOTIF_APPLICATION_ARCHIVED',
 'Notifikasi: Permohonan Dibatalkan',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah dibatalkan. Sila rujuk dashboard untuk maklumat lanjut.',
 'Notifikasi rasmi kepada pemohon apabila permohonan dibatalkan atau diarkibkan.',
 '{{app_ref}}'
),
('NOTIF_APPLICATION_STATUS_GENERIC',
 'Notifikasi: Kemaskini Status Permohonan',
 'Adalah dimaklumkan bahawa status permohonan {{app_ref}} telah dikemas kini kepada {{status}}. Sila rujuk dashboard untuk maklumat lanjut.',
 'Notifikasi rasmi generik apabila status permohonan berubah.',
 '{{app_ref}}, {{status}}'
),
('NOTIF_PRESENTATION_APPLICANT',
 'Notifikasi Pembentangan: Makluman kepada Pemohon',
 'Adalah dimaklumkan bahawa sesi pembentangan bagi permohonan {{app_ref}} telah dijadualkan seperti berikut:\nTarikh: {{presentation_date}}\nMasa: {{presentation_time}}\nTempat: {{presentation_venue}}\nSila hadir mengikut ketetapan yang dinyatakan.',
 'Notifikasi rasmi dalam sistem kepada pemohon berserta maklumat pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}'
),
('NOTIF_PRESENTATION_KPP',
 'Notifikasi Pembentangan: Jemputan kepada KPP',
 'Adalah dimaklumkan bahawa sesi pembentangan bagi permohonan {{app_ref}} akan diadakan pada ketetapan berikut:\nTarikh: {{presentation_date}}\nMasa: {{presentation_time}}\nTempat: {{presentation_venue}}\nKerjasama tuan/puan untuk hadir adalah dihargai.',
 'Notifikasi rasmi dalam sistem kepada ahli KPP yang dijemput untuk pembentangan.',
 '{{app_ref}}, {{presentation_date}}, {{presentation_time}}, {{presentation_venue}}'
),
('NOTIF_PROFILE_APPROVED',
 'Notifikasi: Profil Diluluskan',
 'Adalah dimaklumkan bahawa maklumat profil anda telah diluluskan. Akaun anda kini boleh mengakses dashboard dan fungsi sistem.',
 'Notifikasi rasmi kepada pengguna apabila profil mereka diluluskan.',
 '{{display_id}}'
),
('NOTIF_PROFILE_REJECTED',
 'Notifikasi: Profil Ditolak',
 'Adalah dimaklumkan bahawa semakan maklumat profil anda tidak dapat diluluskan. Sebab semakan: {{review_notes}}. Sila kemas kini maklumat berkaitan dan cuba semula.',
 'Notifikasi rasmi kepada pengguna apabila profil mereka ditolak.',
 '{{review_notes}}'
),
('NOTIF_DIRECTOR_ACCEPT',
 'Notifikasi: Permohonan Menunggu Semakan Admin',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah diterima oleh Pengarah dan kini berada dalam semakan Admin. Sila rujuk dashboard untuk tindakan lanjut.',
 'Notifikasi rasmi kepada Admin atau pemohon selepas tindakan awal Pengarah.',
 '{{app_ref}}'
),
('NOTIF_DIRECTOR_DECISION',
 'Notifikasi: Keputusan Pengarah Direkodkan',
 'Adalah dimaklumkan bahawa keputusan Pengarah bagi permohonan {{app_ref}} telah direkodkan. {{next_step}}',
 'Notifikasi rasmi apabila Pengarah selesai mengambil tindakan.',
 '{{app_ref}}, {{next_step}}, {{result_label}}, {{notes_section}}'
),
('NOTIF_DIRECTOR_FINAL_REVIEW_PENDING',
 'Notifikasi: Permohonan Dihantar untuk Tindakan Akhir Pengarah',
 'Adalah dimaklumkan bahawa permohonan {{app_ref}} telah dikemukakan kepada Pengarah untuk tindakan akhir. Sila rujuk dashboard bagi status terkini.',
 'Notifikasi rasmi kepada pemohon apabila permohonan dihantar untuk tindakan akhir Pengarah.',
 '{{app_ref}}'
),
('NOTIF_PRESENTATION_RESPONSE_ATTEND',
 'Notifikasi: Pengesahan Kehadiran Pembentangan',
 'Adalah dimaklumkan bahawa pemohon telah mengesahkan kehadiran bagi sesi pembentangan {{app_ref}}. Wakil: {{representative_name}}. Bilangan peserta: {{attendee_count}}.',
 'Notifikasi rasmi kepada Admin apabila pemohon mengesahkan kehadiran pembentangan.',
 '{{app_ref}}, {{representative_name}}, {{attendee_count}}'
),
('NOTIF_PRESENTATION_RESPONSE_ABSENT',
 'Notifikasi: Ketidakhadiran Pembentangan',
 'Adalah dimaklumkan bahawa pemohon tidak dapat hadir bagi sesi pembentangan {{app_ref}}. Sebab: {{absence_reason}}. Sila pertimbangkan penjadualan semula.',
 'Notifikasi rasmi kepada Admin apabila pemohon tidak dapat hadir pembentangan.',
 '{{app_ref}}, {{absence_reason}}'
)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    message = VALUES(message),
    description = VALUES(description),
    variables = VALUES(variables),
    updated_at = NOW();
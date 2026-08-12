USE sistemppa;

INSERT INTO app_runtime_settings (setting_key, setting_value, enabled, description)
VALUES
    ('user_dashboard_decision_popup_enabled', 'true', 1, 'Enable one-time decision popup on user dashboard for unread status notifications'),
    ('user_dashboard_decision_popup_approve_icon', '/icon/stamp.gif', 1, 'Icon path for approval popup on user dashboard'),
    ('user_dashboard_decision_popup_reject_icon', '/icon/exit.png', 1, 'Icon path for rejected/suspended popup close button on user dashboard'),
    ('user_dashboard_decision_popup_approve_button_text', 'Lihat Perakuan', 1, 'Primary button text for approval popup on user dashboard')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    enabled = VALUES(enabled),
    description = VALUES(description),
    updated_at = CURRENT_TIMESTAMP;

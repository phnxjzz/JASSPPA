SET @users_supporting_doc_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'supporting_document_url'
);
SET @users_supporting_doc_sql := IF(@users_supporting_doc_exists = 0,
    'ALTER TABLE users ADD COLUMN supporting_document_url VARCHAR(255) NULL AFTER avatar_url',
    'SELECT 1');
PREPARE stmt_users_supporting_doc FROM @users_supporting_doc_sql;
EXECUTE stmt_users_supporting_doc;
DEALLOCATE PREPARE stmt_users_supporting_doc;

SET @users_profile_status_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'profile_review_status'
);
SET @users_profile_status_sql := IF(@users_profile_status_exists = 0,
    'ALTER TABLE users ADD COLUMN profile_review_status ENUM(''DRAFT'',''PENDING_REVIEW'',''APPROVED'',''REJECTED'') NOT NULL DEFAULT ''DRAFT'' AFTER supporting_document_url',
    'SELECT 1');
PREPARE stmt_users_profile_status FROM @users_profile_status_sql;
EXECUTE stmt_users_profile_status;
DEALLOCATE PREPARE stmt_users_profile_status;

SET @users_profile_submitted_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'profile_submitted_at'
);
SET @users_profile_submitted_sql := IF(@users_profile_submitted_exists = 0,
    'ALTER TABLE users ADD COLUMN profile_submitted_at TIMESTAMP NULL AFTER profile_review_status',
    'SELECT 1');
PREPARE stmt_users_profile_submitted FROM @users_profile_submitted_sql;
EXECUTE stmt_users_profile_submitted;
DEALLOCATE PREPARE stmt_users_profile_submitted;

SET @users_profile_reviewed_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'profile_reviewed_at'
);
SET @users_profile_reviewed_sql := IF(@users_profile_reviewed_exists = 0,
    'ALTER TABLE users ADD COLUMN profile_reviewed_at TIMESTAMP NULL AFTER profile_submitted_at',
    'SELECT 1');
PREPARE stmt_users_profile_reviewed FROM @users_profile_reviewed_sql;
EXECUTE stmt_users_profile_reviewed;
DEALLOCATE PREPARE stmt_users_profile_reviewed;

SET @users_profile_reviewed_by_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'profile_reviewed_by'
);
SET @users_profile_reviewed_by_sql := IF(@users_profile_reviewed_by_exists = 0,
    'ALTER TABLE users ADD COLUMN profile_reviewed_by INT NULL AFTER profile_reviewed_at',
    'SELECT 1');
PREPARE stmt_users_profile_reviewed_by FROM @users_profile_reviewed_by_sql;
EXECUTE stmt_users_profile_reviewed_by;
DEALLOCATE PREPARE stmt_users_profile_reviewed_by;

SET @users_profile_notes_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'profile_review_notes'
);
SET @users_profile_notes_sql := IF(@users_profile_notes_exists = 0,
    'ALTER TABLE users ADD COLUMN profile_review_notes TEXT NULL AFTER profile_reviewed_by',
    'SELECT 1');
PREPARE stmt_users_profile_notes FROM @users_profile_notes_sql;
EXECUTE stmt_users_profile_notes;
DEALLOCATE PREPARE stmt_users_profile_notes;

SET @users_profile_status_idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND index_name = 'idx_profile_review_status'
);
SET @users_profile_status_idx_sql := IF(@users_profile_status_idx_exists = 0,
    'CREATE INDEX idx_profile_review_status ON users(profile_review_status)',
    'SELECT 1');
PREPARE stmt_users_profile_status_idx FROM @users_profile_status_idx_sql;
EXECUTE stmt_users_profile_status_idx;
DEALLOCATE PREPARE stmt_users_profile_status_idx;

UPDATE users
SET profile_review_status = 'APPROVED'
WHERE role = 'USER'
  AND (profile_review_status IS NULL OR profile_review_status = 'DRAFT');

UPDATE users
SET profile_review_status = 'APPROVED'
WHERE role IN ('ADMIN', 'STAFF')
  AND (profile_review_status IS NULL OR profile_review_status = 'DRAFT');
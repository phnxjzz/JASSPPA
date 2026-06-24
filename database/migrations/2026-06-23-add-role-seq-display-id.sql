-- Role-based display numbering for users (ADM001 / P001 / STF001)
-- Keeps users.id as technical PK and introduces users.role_seq for user-facing numbering.

SET @col_exists := (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'role_seq'
);
SET @col_sql := IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN role_seq INT NULL AFTER role',
    'SELECT 1');
PREPARE stmt_col FROM @col_sql;
EXECUTE stmt_col;
DEALLOCATE PREPARE stmt_col;

-- Backfill existing rows with contiguous numbering per role by creation order (id).
UPDATE users u
JOIN (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY role ORDER BY id) AS seq_no
    FROM users
) ranked ON ranked.id = u.id
SET u.role_seq = ranked.seq_no
WHERE u.role_seq IS NULL OR u.role_seq <= 0;

-- Ensure role_seq is populated going forward.
ALTER TABLE users
    MODIFY COLUMN role_seq INT NOT NULL;

-- Ensure uniqueness of display number inside each role.
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND index_name = 'uniq_role_role_seq'
);
SET @idx_sql := IF(@idx_exists = 0,
    'CREATE UNIQUE INDEX uniq_role_role_seq ON users(role, role_seq)',
    'SELECT 1');
PREPARE stmt_idx FROM @idx_sql;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;

DROP TRIGGER IF EXISTS trg_users_role_seq_before_insert;
DROP TRIGGER IF EXISTS trg_users_before_insert_role_seq;
DROP TRIGGER IF EXISTS trg_users_before_update_role_seq;

DELIMITER $$
CREATE TRIGGER trg_users_before_insert_role_seq
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    DECLARE next_seq INT;

    IF NEW.role_seq IS NULL OR NEW.role_seq <= 0 THEN
        SELECT COALESCE(MIN(c.candidate_seq), 1)
        INTO next_seq
        FROM (
            SELECT 1 AS candidate_seq
            UNION ALL
            SELECT u.role_seq + 1
            FROM users u
            WHERE u.role = NEW.role
              AND u.role_seq IS NOT NULL
        ) c
        LEFT JOIN users e
            ON e.role = NEW.role
           AND e.role_seq = c.candidate_seq
        WHERE e.role_seq IS NULL;

        SET NEW.role_seq = next_seq;
    END IF;
END$$

CREATE TRIGGER trg_users_before_update_role_seq
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    DECLARE next_seq INT;

    IF NEW.role <> OLD.role OR NEW.role_seq IS NULL OR NEW.role_seq <= 0 THEN
        SELECT COALESCE(MIN(c.candidate_seq), 1)
        INTO next_seq
        FROM (
            SELECT 1 AS candidate_seq
            UNION ALL
            SELECT u.role_seq + 1
            FROM users u
            WHERE u.role = NEW.role
              AND u.id <> OLD.id
              AND u.role_seq IS NOT NULL
        ) c
        LEFT JOIN users e
            ON e.role = NEW.role
           AND e.id <> OLD.id
           AND e.role_seq = c.candidate_seq
        WHERE e.role_seq IS NULL;

        SET NEW.role_seq = next_seq;
    END IF;
END$$
DELIMITER ;

-- Normalize existing admin audit details from ADM{id} to ADM{role_seq}.
UPDATE audit_log al
JOIN users u ON u.id = al.user_id
SET al.details = REPLACE(
        al.details,
        CONCAT('ADM', LPAD(u.id, 3, '0')),
        CONCAT('ADM', LPAD(u.role_seq, 3, '0'))
    )
WHERE u.role = 'ADMIN'
  AND al.details IS NOT NULL
  AND al.details LIKE '%ADM%';

-- Normalize older legacy admin format A{id} -> ADM{role_seq}.
UPDATE audit_log al
JOIN users u ON u.id = al.user_id
SET al.details = REPLACE(
                al.details,
                CONCAT('A', LPAD(u.id, 3, '0')),
                CONCAT('ADM', LPAD(u.role_seq, 3, '0'))
        )
WHERE u.role = 'ADMIN'
    AND al.details IS NOT NULL
    AND al.details LIKE CONCAT('%A', LPAD(u.id, 3, '0'), '%');

-- Expose display_id directly in users table for easier database verification.
SET @display_col_exists := (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND column_name = 'display_id'
);
SET @display_col_sql := IF(@display_col_exists = 0,
        'ALTER TABLE users ADD COLUMN display_id VARCHAR(20) GENERATED ALWAYS AS (CONCAT(CASE role WHEN ''ADMIN'' THEN ''ADM'' WHEN ''STAFF'' THEN ''STF'' ELSE ''P'' END, LPAD(role_seq,3,''0''))) STORED',
        'SELECT 1');
PREPARE stmt_display_col FROM @display_col_sql;
EXECUTE stmt_display_col;
DEALLOCATE PREPARE stmt_display_col;

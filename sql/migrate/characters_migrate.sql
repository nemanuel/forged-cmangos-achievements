-- ============================================================
-- Achievements Module — Characters DB Migration
-- Idempotent: safe to run multiple times.
-- ============================================================

-- character_achievement
CREATE TABLE IF NOT EXISTS `character_achievement` (
    `guid`        INT(10) UNSIGNED NOT NULL,
    `achievement` SMALLINT(5) UNSIGNED NOT NULL,
    `date`        INT(10) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`guid`, `achievement`),
    INDEX `idx_achievement` (`achievement`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Per-character completed achievements';

-- Add index on achievement column if it does not yet exist
-- (handles databases upgraded from the old schema without the index)
SET @db   = DATABASE();
SET @tbl  = 'character_achievement';
SET @idx  = 'idx_achievement';
SET @sql  = IF(
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = @db AND TABLE_NAME = @tbl AND INDEX_NAME = @idx) = 0,
    CONCAT('ALTER TABLE `', @tbl, '` ADD INDEX `', @idx, '` (`achievement`)'),
    'SELECT ''index idx_achievement already exists'' AS info'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- character_achievement_progress
CREATE TABLE IF NOT EXISTS `character_achievement_progress` (
    `guid`     INT(10) UNSIGNED NOT NULL,
    `criteria` SMALLINT(5) UNSIGNED NOT NULL,
    `counter`  INT(10) UNSIGNED NOT NULL,
    `date`     INT(10) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`guid`, `criteria`),
    INDEX `idx_criteria` (`criteria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Per-character achievement criteria progress';

-- Add index on criteria column if it does not yet exist
SET @tbl = 'character_achievement_progress';
SET @idx = 'idx_criteria';
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = @db AND TABLE_NAME = @tbl AND INDEX_NAME = @idx) = 0,
    CONCAT('ALTER TABLE `', @tbl, '` ADD INDEX `', @idx, '` (`criteria`)'),
    'SELECT ''index idx_criteria already exists'' AS info'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- AlterTable
ALTER TABLE `recommendation` ADD COLUMN `hasCurrentProducts` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `isEffective` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `productAnalysis` LONGTEXT NULL;

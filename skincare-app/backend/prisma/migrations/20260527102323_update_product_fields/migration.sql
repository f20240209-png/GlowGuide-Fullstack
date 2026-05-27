-- AlterTable
ALTER TABLE `product` ADD COLUMN `discount` VARCHAR(191) NULL,
    ADD COLUMN `imageUrl` TEXT NULL,
    ADD COLUMN `ingredients` LONGTEXT NULL,
    ADD COLUMN `originalPrice` DOUBLE NOT NULL DEFAULT 0,
    ADD COLUMN `productUrl` TEXT NULL,
    ADD COLUMN `reviewCount` INTEGER NOT NULL DEFAULT 0,
    MODIFY `name` TEXT NOT NULL,
    MODIFY `price` DOUBLE NOT NULL DEFAULT 0,
    MODIFY `availableAt` VARCHAR(191) NOT NULL DEFAULT 'Nykaa, Amazon, Flipkart';

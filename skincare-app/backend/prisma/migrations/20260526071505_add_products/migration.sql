-- CreateTable
CREATE TABLE `Product` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(191) NOT NULL,
    `brand` VARCHAR(191) NOT NULL,
    `category` VARCHAR(191) NOT NULL,
    `price` DOUBLE NOT NULL,
    `skinTypes` VARCHAR(191) NOT NULL,
    `skinGoals` VARCHAR(191) NOT NULL,
    `description` TEXT NOT NULL,
    `howToUse` TEXT NOT NULL,
    `availableAt` VARCHAR(191) NOT NULL,
    `rating` DOUBLE NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

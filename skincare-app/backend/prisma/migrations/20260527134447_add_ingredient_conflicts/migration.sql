-- CreateTable
CREATE TABLE `Ingredient_Conflict` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `ingredient_a` VARCHAR(191) NOT NULL,
    `ingredient_b` VARCHAR(191) NOT NULL,
    `severity_level` VARCHAR(191) NOT NULL,
    `warning_message` TEXT NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Ingredient_Conflict_ingredient_a_ingredient_b_key`(`ingredient_a`, `ingredient_b`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

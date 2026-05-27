/*
  Warnings:

  - A unique constraint covering the columns `[googleId]` on the table `User` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE `user` ADD COLUMN `googleId` VARCHAR(191) NULL,
    MODIFY `password` VARCHAR(191) NULL;

-- CreateTable
CREATE TABLE `SkincareLog` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `userId` INTEGER NOT NULL,
    `timeOfDay` VARCHAR(191) NOT NULL,
    `productsUsed` TEXT NOT NULL,
    `notes` TEXT NULL,
    `photo` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE UNIQUE INDEX `User_googleId_key` ON `User`(`googleId`);

-- AddForeignKey
ALTER TABLE `SkincareLog` ADD CONSTRAINT `SkincareLog_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

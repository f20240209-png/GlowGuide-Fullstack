-- DropForeignKey
ALTER TABLE `profile` DROP FOREIGN KEY `Profile_userId_fkey`;

-- DropForeignKey
ALTER TABLE `recommendation` DROP FOREIGN KEY `Recommendation_profileId_fkey`;

-- DropForeignKey
ALTER TABLE `skincarelog` DROP FOREIGN KEY `SkincareLog_userId_fkey`;

-- DropIndex
DROP INDEX `SkincareLog_userId_fkey` ON `skincarelog`;

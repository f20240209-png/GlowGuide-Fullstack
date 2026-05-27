/*
  Warnings:

  - You are about to drop the column `ingredient_a` on the `ingredient_conflict` table. All the data in the column will be lost.
  - You are about to drop the column `ingredient_b` on the `ingredient_conflict` table. All the data in the column will be lost.
  - You are about to drop the column `severity_level` on the `ingredient_conflict` table. All the data in the column will be lost.
  - You are about to drop the column `warning_message` on the `ingredient_conflict` table. All the data in the column will be lost.
  - Added the required column `ingredientA` to the `Ingredient_Conflict` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ingredientB` to the `Ingredient_Conflict` table without a default value. This is not possible if the table is not empty.
  - Added the required column `severityLevel` to the `Ingredient_Conflict` table without a default value. This is not possible if the table is not empty.
  - Added the required column `warningMessage` to the `Ingredient_Conflict` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX `Ingredient_Conflict_ingredient_a_ingredient_b_key` ON `ingredient_conflict`;

-- AlterTable
ALTER TABLE `ingredient_conflict` DROP COLUMN `ingredient_a`,
    DROP COLUMN `ingredient_b`,
    DROP COLUMN `severity_level`,
    DROP COLUMN `warning_message`,
    ADD COLUMN `ingredientA` VARCHAR(191) NOT NULL,
    ADD COLUMN `ingredientB` VARCHAR(191) NOT NULL,
    ADD COLUMN `severityLevel` VARCHAR(191) NOT NULL,
    ADD COLUMN `warningMessage` TEXT NOT NULL;

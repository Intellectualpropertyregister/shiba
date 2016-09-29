class AddCostToLines < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute %Q{
      ALTER TABLE "#{Line.table_name}"
        DROP COLUMN IF EXISTS "daytime_safety_level",
        DROP COLUMN IF EXISTS "dark_safety_level",
        DROP COLUMN IF EXISTS "daytime_safety_level_norm",
        DROP COLUMN IF EXISTS "dark_safety_level_norm",
        ADD COLUMN "daytime_safety_level" int,
        ADD COLUMN "dark_safety_level" int,
        ADD COLUMN "daytime_cost" float,
        ADD COLUMN "dark_cost" float;

      UPDATE "#{Line.table_name}" SET
        "daytime_safety_level" = #{SafetyLevelConverter.unknown[:int]},
        "dark_safety_level" = #{SafetyLevelConverter.unknown[:int]},
        "daytime_cost" = #{SafetyLevelConverter.unknown[:cost]} * km,
        "dark_cost" = #{SafetyLevelConverter.unknown[:cost]} * km;
    }
  end

  def down
  end
end

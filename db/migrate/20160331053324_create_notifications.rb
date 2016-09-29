class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
        t.string :title
        t.string :error_msg
        t.json :error_code
        t.boolean :reviewed
        t.timestamps null: false
    end
  end
end

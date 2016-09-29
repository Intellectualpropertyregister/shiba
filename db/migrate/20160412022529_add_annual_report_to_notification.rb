class AddAnnualReportToNotification < ActiveRecord::Migration
  def change
      add_column :notifications, :annual_report, :boolean
  end
end

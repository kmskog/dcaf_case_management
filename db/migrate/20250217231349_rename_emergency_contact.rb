class RenameEmergencyContact < ActiveRecord::Migration[7.1]
  def change
    rename_column :patients, :emergency_conctact, :emergency_contact
  end
end

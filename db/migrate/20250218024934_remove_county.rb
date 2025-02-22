class RemoveCounty < ActiveRecord::Migration[7.1]
  def change
    remove_column :archived_patients, :county, :string
    remove_column :patients, :county, :string
  end
end

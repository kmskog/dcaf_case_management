class RenameLinesToCities < ActiveRecord::Migration[7.1]
  def change
    rename_table :lines, :cities
  end
end

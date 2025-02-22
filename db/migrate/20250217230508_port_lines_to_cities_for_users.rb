class PortLinesToCitiesForUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :city, foreign_key: true
    remove_column :users, :line
  end
end

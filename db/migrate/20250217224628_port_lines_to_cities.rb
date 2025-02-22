class PortLinesToCities < ActiveRecord::Migration[7.1]
  def change
    [:archived_patients, :call_list_entries, :events, :patients].each do |tbl|
      add_reference tbl, :city, foreign_key: true
      remove_reference tbl, :line
    end
  end
end



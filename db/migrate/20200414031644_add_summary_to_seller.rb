class AddSummaryToSeller < ActiveRecord::Migration[6.0]
  def change
    add_column :sellers, :summary, :text
  end
end

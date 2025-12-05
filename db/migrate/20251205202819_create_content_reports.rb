class CreateContentReports < ActiveRecord::Migration[8.0]
  def change
    create_table :content_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reportable, polymorphic: true, null: false
      t.text :reason, null: false
      t.string :report_type, null: false
      t.string :status, default: 'pending', null: false
      t.integer :reviewed_by
      t.datetime :reviewed_at
      t.text :resolution_notes

      t.timestamps
    end
    
    add_index :content_reports, :status
    add_index :content_reports, [:reportable_type, :reportable_id]
  end
end

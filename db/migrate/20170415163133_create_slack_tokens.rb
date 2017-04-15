class CreateSlackTokens < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :slack_access_token

    create_table :slack_tokens do |t|
      t.references :user, index: true, null: false
      t.string :token, null: false
      t.string :team_id, null: false
      t.string :team_name, null: false
      t.string :slack_user_id, null: false
      t.string :user_name, null: false
      t.timestamps null: false
    end

    add_index :slack_tokens, [:user_id, :team_id, :slack_user_id],
      unique: true
  end

  def down
    drop_table :slack_tokens

    add_column :users, :slack_access_token, :string
  end
end

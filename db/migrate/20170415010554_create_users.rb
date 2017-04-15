class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :user_name, null: false
      t.string :spotify_access_token
      t.string :spotify_refresh_token
      t.string :slack_access_token
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :user_name
  end
end

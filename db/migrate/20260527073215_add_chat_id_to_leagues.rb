class AddChatIdToLeagues < ActiveRecord::Migration[8.0]
  def change
    add_column :leagues, :chat_id, :string
  end
end

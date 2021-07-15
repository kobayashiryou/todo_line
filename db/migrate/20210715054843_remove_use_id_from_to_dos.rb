class RemoveUseIdFromToDos < ActiveRecord::Migration[6.1]
  def change
    remove_column :todos, :user_id, :string
  end
end

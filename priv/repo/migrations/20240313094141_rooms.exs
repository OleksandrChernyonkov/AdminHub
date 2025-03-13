defmodule MySuperApp.Repo.Migrations.Rooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :room_number, :integer, null: false
    end
  end
end

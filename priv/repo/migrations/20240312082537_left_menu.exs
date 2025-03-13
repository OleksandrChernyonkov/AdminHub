defmodule MySuperApp.Repo.Migrations.LeftMenu do
  use Ecto.Migration

  def change do
    create table(:left_menu) do
      add :title, :string, null: false
    end
  end
end

defmodule MySuperApp.Repo.Migrations.RightMenu do
  use Ecto.Migration

  def change do
    create table(:right_menu) do
      add :title, :string, null: false
    end
  end
end

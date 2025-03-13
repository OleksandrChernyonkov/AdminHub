defmodule MySuperApp.Repo.Migrations.Phones do
  use Ecto.Migration

  def change do
    create table(:phones) do
      add :phone_number, :string, null: false
    end
  end
end

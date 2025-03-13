defmodule MySuperApp.Repo.Migrations.CreateRows do
  use Ecto.Migration

  def change do
    create table(:rows) do
      add :eng_word, :string
      add :ukr_word, :string

      timestamps()
    end
  end
end

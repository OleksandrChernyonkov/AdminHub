defmodule MySuperApp.Repo.Migrations.Sites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :brand, :string
      add :status, :string, null: false, default: "ACTIVE"
      add :operator_id, references(:operators, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:sites, [:brand])
  end
end

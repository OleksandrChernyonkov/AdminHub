defmodule MySuperApp.Repo.Migrations.Roles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string
      add :operator_id, references(:operators, on_delete: :nilify_all)
      add :permission_id, references(:permissions, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])
  end
end

defmodule MySuperApp.Repo.Migrations.CreatePictures do
  use Ecto.Migration

  def change do
    create table(:pictures) do
      add :file_name, :string
      add :path, :string
      add :post_id, references(:posts)
      add :upload_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end

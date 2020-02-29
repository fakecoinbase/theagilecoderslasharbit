defmodule Arbit.Repo.Migrations.CreateCoindcx do
  use Ecto.Migration

  def change do
    create table(:coindcx) do
      add :coin,           :string
      add :quote_currency, :string
      add :price_inr,      :float
      add :price_usd,      :float
      add :price_btc,      :float
      add :volume,         :float

      timestamps()
    end

    create unique_index(:coindcx, [:coin, :quote_currency])
  end
end
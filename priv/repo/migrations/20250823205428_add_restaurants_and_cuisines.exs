defmodule Eatfair.Repo.Migrations.CreateAllEatfairTables do
  use Ecto.Migration

  def change do
    # 1. Modify the existing 'users' table
    # This migration adds the role, name, phone_number, and default_address fields.
    alter table(:users) do
      add :name, :string
      add :role, :string, default: "customer"
      add :phone_number, :string
      add :default_address, :string
    end

    # 2. Create the 'restaurants' table
    create table(:restaurants) do
      add :name, :string, null: false
      add :address, :string
      add :delivery_time, :integer
      add :min_order_value, :decimal
      add :is_open, :boolean, default: true
      add :rating, :decimal
      add :image_url, :string
      add :owner_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:restaurants, [:owner_id])

    # 3. Create the 'cuisines' table
    create table(:cuisines) do
      add :name, :string, null: false
      timestamps()
    end

    # 4. Create the 'restaurant_cuisines' join table for the many-to-many relationship
    create table(:restaurant_cuisines) do
      add :restaurant_id, references(:restaurants, on_delete: :delete_all), null: false
      add :cuisine_id, references(:cuisines, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:restaurant_cuisines, [:restaurant_id, :cuisine_id])

    # 5. Create the 'menus' table
    create table(:menus) do
      add :name, :string, null: false
      add :restaurant_id, references(:restaurants, on_delete: :delete_all), null: false
      timestamps()
    end

    # 6. Create the 'meals' table
    create table(:meals) do
      add :name, :string, null: false
      add :description, :string
      add :price, :decimal, null: false
      add :is_available, :boolean, default: true
      add :menu_id, references(:menus, on_delete: :delete_all), null: false
      timestamps()
    end

    # 7. Create the 'meal_customizations' table
    create table(:meal_customizations) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :meal_id, references(:meals, on_delete: :delete_all), null: false
      timestamps()
    end

    # 8. Create the 'customization_options' table
    create table(:customization_options) do
      add :name, :string, null: false
      add :price, :decimal, default: 0.0

      add :meal_customization_id, references(:meal_customizations, on_delete: :delete_all),
        null: false

      timestamps()
    end

    # 9. Create the 'orders' table
    create table(:orders) do
      add :status, :string, default: "pending"
      add :total_price, :decimal
      add :delivery_address, :string
      add :delivery_notes, :string
      add :customer_id, references(:users, on_delete: :nothing), null: false
      add :restaurant_id, references(:restaurants, on_delete: :nothing), null: false
      timestamps()
    end

    # 10. Create the 'order_items' table
    create table(:order_items) do
      add :quantity, :integer, null: false
      add :customization_options, :integer, array: true, default: []
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :meal_id, references(:meals, on_delete: :delete_all), null: false
      timestamps()
    end

    # 11. Create the 'payments' table
    create table(:payments) do
      add :amount, :decimal, null: false
      add :status, :string, default: "pending"
      add :provider_transaction_id, :string
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:payments, [:order_id])
  end
end

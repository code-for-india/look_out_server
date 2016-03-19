Sequel.migration do
  change do
    create_table(:users) do
      String :id, size: 32, primary_key: true, primary_key_constraint_name: :users_id_pk1
      Bignum :created_at
      Bignum :updated_at
    end
  end
end
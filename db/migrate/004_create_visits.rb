Sequel.migration do
  change do
    create_table(:visits) do
      primary_key :id, primary_key_constraint_name: :visits_id_pk1
      Integer :loo_id
      Bignum :created_at
      Bignum :updated_at
      foreign_key [:loo_id], :loos, name: :visits_lid_fk1, on_delete: :cascade, on_update: :cascade
    end
  end
end
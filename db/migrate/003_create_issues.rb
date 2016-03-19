Sequel.migration do
  change do
    create_table(:issues) do
      primary_key :id, primary_key_constraint_name: :reviews_id_pk1
      String :user_id, size: 32, null: false
      Integer :loo_id
      String :issue_type, size: 32
      String :comment, size: 256
      String :picture_url, size: 256
      String :state, size: 32
      String :source, size: 32
      String :gender, size: 32
      Bignum :resolved_at
      Bignum :created_at
      Bignum :updated_at
      foreign_key [:loo_id], :loos, name: :reviews_lid_fk1, on_delete: :cascade, on_update: :cascade
    end
  end
end
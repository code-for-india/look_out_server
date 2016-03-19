Sequel.migration do
  change do
    create_table(:loos) do
      primary_key :id, primary_key_constraint_name: :loos_id_pk1
      String :address, size: 256
      Float :latitude
      Float :longitude
      String :timing, size: 128
      String :type, size: 32
      Integer :urinal_count
      TrueClass :handicap_support
      TrueClass :paid
      Float :avg_rating
      String :picture_url

      Bignum :created_at
      Bignum :updated_at
    end
  end
end
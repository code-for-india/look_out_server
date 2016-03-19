class Visit < Sequel::Model
  unrestrict_primary_key

  def to_hash()
    {
        id: self.id,
        loo_id: self.loo_id,
        created_at: self.created_at,
        updated_at: self.updated_at
    }
  end
end
class Issue < Sequel::Model
  unrestrict_primary_key

  def to_hash()
    {
        id: self.id,
        user_id: self.user_id,
        loo_id: self.loo_id,
        issue_type: self.issue_type,
        comment: self.comment,
        picture_url: self.picture_url,
        state: self.state,
        source: self.source,
        gender: self.gender,
        resolved_at: self.resolved_at,
        created_at: self.created_at,
        updated_at: self.updated_at
    }
  end

end
class Course < Sequel::Model
  unrestrict_primary_key

  def to_hash()
    {
        id: self.id,
        teacher_id: self.teacher_id,
        name: self.name
    }
  end

end
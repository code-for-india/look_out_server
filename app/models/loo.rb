class Loo < Sequel::Model
  unrestrict_primary_key


  attr_accessor :no_soap_count
  attr_accessor :no_water_count
  attr_accessor :broken_count
  attr_accessor :dirty_count
  attr_accessor :other_count

  attr_accessor :no_soap_since
  attr_accessor :no_water_since
  attr_accessor :broken_since
  attr_accessor :dirty_since
  attr_accessor :other_issue_since


  def to_hash()
    {
        id: self.id,
        address: self.address,
        latitude: self.latitude,
        longitude: self.longitude,
        timing: self.timing,
        type: self.type,
        urinal_count: self.urinal_count,
        handicap_support: self.handicap_support,
        paid: self.paid,
        avg_rating: self.avg_rating,
        picture_url: self.picture_url,
        created_at: self.created_at,
        updated_at: self.updated_at,
        contact: ServerUtils.get_loo_contact(self.id)
    }
  end

  def to_hash_i()
    {
        id: self.id,
        no_soap_count: self.no_soap_count,
        no_water_count: self.no_water_count,
        broken_count: self.broken_count,
        dirty_count: self.dirty_count,
        other_count: self.other_count,

        no_soap_since: self.no_soap_since,
        no_water_since: self.no_water_since,
        broken_since: self.broken_since,
        dirty_since: self.dirty_since,
        other_issue_since: self.other_issue_since,
        contact: ServerUtils.get_loo_contact(self.id),
        created_at: self.created_at,
        updated_at: self.updated_at
    }
  end
end
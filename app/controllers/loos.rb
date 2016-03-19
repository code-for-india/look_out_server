
ApiServer::App.controllers :loos, provides: :json do

  module Constants
    LOO_CREATE_SCHEMA = {
        'type' => 'object', 'required' => true, 'additionalProperties' => true,
        'properties' => {
            'address' => { 'type' => 'string'},
            'latitude' => { 'type' => 'float'},
            'longitude' => { 'type' => 'float'},
            'timing' => { 'type' => 'string'},
            'type' => { 'type' => 'string'},
            'urinal_count' => { 'type' => 'integer'},
            'handicap_support' => { 'type' => 'boolean'},
            'paid' => { 'type' => 'boolean'},
            'avg_rating' => { 'type' => 'float'},
            'picture_url' => { 'type' => 'string'}
        }
    }

    LOO_QUERY_PARAMS = ['id', 'latitude', 'longitude', 'type', 'urinal_count', 'handicap_support', 'paid','avg_rating','rating_gte', 'rating_lte', 'created_before', 'created_after', 'updated_before', 'updated_after']
    LOO_FILTERS = ['rating_gte', 'rating_lte', 'created_before', 'created_after', 'updated_before', 'updated_after']
  end

  before :list do
    @args = {}
    @filters = {}
    unless params.nil?
      params.each do|key, val|
        raise InputValidationError unless Constants::LOO_QUERY_PARAMS.include?(key)
        @args[key.to_sym] = val unless Constants::LOO_FILTERS.include? key

        case key.to_sym
          when :rating_gte
            @filters[:rating_gte] = val
          when :rating_lte
            @filters[:rating_lte] = val
          when :created_before
            @filters[:created_before] = ServerValidators.validate_datetime key, val
          when :created_after
            @filters[:created_after] = ServerValidators.validate_datetime key, val
          when :updated_before
            @filters[:updated_before] = ServerValidators.validate_datetime key, val
          when :updated_after
            @filters[:updated_after] = ServerValidators.validate_datetime key, val
        end if val

      end

    end
  end

  get :list, map: '/v1/loos' do
    @loos = Loo.where
    @args.each do |key, val|
      @loos = @loos.where(key => val)
    end
    @filters.each do |key, val|
      case key
        when :rating_gte
          @loos = @loos.where('avg_rating >= ?', val)
        when :rating_lte
          @loos = @loos.where('avg_rating <= ?', val)
        when :created_before
          @loos = @loos.where('created_at <= ?', val)
        when :created_after
          @loos = @loos.where('created_at >= ?', val)
        when :updated_before
          @loos = @loos.where('updated_at <= ?', val)
        when :updated_after
          @loos = @loos.where('updated_at >= ?', val)
      end if val
    end

    @loos = @loos.all.map{ |rev|
      rev.to_hash
    }
    @view_obj = {
        timestamp: (Time.now.to_f * 1000).to_i,
        loos: @loos
    }
    # response.headers["Access-Control-Allow-Origin"] = "*"
    render 'shared/index'

  end

  before :list2 do
    @args = {}
    unless params.nil?
      params.each do|key, val|
        raise InputValidationError unless Constants::LOO_QUERY_PARAMS.include?(key)
        @args[key.to_sym] = val unless Constants::LOO_FILTERS.include? key
      end
    end
  end


  get :list2, map: '/v1/loo-issues' do
    @loos = Loo.where
    @args.each do |key, val|
      @loos = @loos.where(key => val)
    end
    @loos = @loos.all

    @loos.each do|loo|
      @open_issues = Issue.where(:loo_id => loo.id, :state => 'pending')

      @dirty_issues = @open_issues.where(:issue_type =>'dirty')
      loo.dirty_count = @dirty_issues.count
      if loo.dirty_count == 0
        loo.dirty_since = 0
      else
        loo.dirty_since = @dirty_issues.first().created_at
      end


      @no_water_issues = @open_issues.where(:issue_type =>'no water')
      loo.no_water_count = @no_water_issues.count
      if loo.no_water_count == 0
        loo.no_water_since = 0
      else
        loo.no_water_since = @no_water_issues.first().created_at
      end


      @no_soap_issues = @open_issues.where(:issue_type =>'no soap')
      loo.no_soap_count = @no_soap_issues.count
      if loo.no_soap_count == 0
        loo.no_soap_since = 0
      else
        loo.no_soap_since = @no_soap_issues.first().created_at
      end

      @broken_issues = @open_issues.where(:issue_type =>'broken')
      loo.broken_count = @broken_issues.count
      if loo.broken_count == 0
        loo.broken_since = 0
      else
        loo.broken_since = @broken_issues.first.created_at
      end

      @other_issues = @open_issues.where(:issue_type =>'other')
      loo.other_count = @other_issues.count
      if loo.other_count == 0
        loo.other_issue_since = 0
      else
        loo.other_issue_since = @other_issues.first().created_at
      end


    end

    @loos = @loos.map{ |rev|
      rev.to_hash_i
    }
    @view_obj = {
        timestamp: (Time.now.to_f * 1000).to_i,
        loos: @loos
    }
    render 'shared/index'

  end

  before :create do
    ServerValidators.validate_content_type request.content_type, ServerValidators::Constants::CONTENT_TYPE_JSON
    @payload = ServerValidators.validate_json_string :body, request.body.read
    ServerValidators.validate_json_schema :body, Constants::LOO_CREATE_SCHEMA, @payload
    @lat = @payload['latitude']
    @lng = @payload['longitude']
    @address = @payload['address']
    # @lat, @lng = ServerUtils.get_lat_lng(@address) if @lat.nil? or @lng.nil? and not @address.nil?
    # @address = ServerUtils.get_address(@lat, @lng) if @address.nil? and (not @lat.nil? and not @lng.nil?)
  end

  put :create, map: '/v1/loos' do
    DB.transaction(:rollback => :reraise) do
      @loo = Loo.create({
                            address: @address,
                            latitude: @lat,
                            longitude: @lng,
                            timing: @payload['timing'],
                            type: @payload['type'],
                            urinal_count: @payload['urinal_count'],
                            handicap_support: @payload['handicap_support'],
                            paid: @payload['paid'],
                            avg_rating: @payload['avg_rating'],
                            picture_url: @payload['picture_url']
                        })

      status 201
      @view_obj = @loo.to_hash;
      render 'shared/index'
    end
  end

end


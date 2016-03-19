
ApiServer::App.controllers :issues, provides: :json do

  module Constants
    ISSUE_CREATE_SCHEMA = {
        'type' => 'object', 'required' => true, 'additionalProperties' => true,
        'properties' => {
            'loo_id' => { 'type' => 'integer', 'required' => true },
            'user_id' => { 'type' => 'string'},
            'issue_type' => { 'type' => 'string', 'required' => false },
            'comment' => { 'type' => 'string', 'required' => false },
            'state' => { 'type' => 'string', 'required' => false },
            'source' => { 'type' => 'string', 'required' => false },
            'gender' => { 'type' => 'string', 'required' => false },
            'picture_url' => { 'type' => 'string', 'required' => false },
            'resolved_at' => { 'type' => 'string', 'required' => false }
        }
    }

    ISSUE_UPDATE_SCHEMA = {
        'type' => 'object', 'required' => true, 'additionalProperties' => true,
        'properties' => {
            'id' => { 'type' => 'integer', 'required' => true },
            'state' => { 'type' => 'string', 'required' => true },
            'resolved_at' => { 'type' => 'string', 'required' => false }
        }
    }



    ISSUE_QUERY_PARAMS = ['id', 'user_id', 'loo_id', 'issue_type', 'state', 'comment', 'picture_url', 'created_before', 'created_after', 'updated_before', 'updated_after']
    ISSUE_DATE_FILTERS = ['created_before', 'created_after', 'updated_before', 'updated_after']
  end


  before :list do
    @args = {}
    @filters = {}
    unless params.nil?
      params.each do|key, val|
        print Constants::ISSUE_QUERY_PARAMS
        raise InputValidationError unless Constants::ISSUE_QUERY_PARAMS.include?(key)
        @args[key.to_sym] = val unless Constants::ISSUE_DATE_FILTERS.include? key

        case key.to_sym
          when :created_before
            @filters[:created_before] = val
          when :created_after
            @filters[:created_after] = val
          when :updated_before
            @filters[:updated_before] = val
          when :updated_after
            @filters[:updated_after] =  val
        end if val

      end

    end
  end

  get :list, map: '/v1/issues' do
    @issues = Issue.where
    @args.each do |key, val|
      @issues = @issues.where( key => val)
    end
    @filters.each do |key, val|
      case key
        when :created_before
          @issues = @issues.where('created_at <= ?', val)
        when :created_after
          @issues = @issues.where('created_at >= ?', val)
        when :updated_before
          @issues = @issues.where('updated_at <= ?', val)
        when :updated_after
          @issues = @issues.where('updated_at >= ?', val)
      end if val
    end

    @issues = @issues.all.map{ |rev|
      rev.to_hash
    }
    @view_obj = {
        timestamp: (Time.now.to_f * 1000).to_i,
        issues: @issues
    }
    render 'shared/index'
  end

  before :create do
    ServerValidators.validate_content_type request.content_type, ServerValidators::Constants::CONTENT_TYPE_JSON
    @payload = ServerValidators.validate_json_string :body, request.body.read
    ServerValidators.validate_json_schema :body, Constants::ISSUE_CREATE_SCHEMA, @payload

    @user_id = @payload['user_id']
    @loo_id = @payload['loo_id']

    @loo = Loo.first(id: @loo_id)
    raise ResourceNotExistsError, {loo: 'does not exists'} if @loo.nil?

    @user = User.first(id: @user_id)
    @user = User.create(id: UUIDTools::UUID.random_create.hexdigest) if @user.nil?

    @issue_type = @payload['issue_type']
    @issue_type = "other" if @issue_type.nil?
  end

  put :create, map: '/v1/issues' do
    DB.transaction(:rollback => :reraise) do
      @issue = Issue.create({
                                user_id: @user.id,
                                loo_id: @loo.id,
                                issue_type: @issue_type,
                                comment: @payload['comment'],
                                state: 'pending',
                                source: 'app',
                                gender: @payload['gender'],
                                picture_url: @payload['picture_url'],
                                resolved_at: @payload['picture_url'],
                                created_at: (Time.now.to_f * 1000).to_i,
                                updated_at: (Time.now.to_f * 1000).to_i
                            })


      @loo_issues = Issue.where(loo_id: @loo.id);
      @open_issues = @loo_issues.where(:state => 'pending')
      open_issue_count = @open_issues.count

      visiter_count = Visit.where(loo_id: @loo.id).count
      visiter_count = 1 if (visiter_count == 0)
      onenormalizedrating = 1 - (open_issue_count.to_f / visiter_count)
      onenormalizedrating = 1 if (onenormalizedrating > 1)
      new_rating = onenormalizedrating * 5

      @loo.update({
                      avg_rating: new_rating,
                  })

      status 201

      phone = ServerConfig.worker_phone
      msg = "Task Assigned:" + " id:" +  @issue.id.to_s +  ", Loo:" + @loo.id.to_s + ", address: "+ @loo.address + ", Issue: " + @issue.issue_type
      ServerUtils.send_sms(phone, msg)
      @view_obj = @issue.to_hash;
      render 'shared/index'
    end
  end

  before :update do
    ServerValidators.validate_content_type request.content_type, ServerValidators::Constants::CONTENT_TYPE_JSON
    @payload = ServerValidators.validate_json_string :body, request.body.read
    ServerValidators.validate_json_schema :body, Constants::ISSUE_UPDATE_SCHEMA, @payload
    @issue_id = @payload['id']
    @issue = Issue.first(id: @issue_id)
    raise ResourceNotExistsError, {issue: 'does not exists'} if @issue.nil?
  end

  post :update, map: '/v1/issues' do
    DB.transaction(:rollback => :reraise) do
      @issue.update({
                        state: @payload['state'],
                        resolved_at: @payload['resolved_at'],
                        updated_at: (Time.now.to_f * 1000).to_i
                    })

      status 200
      @view_obj = @issue.to_hash;
      render 'shared/index'
    end
  end


  before :resolve do
    raise InputValidationError if params.nil?
    raise InputValidationError if (params.length == 0)
    @loo_id = params['loo_id']
    @issue_type = params['issue_type']
    @gender = params['gender']
    @loo = Loo.first(id: @loo_id)
    raise InputValidationError if @loo.nil?
    raise InputValidationError if @issue_type.nil?
  end


  get :resolve, map: '/v1/issues/resolve' do
    DB.transaction(:rollback => :reraise) do
      @issues = Issue.where({
                                :loo_id => @loo_id,
                                :issue_type => @issue_type
                            })

      time_now= (Time.now.to_f * 1000).to_i
      @issues.update({
                         :state => "resolved",
                         updated_at: time_now,
                         resolved_at: time_now
                     }) unless (@issues.count == 0)
      status 200
      @issues = @issues.all.map{ |rev|
        rev.to_hash
      }
      phone = ServerConfig.user_phone
      msg = "Issue reported by you for loo at- "+ @loo.address + " has been resolved. Thanks for your participation."
      ServerUtils.send_sms(phone, msg)

      @view_obj = {
          timestamp: (Time.now.to_f * 1000).to_i,
          issues: @issues
      }
      render 'shared/index'
    end
  end

  before :remind do
    raise InputValidationError if params.nil?
    raise InputValidationError if (params.length == 0)
    @loo_id = params['loo_id']
    @issue_type = params['issue_type']
    @loo = Loo.first(id: @loo_id)
    raise InputValidationError if @loo.nil?
    raise InputValidationError if @issue_type.nil?
  end

  get :remind, map: '/v1/issues/remind' do
    phone = ServerConfig.worker_phone
    msg = "Task Assigned:" +  ", Loo:" + @loo.id.to_s + ", address: "+ @loo.address + ", Issue: " + @issue_type
    ServerUtils.send_sms(phone, msg)
    @view_obj = {};
    status 200
    render 'shared/index'
  end

  before :notify do
    raise InputValidationError if params.nil?
    raise InputValidationError if (params.length == 0)
    @loo_id = params['loo_id']
    @loo = Loo.first(id: @loo_id)
    raise InputValidationError if @loo.nil?
  end

  get :notify, map: '/v1/issues/notify' do
    phone = ServerConfig.user_phone
    msg = "Issue reported by you for loo at- "+ @loo.address + " has been resolved. Thanks for your participation."
    ServerUtils.send_sms(phone, msg)
    @view_obj = {};
    status 200
    render 'shared/index'
  end

end


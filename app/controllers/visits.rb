
ApiServer::App.controllers :visits, provides: :json do

  module Constants
    VISIT_QUERY_PARAMS = ['loo_id', 'created_before', 'created_after', 'updated_before', 'updated_after']
    VISIT_FILTERS = ['created_before', 'created_after', 'updated_before', 'updated_after']
  end

  before :list do
    @args = {}
    @filters = {}
    unless params.nil?
      params.each do|key, val|
        raise InputValidationError unless Constants::VISIT_QUERY_PARAMS.include?(key)
        @args[key.to_sym] = val unless Constants::VISIT_FILTERS.include? key

        case key.to_sym
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

  get :list, map: '/v1/visits' do
    @visits = Visit.where
    @args.each do |key, val|
      @visits = @visits.where(key => val)
    end
    @filters.each do |key, val|
      case key
        when :created_before
          @visits = @visits.where('created_at <= ?', val)
        when :created_after
          @visits = @visits.where('created_at >= ?', val)
        when :updated_before
          @visits = @visits.where('updated_at <= ?', val)
        when :updated_after
          @visits = @visits.where('updated_at >= ?', val)
      end if val
    end
    @count = @visits.count
    @view_obj = {visits: @count}
    render 'shared/index'

end
  before :create do
    @loo_id= params[:loo_id]
    @loo = Loo.first(id: @loo_id)
    raise ResourceNotExistsError, {loo: 'does not exists'} if @loo.nil?
  end

  put :create, map: '/v1/visits/:loo_id' do
    DB.transaction(:rollback => :reraise) do
      @visit = Visit.create({
                            loo_id: @loo.id
                        })

      status 201
      @view_obj = @visit.to_hash;
      render 'shared/index'
    end
  end
end



ApiServer::App.controllers :courses, provides: :json do

  module Constants
    COURSES_QUERY_PARAMS = ['teacher_id']
  end

  before :list do
    @args = {}
    unless params.nil?
      params.each do|key, val|
        raise InputValidationError unless Constants::COURSES_QUERY_PARAMS.include?(key)
        @args[key.to_sym] = val
      end

    end
  end

  get :list, map: '/v1/courses' do
    @courses = Course.where
    @args.each do |key, val|
      @courses = @courses.where(key => val)
    end
    @courses = @courses.all.map{ |rev|
      rev.to_hash
    }
    @view_obj = {
        timestamp: (Time.now.to_f * 1000).to_i,
        courses: @courses
    }
    render 'shared/index'

  end
end


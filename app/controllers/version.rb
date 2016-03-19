require 'json'

ApiServer::App.controllers :version, provides: :json do
	get :show, map: '/v1/version' do
		@view_obj = {
			'version' => '1.0.0',
			'branch' => 'development'
		}
		render 'shared/index'
	end
end

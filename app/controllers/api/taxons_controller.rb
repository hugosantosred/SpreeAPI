class Api::TaxonsController < Api::BaseController
  resource_controller_for_api
  actions :index, :show, :create, :update
  

  private   
    def object_serialization_options
      
    end
end

class Api::BaseController < Spree::BaseController

  def self.resource_controller_for_api
    resource_controller
    before_filter :check_http_authorization
    skip_before_filter :verify_authenticity_token, :if => lambda { admin_token_passed_in_headers }

    index do
      wants.json { render :json => collection.to_json(collection_serialization_options) }
    end

    show do
      wants.json { render :json => object.to_json(object_serialization_options) }
      failure.wants.json { render :text => "Failure\n", :status => 500 }
    end

    create do
      wants.json { render :text => "Resource created\n", :status => 201, :location => object_url }
      failure.wants.json { render :text => "Failure\n", :status => 500 }
    end

    update do
      wants.json { render :nothing => true }
      failure.wants.json { render :text => "Failure\n", :status => 500 }
    end

    define_method :admin_token_passed_in_headers do
      request.headers['HTTP_AUTHORIZATION'].present?
    end

    define_method :end_of_association_chain do
      parent? ? parent_association.scoped : model.scoped(:include  => eager_load_associations)
    end

    define_method :collection do
      @collection ||= search.relation.limit(100)
    end
  end

  def access_denied
    render :text => 'access_denied', :status => 401
  end

  # Generic action to handle firing of state events on an object
  def event
    valid_events = model.state_machine.events.map(&:name)
    valid_events_for_object = object.state_transitions.map(&:event)

    if params[:e].blank?
      errors = t('api.errors.missing_event')
    elsif valid_events_for_object.include?(params[:e].to_sym)
      object.send("#{params[:e]}!")
      errors = nil
    elsif valid_events.include?(params[:e].to_sym)
      errors = t('api.errors.invalid_event_for_object', :events => valid_events_for_object.join(','))
    else
      errors = t('api.errors.invalid_event', :events => valid_events.join(','))
    end

    respond_to do |wants|
      wants.json do
        if errors.blank?
          render :nothing => true
        else
          render :json => errors.to_json, :status => 422
        end
      end
    end
  end

  protected

    def search
      return @search unless @search.nil?
      params[:search] = {} if params[:search].blank?
      params[:search][:meta_sort] = 'created_at.desc' if params[:search][:meta_sort].blank?
      @search = end_of_association_chain.metasearch(params[:search])
      @search
    end

    def collection_serialization_options
      {}
    end

    def object_serialization_options
      {}
    end

    def eager_load_associations
      nil
    end

    def object_errors
      {:errors => object.errors.full_messages}
    end

  private
  def check_http_authorization
    render :text => "Access Denied\n", :status => 401 unless request.headers['HTTP_AUTHORIZATION'].present?
  end

end

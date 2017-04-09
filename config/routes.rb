Rails.application.routes.draw do

  root 'dates#index' # this is the entry point for the UI
  #get '/date/:date', to: 'dates#show'
  get "date/(:date)" => "dates#show_date_events", 
    :constraints => { :date => /\d{4}-\d{2}-\d{2}/ },
    :as => "show_date_events"
  #resources :event_data
  namespace :api do
    # API controller goes here
  end
end

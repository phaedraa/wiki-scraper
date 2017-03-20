Rails.application.routes.draw do

  root 'dates#index' # this is the entry point for the UI
  #get '/date/:date', to: 'dates#show'
  #resources :event_data
  namespace :api do
    # API controller goes here
  end
end

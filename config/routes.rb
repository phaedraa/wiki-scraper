Rails.application.routes.draw do

  root 'events#index' # this is the entry point for the UI

  namespace :api do
    # API controller goes here
  end
end

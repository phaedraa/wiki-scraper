Rails.application.routes.draw do

  root 'application#scrape_wikipedia' # this is the entry point for the UI
  #get '/date/:date', to: 'dates#show'

  namespace :api do
    # API controller goes here
  end
end

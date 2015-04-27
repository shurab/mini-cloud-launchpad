Rails.application.routes.draw do

  get    'launchpad/new'  => "launchpad#new"   #, as: :launch
  get    'launchpad/show' => 'launchpad#show'  #, as: :status
  post   'launchpad'      => 'launchpad#create'
  delete 'launchpad'      => 'launchpad#destroy'

  root 'launchpad#new'
end

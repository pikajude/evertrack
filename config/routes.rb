Evertrack::Application.routes.draw do
  get "sprints/current"
  get "sprints/view/:guid",    to: "sprints#view"
  post "sprints/update/:guid", to: "sprints#update"

  root 'home#current'

  devise_for :users
end

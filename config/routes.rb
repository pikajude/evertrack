Evertrack::Application.routes.draw do
  get "sprints/current"
  get "sprints/view/:guid", to: "sprints#view"

  root 'home#current'

  devise_for :users
end

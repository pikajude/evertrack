Evertrack::Application.routes.draw do
  get "notes/view/:guid", to: "notes#view"
  post "notes/update/:guid", to: "notes#update"
  post "notes/assign/:guid", to: "notes#assign"

  get "sprints/current"

  root 'home#current'

  devise_for :users
end

require "sinatra"
require "sinatra/reloader"
require 'sinatra/content_for'
require "tilt/erubis"

configure do
  enable :sessions, :method_override
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def complete?(list)
    !list[:todos].empty? && list[:todos].all? { |todo| todo[:completed] }
  end

  def stats(list)
    total = list[:todos].size
    num_left = list[:todos].count { |todo| !todo[:completed] }
    "#{num_left} / #{total}"
  end

  def sort_by_with_index(collection, &block)
    with_idx(collection)
      .sort_by(&block)
  end
end

def with_idx(collection)
  collection.map.with_index { |item, idx| [item, idx] }
end

def validate(name, list)
  if !valid_length?(name)
    "Name must be between 1 and 50 characters"
  elsif !unique?(name, list)
    "Name must be unique"
  end
end

def valid_length?(name)
  name&.size&.between?(1, 50)
end

def unique?(name, collection)
  collection.none? { |item| item[:name] == name }
end

def list_at(index)
  session[:lists].at(index.to_i)
end

get "/" do
  redirect "/lists"
end

# show all list
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# show new list form
get '/lists/new' do
  erb :new_list
end

# show a list
get "/lists/:id" do
  list = list_at(params[:id])
  halt(404) unless list
  erb :list, locals: { list: }
end

# show edit list form
get '/lists/:id/edit' do
  erb :edit_list, locals: { list: list_at(params[:id]) }
end

# add a list
post '/lists' do
  list_name = params[:list_name].strip
  error_message = validate(list_name, session[:lists])
  if error_message
    session[:error] = error_message
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# update list name
put "/lists/:id" do
  id = params[:id].to_i
  list_name = params[:list_name].strip
  list = list_at(id)
  error_message = validate(list_name, list)
  if error_message
    session[:error] = error_message
    erb :new_list, layout: :layout
  else
    list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

# delete list
delete "/lists/:id" do
  list = session[:lists].delete_at(params[:id].to_i)
  session[:success] = 'List deleted' if list
  redirect "/lists"
end

# add todo to list
post "/lists/:id/todos" do
  list = list_at(params[:id])
  todo = params[:todo]
  error_message = validate(todo, list[:todos])
  if error_message
    session[:error] = error_message
    erb :list, locals: { id: params[:id], list: }
  else
    list[:todos] << { name: todo, completed: false }
    session[:success] = 'Todo added'
    redirect "/lists/#{params[:id]}"
  end
end

post "/lists/:id/complete" do
  list_at(params[:id])[:todos].each { |todo| todo[:completed] = true }
  redirect "/lists/#{params[:id]}"
end

put "/lists/:id/todos/:todo_id" do
  list = list_at(params[:id])
  list[:todos][params[:todo_id].to_i][:completed] = params[:completed] == "true"
  redirect "/lists/#{params[:id]}"
end

delete "/lists/:id/todos/:todo_id" do
  list = list_at(params[:id])
  todo = list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = 'Todo deleted' if todo
  redirect "/lists/#{params[:id]}"
end

not_found do
  "Nothing to See Here"
end

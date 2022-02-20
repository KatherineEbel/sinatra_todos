require "sinatra"
require 'sinatra/content_for'
require "tilt/erubis"

require_relative 'database_persistence'

configure do
  enable :sessions, :method_override
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload 'database_persistence.rb'
  also_reload 'model.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end

helpers do
  def list_class(list)
    'complete' if list.complete?
  end

  def todo_class(todo)
    'complete' if todo.completed
  end

  def stats(list)
    total    = list.todos.size
    num_left = list.todos.count { |todo| !todo[:completed] }
    "#{num_left} / #{total}"
  end
end

get "/" do
  redirect "/lists"
end

# show all list
get "/lists" do
  @lists = @storage.lists
  erb :lists, layout: :layout
end

# show new list form
get '/lists/new' do
  erb :new_list
end

# show a list
get "/lists/:id" do
  list = @storage.find_list(params[:id])
  session[:error] = @storage.error
  redirect '/lists' if list.nil?
  erb :list, locals: { list: }
end

# show edit list form
get '/lists/:id/edit' do
  list = @storage.find_list(params[:id])
  session[:error] = @storage.error
  erb :edit_list, locals: { list: }
end

# add a list
post '/lists' do
  @storage.add_list(params[:list_name].strip)
  if @storage.error?
    session[:error] = @storage.error
    erb :new_list, layout: :layout
  else
    session[:success] = 'List Added'
    redirect '/lists'
  end
end

# update list name
put "/lists/:id" do
  id        = params[:id]
  list      = @storage.update_list(id, params[:list_name].strip)
  if @storage.error?
    session[:error] = @storage.error
    erb :edit_list, layout: :layout, locals: { list: }
  else
    session[:success] = 'List updated'
    redirect "/lists/#{id}"
  end
end

# delete list
delete "/lists/:id" do
  list = @storage.delete_list(params[:id])
  session[:error] = @storage.error
  redirect '/lists' if list.nil?
  if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    "/lists"
  else
    session[:success] = 'List deleted'
    redirect "/lists"
  end
end

# add todo to list
post "/lists/:id/todos" do
  @storage.add_todo(params[:todo], params[:id])
  if @storage.error?
    session[:error] = @storage.error
    erb :list,
        locals: { id: params[:id], list: @storage.find_list(params[:id]) }
  else
    session[:success] = 'Todo Added'
    redirect "/lists/#{params[:id]}"
  end
end

# complete list
post "/lists/:id/complete" do
  @storage.complete_list(params[:id].to_i)
  session[:error] = @storage.error
  redirect "/lists/#{params[:id]}"
end

# toggle complete
put "/lists/:id/todos/:todo_id" do
  todo_id = params[:todo_id]
  @storage.toggle_complete(todo_id, params[:completed])
  session[:error] = @storage.error
  redirect "/lists/#{params[:id]}"
end

# delete a todo
delete "/lists/:id/todos/:todo_id" do
  todo = @storage.delete_todo(params[:todo_id])
  if todo.nil?
    halt not_found
  end
  if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = 'Todo deleted'
    redirect "/lists/#{params[:id]}"
  end
end

not_found do
  "Nothing to See Here"
end

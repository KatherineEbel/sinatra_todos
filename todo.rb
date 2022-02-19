require "sinatra"
require "sinatra/reloader" if development?
require 'sinatra/content_for'
require "tilt/erubis"

require_relative 'session_persistence'

configure do
  enable :sessions, :method_override
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

before do
  @storage = SessionPersistence.new(session)
end

helpers do
  def list_class(list)
    'complete' if complete?(list)
  end

  def todo_class(todo)
    'complete' if todo[:completed]
  end

  def complete?(list)
    !list[:todos].empty? && list[:todos].all? { |todo| todo[:completed] }
  end

  def stats(list)
    total    = list[:todos].size
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

def list_at(index)
  list = @storage.find_list(index)
  return list if list

  redirect '/lists'
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
  list = @storage.find_list(params[:id].to_i)
  redirect '/lists' if list.nil?
  erb :list, locals: { list: }
end

# show edit list form
get '/lists/:id/edit' do
  list = @storage.find_list(params[:id].to_i)
  erb :edit_list, locals: { list: }
end

# add a list
post '/lists' do
  @storage.add_list(params[:list_name].strip)
  if @storage.error?
    erb :new_list, layout: :layout
  else
    redirect '/lists'
  end
end

# update list name
put "/lists/:id" do
  id        = params[:id].to_i
  list      = @storage.update_list(id, params[:list_name].strip)
  if @storage.error?
    erb :edit_list, layout: :layout, locals: { list: }
  else
    redirect "/lists/#{id}"
  end
end

# delete list
delete "/lists/:id" do
  list = @storage.delete_list(params[:id].to_i)
  redirect '/lists' if list.nil?
  if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    "/lists"
  else
    redirect "/lists"
  end
end

# add todo to list
post "/lists/:id/todos" do
  list = @storage.add_todo(params[:id].to_i, params[:todo])
  if @storage.error?
    erb :list,
        locals: { id: params[:id], list: }
  else
    redirect "/lists/#{params[:id]}"
  end
end

# complete list
post "/lists/:id/complete" do
  @storage.complete_list(params[:id].to_i)
  redirect "/lists/#{params[:id]}"
end

# toggle complete
put "/lists/:id/todos/:todo_id" do
  list_id, todo_id = [params[:id], params[:todo_id]].map(&:to_i)
  @storage.toggle_complete(list_id, todo_id)
  redirect "/lists/#{params[:id]}"
end

# delete a todo
delete "/lists/:id/todos/:todo_id" do
  todo = @storage.delete_todo(params[:id].to_i, params[:todo_id].to_i)
  if todo.nil?
    halt not_found
  end
  if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    status 204
  else
    redirect "/lists/#{params[:id]}"
  end
end

not_found do
  "Nothing to See Here"
end

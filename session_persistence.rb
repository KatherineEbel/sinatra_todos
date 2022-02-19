class SessionPersistence
  attr_reader :session, :lists

  def initialize(session)
    @session   = session
    @lists     = session[:lists] ||= []
  end

  def error?
    !session[:error].nil?
  end

  def find_list(id)
    list = lists.at(id)
    return list if list
    self.error = 'List not found'
  end

  def update_list(id, name)
    list = find_list(id)
    if list.nil?
      self.error = 'List not found'
    else
      list[:name] = name
      session[:success] = 'The list has been updated.'
    end
    list
  end

  def error=(error)
    session[:error] = error
  end

  def add_list(name)
    lists << { name:, todos: [] }
    session[:success] = 'The list has been created'
  end

  def delete_list(id)
    list = lists.delete_at(id)
    session[:success] = 'List deleted' if list
    list
  end

  def add_todo(list_id, todo)
    list = find_list(list_id)
    return if list.nil?

    validate(todo, list[:todos])
    return if error?
    session[:success] = 'Todo added'
    list[:todos] << { name: todo, completed: false }
  end

  def complete_list(id)
    list = find_list(id)
    return if list.nil?
    list[:todos]&.each { |todo| todo[:completed] = true }
  end

  def toggle_complete(list_id, todo_id)
    list = find_list(list_id)
    return if list.nil?
    complete = list[:todos][todo_id][:completed]
    list[:todos][todo_id][:completed] = !complete
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    return if list.nil?
    todo = list[:todos]&.delete_at(todo_id)
    session[:success] = 'Todo deleted' if todo
    todo
  end

  def exists?(list_name)
    lists.any? { |l| l[:name] = list_name }
  end

  def validate(name, collection)
    message = if !valid_length?(name)
                "Name must be between 1 and 50 characters"
              elsif !unique?(name, collection)
                "Name must be unique"
              end

    self.error = message
  end

  def valid_length?(name)
    name&.size&.between?(1, 50)
  end

  def unique?(name, collection)
    collection.none? { |item| item[:name] == name }
  end

  private :session
end

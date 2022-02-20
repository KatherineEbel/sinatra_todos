require 'pg'
require_relative 'model'

class DatabasePersistence
  attr_reader :logger, :db, :error

  def initialize(logger)
    @db     = PG.connect(dbname: 'todos')
    @logger = logger
  end

  def clear_error
    self.error = nil
  end

  def error=(error)
    logger.error(error)
    @error = error
  end

  def merge_rows(rows)
    rows.each_with_index.each_with_object([]) do |(r, i), result|
      if i.zero?
        result.concat(r.shift(2), r)
      else
        result.concat(r.drop(2))
      end
    end
  end

  def lists
    result = query(List.sql_all)
    result.values.group_by(&:first)
          .each_value.map do |v|
      List.from_array((v.size > 1 ? merge_rows(v) : v.first))
    end
  end

  def error?
    !@error.nil?
  end

  def find_list(id)
    result = query(List.sql_find, id)
    if result.ntuples.zero?
      self.error = 'List not found'
      return
    end
    result.values.group_by(&:first)
          .each_value.map do |v|
      List.from_array((v.size > 1 ? merge_rows(v) : v.first))
    end.first
  end

  def update_list(id, name)
    begin
      query(List.sql_update, name, id)
    rescue StandardError => e
      self.error = e
    end
    find_list(id)
  end

  def add_list(name)
    query(List.sql_new, name)
  rescue StandardError => e
    self.error = e
  end

  def delete_list(id)
    query(List.sql_delete, id)
  rescue StandardError => e
    self.error = e
  end

  def add_todo(todo, list_id)
    query(Todo.sql_add, todo, list_id)
  rescue StandardError => e
    self.error = e
  end

  def complete_list(id)
    result = query(Todo.sql_ids, id)
    ids    = result.each_row.flat_map(&:itself)
    query(Todo.sql_complete_all(ids.size), *ids)
  rescue StandardError => e
    self.error = e
  end

  def toggle_complete(todo_id, completed)
    query(Todo.sql_toggle_complete, completed, todo_id)
  rescue StandardError => e
    self.error = e
  end

  def delete_todo(id)
    query(Todo.sql_delete, id)
  rescue StandardError => e
    self.error = e
  end

  private :logger, :db, :error=

  def query(statement, *params)
    logger.info "#{statement}: #{params}"
    db.exec_params(statement, params)
  end
end

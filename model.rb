List = Struct.new(:id, :name, :todos, keyword_init: true) do
  def size
    todos.size
  end

  def empty?
    size.zero?
  end

  def complete?
    !empty? && todos.all?(&:completed)
  end

  def stats
    num_left = todos.count { |todo| !todo.completed }
    "#{num_left} / #{size}"
  end

  def self.from_array(rows)
    id, name = rows.shift(2)
    todos    = rows.compact.each_slice(4).map { |t| Todo.from_array(t) }
    List.new(id:, name:, todos:)
  end

  def self.sql_all
    <<~SQL
      SELECT lists.*, todos.*
      FROM lists
               LEFT JOIN todos ON lists.id = todos.list_id
      GROUP BY lists.id, todos.id
      ORDER BY (
          SELECT coalesce(every(completed), false)
          FROM todos
          WHERE list_id = lists.id
      ),
      (SELECT count(*)
      FROM todos
      WHERE list_id = lists.id) DESC;
    SQL
  end

  def self.sql_find
    <<~SQL
      SELECT lists.*, todos.*
      FROM lists
      LEFT JOIN todos ON todos.list_id = lists.id
      WHERE lists.id = $1
    SQL
  end

  def self.sql_update
    'UPDATE lists SET name = $1 WHERE id = $2'
  end

  def self.sql_new
    <<~SQL
      INSERT INTO lists (name)
      VALUES ($1)
    SQL
  end

  def self.sql_delete
    'DELETE FROM lists WHERE id = $1'
  end
end

Todo = Struct.new(:id, :name, :completed, :list_id, keyword_init: true) do
  def self.from_array(tuple)
    id, name, completed, list_id = tuple
    Todo.new(id: id.to_i, name:, completed: completed == "t",
             list_id: list_id.to_i)
  end

  def self.sql_add
    <<~SQL
      INSERT INTO todos (name, list_id)
      VALUES ($1, $2)
    SQL
  end

  def self.sql_toggle_complete
    'UPDATE todos SET completed = $1 WHERE id = $2'
  end

  def self.sql_delete
    'DELETE FROM todos WHERE id = $1'
  end

  def self.sql_complete_all(count)
    params = 1.upto(count).map { |n| "$#{n}" }.join(', ')
    "UPDATE todos SET completed = true WHERE id IN (#{params})"
  end

  def self.sql_ids
    'SELECT id FROM todos WHERE list_id = $1'
  end
end

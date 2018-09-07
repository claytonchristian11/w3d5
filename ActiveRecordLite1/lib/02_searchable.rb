require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable

  def where(params)
    vals = params.values
    where_line = params.keys.join(" = ? AND ").to_s + " = ?"
    # debugger
    new_ob = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
      SQL
      # debugger
      new_obs = new_ob.map {|ob| self.new(ob)}
    # self.new(new_ob)
  end
end

class SQLObject
  extend Searchable

end

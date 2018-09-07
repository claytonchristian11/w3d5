require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns unless @columns.nil?
    # table = self.table_name
    connections = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL

    @columns = connections[0].map {|con| con.to_sym}
  end

  def self.finalize!

    self.columns.each do |col|

      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end

    end
    @attributes

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    name = self.name
    name = name[0].downcase + name[1..-1] + 's'
  end

  def self.all
    # debugger
    columns = self.columns.map {|col| col.to_s}
    connections = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      SQL

    connections = self.parse_all(connections)
  end

  def self.parse_all(results)
    objects = []
    # debugger
    results.each do |result|
      objects << self.new(result)
    end
    objects
  end

  def self.find(id)
    connections = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    SQL
    return nil if connections.empty?
    # debugger
    self.new(connections[0])
  end

  def initialize(params = {})

    params.each do |k,v|
      col_name = k.to_s
      if !(self.class.columns.include?(k)) && !(self.class.columns.include?(k.to_sym))
        raise Exception.new("unknown attribute '#{col_name}'")
      end

      self.send("#{col_name}=", v)
    end
  end

  def attributes
    @attributes ||= Hash.new

    @attributes
  end

  def attribute_values
    arr = []
    self.class.columns.each do |col|
      arr << self.send("#{col}")
    end
    arr
  end

  def insert
    attr_values = self.attribute_values
    col_names = self.class.columns.join(", ").to_s
    question_marks = (["?"] * attribute_values.length).join(", ").to_s
    # debugger
    DBConnection.execute(<<-SQL, *self.attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    attr_values = (self.attribute_values + [self.id])
    set_line = self.class.columns.join(" = ?, ").to_s
    set_line += " = ?"


    # debugger
    DBConnection.execute(<<-SQL, *attr_values)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = ?
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end

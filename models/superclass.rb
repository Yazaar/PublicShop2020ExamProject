class Superclass
    
    # Public: Saves a database to the @db variable
    #
    # db - open SQLite3 database object
    #
    # Examples
    #  Superclass.load(SQLite3::Database.new('database.db'))
    #  # => nil
    #
    # Returns nil
    def self.load(db, tablename)
        @db = db
        @tablename = tablename
        return nil
    end
    
    # Parsing the "where" Hash variable
    #
    # type - String with the value AND or OR (first layer = AND, second layer = OR, third layer = AND ... ... Should always be AND on first call and recursive calling will swap between then)
    #
    # Examples
    #  product::Product.build_where_component("AND", ["column1", ["colum2", "column2"], "column3"])
    #  # => "column1=? AND (column2=? OR column2=?) AND column2=?"
    #
    # Returns String on success and nil or missing keys on error
    def self.build_where_component(type, where)
        if where.class == String
            return "#{where}=?"
        end
        if where.class != Array
            return ''
        end
        where_statement = ''
        where.each do |component|
            if component.class == Array
                if type == 'AND'
                    if where_statement == ''
                        where_statement += "(#{self.build_where_component('OR', component)})"
                    else
                        where_statement += ' AND (' + self.build_where_component('OR', component) + ')'
                    end
                else
                    if where_statement == ''
                        where_statement += "(#{self.build_where_component('AND', component)})"
                    else
                        where_statement += ' OR (' + self.build_where_component('AND', component) + ')'
                    end
                end
            elsif component.class == String
                if where_statement == ''
                    where_statement += "#{component}=?"
                else
                    where_statement += " #{type} #{component}=?"
                end
            elsif component.class == Hash
                operator = '='
                column = '?'
                columnValue = '?'
                if component[:operator].class == String
                    operator = component[:operator]
                end
                if component[:column].class == String
                    column = component[:column]
                end
                if component[:columnValue].class == String
                    columnValue = component[:columnValue]
                end
                if component[:columnValue].class == Hash
                    if component[:columnValue][:method].downcase == 'inline execute' && component[:columnValue][:request].class == Hash
                        columnValue = "(#{self.get_sql(component[:columnValue][:request])})"
                    end
                end
                if where_statement == ''
                    where_statement += "#{column} #{operator} #{columnValue}"
                else
                    where_statement += " #{type} #{column} #{operator} #{columnValue}"
                end
            end
        end
        return where_statement
    end

    # Parsing the "where" Hash variable
    #
    # type - String with the value AND or OR (first layer = AND, second layer = OR, third layer = AND ... ... Should always be AND on first call and recursive calling will swap between then)
    #
    # Examples
    #  class_instance1.build_where_component("AND", ["column1", ["colum2", "column2"], "column3"])
    #  # => "column1=? AND (column2=? OR column2=?) AND column2=?"
    #
    # Returns String on success and nil or missing keys on error
    def build_where_component(type, where)
        if where.class == String
            return "#{where}=?"
        end
        if where.class != Array
            return ''
        end
        where_statement = ''
        where.each do |component|
            if component.class == Array
                if type == 'AND'
                    if where_statement == ''
                        where_statement += "(#{self.build_where_component('OR', component)})"
                    else
                        where_statement += ' AND (' + self.build_where_component('OR', component) + ')'
                    end
                else
                    if where_statement == ''
                        where_statement += "(#{self.build_where_component('AND', component)})"
                    else
                        where_statement += ' OR (' + self.build_where_component('AND', component) + ')'
                    end
                end
            elsif component.class == String
                if where_statement == ''
                    where_statement += "#{component}=?"
                else
                    where_statement += " #{type} #{component}=?"
                end
            elsif component.class == Hash
                operator = '='
                column = '?'
                columnValue = '?'
                if component[:operator].class == String
                    operator = component[:operator]
                end
                if component[:column].class == String
                    column = component[:column]
                end
                if component[:columnValue].class == String
                    columnValue = component[:columnValue]
                end
                if component[:columnValue].class == Hash
                    if component[:columnValue][:method].downcase == 'inline execute' && component[:columnValue][:request].class == Hash
                        columnValue = "(#{self.get_sql(component[:columnValue][:request])})"
                    end
                end
                if where_statement == ''
                    where_statement += "#{column} #{operator} #{columnValue}"
                else
                    where_statement += " #{type} #{column} #{operator} #{columnValue}"
                end
            end
        end
        return where_statement
    end

    # Public: Checks the operation Hash value and forwards over the data to correct method
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user::User.get_sql({operation: "DELETE", where: "id"})
    #  # => "DELETE FROM users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def self.get_sql(params)
        if params[:operation].class != String
            return nil
        end
        
        operation = params[:operation].downcase
        if operation == 'select'
            return self.get_sql_select(params)
        elsif operation == 'delete'
            return self.get_sql_delete(params)
        elsif operation == 'update'
            return self.get_sql_update(params)
        elsif operation == 'insert'
            return self.get_sql_insert(params)
        else
            return nil
        end
    end

    # Public: Checks the operation Hash value and forwards over the data to correct method
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user_instance1.get_sql({operation: "DELETE", where: "id"})
    #  # => "DELETE FROM users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def get_sql(params)
        if params[:operation].class != String
            return nil
        end
        
        operation = params[:operation].downcase
        if operation == 'select'
            return self.get_sql_select(params)
        elsif operation == 'delete'
            return self.get_sql_delete(params)
        elsif operation == 'update'
            return self.get_sql_update(params)
        elsif operation == 'insert'
            return self.get_sql_insert(params)
        else
            return nil
        end
    end
    
    # Generates a SELECT SQL string which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user_instance1.get_sql_select({operation: "SELECT", where: "id"})
    #  # => "SELECT * FROM users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def get_sql_select(params)
        sql = 'SELECT '
        if params[:columns]
            if params[:columns].class == Array
                params[:columns].each do |column|
                    if column.class == String
                        if sql == 'SELECT '
                            sql += column
                        else
                            sql += ",#{column}"
                        end
                    elsif column.class == Hash && column[:column].class == String
                        if sql == 'SELECT '
                            sql += column[:column]
                        else
                            sql += ",#{column[:column]}"
                        end
                        if column[:rename].class == String && column[:rename].length > 0
                            sql += " AS #{column[:rename]}"
                        end
                    end
                end
            elsif params[:columns].class == String
                sql += params[:columns]
            end
        else
            sql += '*'
        end
        if sql == 'SELECT '
            return nil
        end
        
        if params[:tablename].class == String
            sql += " FROM #{params[:tablename]}"
        elsif @tablename.class == String
            sql += " FROM #{@tablename}"
        else
            return nil
        end

        if params[:left_join].class == Array
            params[:left_join].each do |join_entity|
                if join_entity.class != Array || join_entity.length != 2 || join_entity[0].class != String || join_entity[1].class != String
                    next
                end
                sql += " LEFT JOIN #{join_entity[0]} ON #{join_entity[1]}"
            end
        end

        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        
        if params[:order_by].class == Array
            order_by = " ORDER BY "
            start = true
            params[:order_by].each do |order_entity|
                if order_entity.class == Array && order_entity.length == 2 && (order_entity[0] == 'ASC' || order_entity[0] == 'DESC') && order_entity[1].class == String
                    if start == true
                        start = false
                        order_by += "#{order_entity[1]} #{order_entity[0]}"
                    else
                        order_by += ", #{order_entity[1]} #{order_entity[0]}"
                    end
                end
            end
            if start == false
                sql += order_by
            end
        end
        
        if params[:limit].class == Integer
            sql += " LIMIT #{params[:limit]}"
        end
        if params[:offset].class == Integer
            sql += " OFFSET #{params[:offset]}"
        end
        return sql
    end

    # Generates a SELECT SQL string which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user_instance1.get_sql_select({operation: "SELECT", where: "id"})
    #  # => "SELECT * FROM users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def self.get_sql_select(params)
        sql = 'SELECT '
        if params[:columns]
            if params[:columns].class == Array
                params[:columns].each do |column|
                    if column.class == String
                        if sql == 'SELECT '
                            sql += column
                        else
                            sql += ",#{column}"
                        end
                    elsif column.class == Hash && column[:column].class == String
                        if sql == 'SELECT '
                            sql += column[:column]
                        else
                            sql += ",#{column[:column]}"
                        end
                        if column[:rename].class == String && column[:rename].length > 0
                            sql += " AS #{column[:rename]}"
                        end
                    end
                end
            elsif params[:columns].class == String
                sql += params[:columns]
            end
        else
            sql += '*'
        end
        if sql == 'SELECT '
            return nil
        end

        if params[:tablename].class == String
            sql += " FROM #{params[:tablename]}"
        elsif @tablename.class == String
            sql += " FROM #{@tablename}"
        else
            return nil
        end

        if params[:left_join].class == Array
            params[:left_join].each do |join_entity|
                if join_entity.class != Array || join_entity.length != 2 || join_entity[0].class != String || join_entity[1].class != String
                    next
                end
                sql += " LEFT JOIN #{join_entity[0]} ON #{join_entity[1]}"
            end
        end

        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        
        if params[:order_by].class == Array
            order_by = " ORDER BY "
            start = true
            params[:order_by].each do |order_entity|
                if order_entity.class == Array && order_entity.length == 2 && (order_entity[0] == 'ASC' || order_entity[0] == 'DESC') && order_entity[1].class == String
                    if start == true
                        start = false
                        order_by += "#{order_entity[1]} #{order_entity[0]}"
                    else
                        order_by += ", #{order_entity[1]} #{order_entity[0]}"
                    end
                end
            end
            if start == false
                sql += order_by
            end
        end
        
        if params[:limit].class == Integer
            sql += " LIMIT #{params[:limit]}"
        end
        if params[:offset].class == Integer
            sql += " OFFSET #{params[:offset]}"
        end
        return sql
    end

    # Generates an UPDATE SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user_instance1.get_sql_update({operation: "UPDATE", set: ["username"], where: "id"})
    #  # => "UPDATE SET username=? users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def get_sql_update(params)
        sql = 'UPDATE '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        if params[:set] && params[:set].class == Array
            set_statement = ' SET '
            start = true
            params[:set].each do |entry|
                if entry.class == String
                    if start == true
                        start = false
                        set_statement += "#{entry}=?"
                    else
                        set_statement += ", #{entry}=?"
                    end
                elsif entry.class == Hash
                    if entry[:method].downcase == 'add' && entry[:column].class == String
                        if start == true
                            start = false
                            set_statement += "#{entry[:column]} = #{entry[:column]} + ?"
                        else
                            set_statement += ", #{entry[:column]} = #{entry[:column]} + ?"
                        end
                    end
                end
            end
            if start == false
                sql += set_statement
            else
                return nil
            end
        else
            return nil
        end
        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        return sql
    end

    # Generates an UPDATE SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  user::User.get_sql_update({operation: "UPDATE", set: ["username"], where: "id"})
    #  # => "UPDATE SET username=? users WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def self.get_sql_update(params)
        sql = 'UPDATE '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        if params[:set] && params[:set].class == Array
            set_statement = ' SET '
            start = true
            params[:set].each do |entry|
                if entry.class == String
                    if start == true
                        start = false
                        set_statement += "#{entry}=?"
                    else
                        set_statement += ", #{entry}=?"
                    end
                elsif entry.class == Hash
                    if entry[:method].downcase == 'add' && entry[:column].class == String
                        if start == true
                            start = false
                            set_statement += "#{entry[:column]} = #{entry[:column]} + ?"
                        else
                            set_statement += ", #{entry[:column]} = #{entry[:column]} + ?"
                        end
                    end
                end
            end
            if start == false
                sql += set_statement
            else
                return nil
            end
        else
            return nil
        end
        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        return sql
    end

    # Generates a DELETE SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  product::Product.get_sql_delete({operation: "DELETE", where: "id"})
    #  # => "DELETE FROM products WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def self.get_sql_delete(params)
        sql = 'DELETE FROM '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        return sql
    end

    # Generates a DELETE SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  product_instance1.get_sql_delete({operation: "DELETE", where: "id"})
    #  # => "DELETE FROM products WHERE id=?"
    #
    # Returns String on success and nil or missing but functional data on error
    def get_sql_delete(params)
        sql = 'DELETE FROM '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        if params[:where].class == Array || params[:where].class == String
            where = self.build_where_component('AND', params[:where])
            if where.class == String && where.length > 0
                sql += " WHERE #{where}"
            end
        end
        return sql
    end

    # Generates an INSERT SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  product::Product.get_sql_insert({operation: "INSERT", columns: ["name", "price", "stock", "user_id"]})
    #  # => "INSERT INTO products (name,price,stock,user_id) VALUES(?,?,?,?)"
    #
    # Returns String on success and nil or missing but functional data on error
    def self.get_sql_insert(params)
        sql = 'INSERT INTO '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        columns = '('
        values = 'VALUES('
        if params[:columns].class == Array
            params[:columns].each do |column|
                if column.class != String
                    next
                end
                if columns == '('
                    columns += column
                    values += '?'
                else
                    columns += ",#{column}"
                    values += ',?'
                end
            end
            sql += " #{columns}) #{values})"
        else
            return nil
        end
        return sql
    end

    # Generates an INSERT SQL string for which can be forwarded to a database execute
    #
    # params - Hash of key-value pairs which are required for parsing the SQL String
    #
    # Examples
    #  product_instance1.get_sql_insert({operation: "INSERT", columns: ["name", "price", "stock", "user_id"]})
    #  # => "INSERT INTO products (name,price,stock,user_id) VALUES(?,?,?,?)"
    #
    # Returns String on success and nil or missing but functional data on error
    def get_sql_insert(params)
        sql = 'INSERT INTO '
        if params[:tablename]
            sql += params[:tablename]
        elsif @tablename
            sql += @tablename
        else
            return nil
        end
        columns = '('
        values = 'VALUES('
        if params[:columns].class == Array
            params[:columns].each do |column|
                if column.class != String
                    next
                end
                if columns == '('
                    columns += column
                    values += '?'
                else
                    columns += ",#{column}"
                    values += ',?'
                end
            end
            sql += " #{columns}) #{values})"
        else
            return nil
        end
        return sql
    end
end
require_relative 'superclass'
require 'bcrypt'

class User < Superclass
    
    attr_reader :id, :username, :email, :birth, :stars, :reviewcount, :description, :admin

    # Create a new User instance, not to be run manually
    #
    # db          - SQLite3 object, open database instance
    # id          - Integer, the users id
    # username    - String, the username of the user
    # email       - String, the users email
    # pass_pash   - String, the hashed password for the user
    # bith        - String, the date when the user was born "YYYY.MM.DD"
    # stars       - Integer, the amounts of stars the user has
    # reviewcount - Integer, the amount of users who has starred the user
    # description - String, the users description
    # admin       - Integer, 0 if normal user 1 if admin 
    #
    # Examples
    #  user::User.new(SQLite3::SQLite3::Database, 1, "username", "email@publicshop.io", "weadasde123717easd7a6721535", "2020.02.15", 5, 2, 1)
    #  # => user::User
    #
    # Returns a new instance of the class User
    def initialize(db, id, username, email, pass_hash, birth, stars, reviewcount, description, admin)
        @db = db
        @id = id
        @username = username
        @email = email
        @pass_hash = pass_hash
        @birth = birth
        @stars = stars
        @reviewcount = reviewcount
        @description = description
        @admin = admin
        @tablename = 'users'
    end
    
    # Public: Validates the email and stores it to the @email variable if valid
    #
    # val - String in form of the email-value
    #
    # Examples
    #  user_object.email = "a@a.com"
    #  # => nil
    #
    # Returns nothing
    def email=(val)
        if /^[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-\.]+\.[a-zA-Z]{2,5}$/.match?(val) == false
            return nil
        end
        @email = val
    end
    
    # Public: Validates the username and stores it to the @username variable if valid
    #
    # val - String in form of the username-value
    #
    # Examples
    #  user_object.username = "abcdef"
    #  # => nil
    #
    # Returns nothing
    def username=(val)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: 'id',
            where: 'username',
            limit: 1
        })
        sql = @db.execute(sql, val)

        if sql.length == 0
            @username = val
        end
        return nil
    end

    # Public: Validates the birth date and stores it to the @birth variable if valid
    #
    # val - String in form of the birth-value
    #
    # Examples
    #  user_object.birth = "2015.05.10"
    #  # => nil
    #
    # Returns nothing
    def birth=(val)
        regex = /^(\d{4})\-(\d{2})\-(\d{2})$/.match(val)
        if regex == nil
            return
        end
        #                Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec
        days_in_month = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        year = regex[1].to_i
        month = regex[2].to_i
        day = regex[3].to_i

        year_today = Time.now.year
        if year < year_today - 150 || year > year_today
            return
        end
        if month < 1 || month > 12
            return
        end
        if day < 1 || day > days_in_month[month-1]
            return
        end
        @birth = val
    end

    # Public: Validates the admin variable and stores it to the @admin variable if valid
    #
    # val - Integer in form of the admin-value (1 = true, 0 = false)
    #
    # Examples
    #  user_object.admin = "2015.05.10"
    #  # => nil
    #
    # Returns nothing
    def admin=(val)
        if val != 1 && val != 0
            return
        end
        @admin = val
    end

    # Public: Saves the variables to the database
    #
    # Examples
    #  user1.save()
    #  # => nil
    #
    # Returns nothing
    def save()
        sql = self.get_sql({
            operation: 'UPDATE',
            set: ['username', 'email', 'pass_hash', 'birth', 'description', 'admin'],
            where: 'id'
        })
        @db.execute(sql, @username, @email, @pass_hash, @birth, @description, @admin, @id)
    end

    # Public: Deletes the user from the database
    #
    # Examples
    #  user1.delete()
    #  # => nil
    #
    # Returns nothing
    def delete()
        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'product_parts',
            where: [{column: 'product_id', operator: 'in', columnValue: {
                method: 'inline execute',
                request: {
                    operation: 'SELECT',
                    columns: 'id',
                    tablename: 'products',
                    where: 'user_id'
                }
            }}]
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'product_comments',
            where: [{column: 'product_id', operator: 'in', columnValue: {
                method: 'inline execute',
                request: {
                    operation: 'SELECT',
                    columns: 'id',
                    tablename: 'products',
                    where: 'user_id'
                }
            }}]
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'profile_comments',
            where: [['user_id', 'visitor_id']]
        })
        @db.execute(sql, @id, @id)
        
        sql = self.get_sql({
            operation: 'SELECT',
            columns: 'id',
            where: 'id'
        })
        product_ids = @db.execute(sql, @id)
        product_ids.each do |folder|
            FileUtils.remove_dir("public/img/product_pictures/#{folder['id']}", force=true)
        end
        Dir.glob("public/img/profile_pictures/#{@username.downcase()}.*"). each do |filename|
            File.delete(filename)
        end

        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'products',
            where: 'user_id'
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            where: 'id'
        })
        @db.execute(sql, @id)
    end

    # Public: Signs in the user
    #
    # Examples
    #  User.login(1, "MyPasswordIsSecure")
    #  # => user::User
    #
    # Returns user object on success and nil on failure
    def self.login(user, password)
        sql = self.get_sql({
            operation: 'SELECT',
            where: [['email', 'username']],
            limit: 1
        })
        sql = @db.execute(sql, user.downcase(), user)[0]
        if sql == nil || BCrypt::Password.new(sql['pass_hash']) != password
            return nil
        end
        return self.new(@db, sql['id'], sql['username'], sql['email'], sql['pass_hash'], sql['birth'], sql['stars'], sql['reviewcount'], sql['description'], sql['admin'])
    end

    # Public: Registers a new user
    #
    # Examples
    #  User.register("OriginalUsername", "a@b.com", "Secure123", "2015.10.10")
    #  # => {status: true}
    #
    # Returns the state of the register (errorcode 1 = invalid username, errorcode 2 = invalid email)
    def self.register(username, email, password, birth_date)
        if password.length == 0
            return {status: false, error: 'password_invalid'}
        end
        
        if username.length == 0
            return {status: false, error: 'username_invalid'}
        end
        
        if /^[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-\.]+\.[a-zA-Z]{2,5}$/.match?(email) == false
            return {status: false, error: 'email_invalid'}
        end

        regex = /^(\d{4})\-(\d{2})\-(\d{2})$/.match(birth_date)
        if regex == nil
            return {status: false, error: 'invalid_birth_date'}
        end
        #                Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec
        days_in_month = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        year = regex[1].to_i
        month = regex[2].to_i
        day = regex[3].to_i
        year_today = Time.now.year
        if year < year_today - 150 || year > year_today || month < 1 || month > 12 || day < 1 || day > days_in_month[month-1]
            return {status: false, error: 'invalid_birth_date'}
        end
        pass_hash = BCrypt::Password.create(password)

        sql = self.get_sql({
            operation: 'SELECT',
            where: [['email', 'username']]
        })
        sql_res = @db.execute(sql, email, username)[0]
        if sql_res != nil
            if sql_res['username'].downcase() == username.downcase()
                return {status: false, error: 'username_registered'}
            else
                return {status: false, error: 'email_registered'}
            end
        end
        
        sql = self.get_sql({
            operation: 'INSERT',
            columns: ['username', 'email', 'pass_hash', 'birth']
        })
        @db.execute(sql, username, email.downcase(), pass_hash, birth_date)
        return {status: true}
    end

    # Builds an User object, should be run through User.get_by_user_id(), User.get_by_user_username() etc
    #
    # table_row - SQLite3 response object with hashes enabled which should be parsed
    #
    # Examples
    #  User.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => user::User
    #
    # Returns User object on success and nil on failure
    def self.build(table_row)
        if table_row.class != SQLite3::ResultSet::HashWithTypesAndFields || table_row['id'] == nil || table_row['username'] == nil || table_row['email'] == nil || table_row['pass_hash'] == nil || table_row['birth'] == nil || table_row['stars'] == nil || table_row['reviewcount'] == nil || table_row['description'] == nil || table_row['admin'] == nil
            return nil
        end

        return self.new(@db, table_row['id'], table_row['username'], table_row['email'], table_row['pass_hash'], table_row['birth'], table_row['stars'], table_row['reviewcount'], table_row['description'], table_row['admin'])
    end

    # Public: Fetches a specific amount of users with highest review-score which have to be higher than 0
    #
    # count - Integer, amount of people to get
    #
    # Examples
    #  User.get_top_rated(3)
    #  # => [user::User, user::User, user::User]
    #
    # Returns Array of User objects
    def self.get_top_rated(rawcount)
        if rawcount.class != Integer || rawcount.to_i.to_s != rawcount.to_s
            count = 10
        else
            count = rawcount.to_i
        end
        
        sql = self.get_sql({
            operation: 'SELECT',
            where: [{column: 'reviewcount', operator: '>', columnValue: '0'}],
            order_by: [['DESC', 'stars/reviewcount']],
            limit: count
        })
        sql = @db.execute(sql)
        user_array = []
        sql.each do |row|
            usr = self.build(row)
            if usr != nil
                user_array << usr
            end
        end
        return user_array
    end

    # Public: Extracts an user which matches on the the parameters
    #
    # or_params - Hash where the key is the column and the value is the column value
    #
    # Examples
    #  User.get({"email" => "a@b.com", "username" => "a"})
    #  # => user::User
    #
    # Returns User object on success or nil on failure
    def self.get(or_params)
        or_statements = []
        args = []
        or_params.each do |entity|
            or_statements << entity[0]
            args << entity[1]
        end
        
        sql = self.get_sql({
            operation: 'SELECT',
            where: [or_statements],
            limit: 1
        })
        sql = @db.execute(sql, args)[0]
        return build(sql)
    end

    # Public: Extracts the user which has the forwarded id
    #
    # id - Integer in form of the user id to get
    #
    # Examples
    #  User.get(1)
    #  # => user::User
    #
    # Returns User object on success or nil on failure
    def self.get_by_id(id)
        sql = self.get_sql({
            operation: 'SELECT',
            where: 'id',
            limit: 1
        })
        sql = @db.execute(sql, id)[0]
        return build(sql)
    end

    # Public: Extracts the user which has the forwarded username
    #
    # username - String in form of the username to get
    #
    # Examples
    #  User.get_by_username("hello")
    #  # => user::User
    #
    # Returns User object on success or nil on failure
    def self.get_by_username(username)
        sql = self.get_sql({
            operation: 'SELECT',
            where: 'username',
            limit: 1
        })
        sql = @db.execute(sql, username)[0]
        return build(sql)
    end

    # Public: Extracts the user which has the forwarded email
    #
    # email - String in form of the email to get
    #
    # Examples
    #  User.get_by_email("a@b.com")
    #  # => user::User
    #
    # Returns User object on success or nil on failure
    def self.get_by_email(email)
        sql = self.get_sql({
            operation: 'SELECT',
            where: 'email',
            limit: 1
        })
        sql = @db.execute(sql, email.downcase())[0]
        return build(sql)
    end
end
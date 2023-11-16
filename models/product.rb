require_relative 'superclass'
require_relative 'product_part'
require 'fileutils'

class Product < Superclass
    
    attr_reader :id, :name, :price, :stock, :description, :user_id, :username, :images, :addons, :stars, :reviewcount

    attr_writer :name, :price, :stock, :description, :user_id

    # Create a new Product instance, not to be run manually
    #
    # db          - SQLite3 object, open database instance
    # id          - Integer, the products id
    # name        - String, the name of the product
    # price       - Integer, the price of the product
    # stock       - Integer, how many of the product is left
    # description - String, description about the product
    # stars       - Integer, the amount of stars the product has received
    # reviewcount - Integer, the amount of users who has left a comment on the product
    # user_id     - Integer, the user id of the one who owns the the part
    # username    - String, the name of the user who owns the product
    #
    # Examples
    #  product::Product.new(SQLite3::Database, 1, 1, 1, "groupname", "partname", 1)
    #  # => product::Product
    #
    # Returns a new instance of the class Product
    def initialize(db, id, name, price, stock, description, stars, reviewcount, user_id, username)
        @db = db
        @id = id
        @name = name
        @price = price
        @stock = stock
        @description = description
        @stars = stars
        @reviewcount = reviewcount
        @user_id = user_id
        @username = username
        @images = Dir.glob("img/product_pictures/#{id}/*", base: 'public')
        @addons = {}
        @tablename = 'products'
    end

    # Public: Saves the variables to the database
    #
    # Examples
    #  product1.save()
    #  # => nil
    #
    # Returns nothing
    def save()
        sql = self.get_sql({
            operation: 'UPDATE',
            set: ['name', 'price', 'stock', 'description', 'user_id'],
            where: 'id'
        })
        @db.execute(sql, @name, @price, @stock, @description, @user_id, @id)
    end

    # Public: Deletes the product from the database
    #
    # Examples
    #  product1.delete()
    #  # => nil
    #
    # Returns nothing
    def delete()
        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'product_parts',
            where: 'product_id'
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'product_comments',
            where: 'product_id'
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            where: 'id'
        })
        @db.execute(sql, @id)
        FileUtils.remove_dir("public/img/product_pictures/#{@id}", force=true)
    end

    # Adds a part/group to the product
    #
    # Examples
    #  product1.add_local_addon(product_part::Product_part)
    #  # => nil
    #
    # Returns nothing
    def add_local_addon(obj)
        if @addons[obj.groupname] == nil
            @addons[obj.groupname] = [obj]
        else
            @addons[obj.groupname] << obj
        end
    end

    # Public: Fetches the <count> products with highest review-score which have to be higher than 0
    #
    # count - Integer, amount of products to get
    #
    # Examples
    #  Product.get_top_rated(3)
    #  # => [product::Product, product::Product, product::Product]
    #
    # Returns Array of Product objects
    def self.get_top_rated(rawcount)
        if rawcount.class == Integer
            count = rawcount
        elsif rawcount.to_i.to_s == rawcount.to_s
            count = rawcount.to_i
        else
            count = 10
        end
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['products.*', 'users.username'],
            left_join: [['users', 'products.user_id = users.id']],
            where: [{column: 'products.reviewcount', operator: '>', columnValue: '0'}],
            order_by: [['DESC', 'products.stars/products.reviewcount']],
            limit: count
        })
        sql = @db.execute(sql)
        product_array = []
        sql.each do |row|
            product = self.build(row)
            if product != nil
                product_array << product
            end
        end
        return product_array
    end

    # Builds an User object, should be run through User.get_by_user_id(), User.get_by_user_username() etc
    #
    # table_row - SQLite3 response object with hashes enabled to parse
    #
    # Examples
    #  User.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => user::User
    #
    # Returns User object on success and nil on failure
    def self.build(table_row)
        if table_row.class != SQLite3::ResultSet::HashWithTypesAndFields || table_row['id'] == nil || table_row['name'] == nil || table_row['price'] == nil || table_row['stock'] == nil || table_row['description'] == nil || table_row['stars'] == nil || table_row['reviewcount'] == nil || table_row['user_id'] == nil || table_row['username'] == nil
            return nil
        end

        return self.new(@db, table_row['id'], table_row['name'], table_row['price'], table_row['stock'], table_row['description'], table_row['stars'], table_row['reviewcount'], table_row['user_id'], table_row['username'])
    end

    # Public: Fetches all products owned by the user
    #
    # user_id - Integer in form of the id of an user
    #
    # Examples
    #  Product.all(1)
    #  # => [product::Product, product::Product, product::Product]
    #
    # Returns an Array of Product objects
    def self.all(user_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['products.*', 'product_parts.groupname', 'product_parts.partname', 'product_parts.bonus_price', {column: 'product_parts.id', rename: 'part_id'}, 'users.username'],
            left_join: [['users', 'products.user_id = users.id'], ['product_parts', 'products.id = product_parts.product_id']],
            where: 'user_id'
        })
        sql = @db.execute(sql, user_id)
        productIndexes = {}
        products = []

        sql.each do |product|
            if productIndexes[product['id']] == nil
                products << build(product)
                productIndexes[product['id']] = products.length-1
            end
            if product['groupname'] != nil
                products[productIndexes[product['id']]].add_local_addon(Product_part.new(@db, product['part_id'], product['id'], product['user_id'], product['groupname'], product['partname'], product['bonus_price']))
            end
        end
        return products
    end
    
    # Public: Get a specific product
    #
    # id - Integer in form of the product id
    #
    # Examples
    #  Product.get_by_id(1)
    #  # => product::Product
    #
    # Returns Product object on success or nil on failure
    def self.get_by_id(id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['products.*', 'product_parts.groupname', 'product_parts.partname', 'product_parts.bonus_price', {column: 'product_parts.id', rename: 'part_id'}, 'users.username'],
            left_join: [['users', 'products.user_id = users.id'], ['product_parts', 'products.id = product_parts.product_id']],
            where: 'products.id'
        })
        sql = @db.execute(sql, id)
        product = build(sql[0])
        sql.each do |row|
            if row['groupname'] != nil
                product.add_local_addon(Product_part.new(@db, row['part_id'], id, row['user_id'], row['groupname'], row['partname'], row['bonus_price']))
            end
        end
        return product
    end
    
    # Public: Get all products who starts with a specific String
    #
    # query - String in form of the product name search
    #
    # Examples
    #  Product.search_by_name("ro")
    #  # => [product::Product, product::Product, product::Product]
    #
    # Returns an Array of Product objects
    def self.search_by_name(query)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['products.*', 'users.username'],
            left_join: [['users', 'products.user_id = users.id']],
            where: [{column: 'name', operator: 'LIKE'}]
        })
        sql = @db.execute(sql, query.gsub('\\', '\\\\').gsub('%', '\\%') + '%')
        products = []
        sql.each do |row|
            product = self.build(row)
            if product != nil
                products << product
            end
        end
        return products
    end

    # Public: Create a new product
    #
    # user_id     - Integer in form of the id of the user who owns the product
    # name        - String which is the name of the product to create
    # price       - Integer which is the price of the product
    # stock       - Integer which is the amount of the product which is available
    # description - String which is the product desciption
    #
    # Examples
    #  Product.create(1, "duck", 123, 25, "The duck says honk!")
    #  # => nil
    #
    # Returns nothing
    def self.create(user_id, name, price, stock, description)
        if name.length == 0
            return nil
        end

        sql = self.get_sql({
            operation: 'SELECT',
            columns: 'name',
            where: ['id', 'name']
        })
        existing_products = @db.execute(sql, user_id, name)
        if existing_products.length > 0
            return nil
        end

        sql = self.get_sql({
            operation: 'INSERT',
            columns: ['user_id', 'name', 'price', 'stock', 'description']
        })
        @db.execute(sql, user_id, name, price, stock, description)
        return nil
    end
end
class Product_part < Superclass
    
    attr_reader :id, :product_id, :groupname, :partname, :bonus_price, :user_id
    attr_writer :partname, :bonus_price, :user_id

    # Create a new Product_part instance, not to be run manually
    #
    # db          - SQLite3 object, open database instance
    # id          - Integer, the parts id
    # product_id  - Integer, the id of the product which owns the part
    # user_id     - Integer, the user id of the one who owns the the part
    # groupname   - String, the group which the part is a part of
    # partname    - String, the name of the part
    # bonus_price - Integer, the price of the part
    #
    # Examples
    #  product_part::Product_part.new(SQLite3::Database, 1, 1, 1, "groupname", "partname", 1)
    #  # => product_part::Product_part
    #
    # Returns a new instance of the class Product_part
    def initialize(db, id, product_id, user_id, groupname, partname, bonus_price)
        @db = db
        @id = id
        @product_id = product_id
        @user_id = user_id
        @groupname = groupname
        @partname = partname
        @bonus_price = bonus_price
        @tablename = 'product_parts'
    end

    # Public: Saves the variables to the database
    #
    # Examples
    #  part1.save()
    #  # => nil
    #
    # Returns nothing
    def save()
        sql = self.get_sql({
            operation: 'UPDATE',
            set: ['partname', 'bonus_price'],
            where: 'id'
        })
        @db.execute(sql, @partname, @bonus_price, @id)
    end

    # Public: Deletes the part to the database
    #
    # Examples
    #  part1.delete()
    #  # => nil
    #
    # Returns nothing
    def delete()
        sql = self.get_sql({
            operation: 'DELETE',
            where: 'id'
        })
        @db.execute(sql, @id)
    end
    

    # Public: Deletes all parts who shares group in the database
    #
    # Examples
    #  part1.delete_group()
    #  # => nil
    #
    # Returns nothing
    def delete_group()
        sql = self.get_sql({
            operation: 'DELETE',
            where: ['product_id', 'groupname']
        })
        @db.execute(sql, @product_id, @groupname)
    end

    # Builds a Part object, should not be run manually
    #
    # row - SQLite3 response object with hashes enabled which should be parsed
    #
    # Examples
    #  Product_part.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => product_part::Product_part
    #
    # Returns Product_part object on success and nil on failure
    def self.build(row)
        if row.class != SQLite3::ResultSet::HashWithTypesAndFields || row['id'] == nil || row['product_id'] == nil || row['groupname'] == nil || row['partname'] == nil || row['bonus_price'] == nil || row['user_id'] == nil
            return nil
        end

        return self.new(@db, row['id'], row['product_id'], row['user_id'], row['groupname'], row['partname'], row['bonus_price'])
    end

    # Public: Extracts the part which has the forwarded id
    #
    # id - Integer in form of the part id to get
    #
    # Examples
    #  Product_part.get(1)
    #  # => product_part::Product_part
    #
    # Returns Product_part object on success or nil on failure
    def self.get_by_id(id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['product_parts.*', 'products.user_id'],
            left_join: [['products', 'product_parts.product_id = products.id']],
            where: 'product_parts.id',
            limit: 1
        })
        sql = @db.execute(sql, id)
        if sql.length == 0
            return nil
        end
        return self.build(sql[0])
    end

    # Public: Extracts the part which has the forwarded id
    #
    # id - Integer in form of the part id to get
    #
    # Examples
    #  Product_part.get_by_product_id(1)
    #  # => {"group1" => [product_part::Product_part, product_part::Product_part, product_part::Product_part], "group2" => [product_part::Product_part, product_part::Product_part]}
    #
    # Returns an Hash containing Array of Product_part objects
    def self.get_by_product_id(product_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['product_parts.*', 'products.user_id'],
            left_join: [['products', 'product_parts.product_id = products.id']],
            where: 'product_parts.product_id'
        })
        sql = @db.execute(sql, product_id)
        if sql.length == 0
            return nil
        end
        groups_and_parts = {}
        sql.each do |item|
            new_object = self.build(item)
            if new_object == nil
                next
            end
            if groups_and_parts[new_object.groupname] == nil
                groups_and_parts[new_object.groupname] = [new_object]
            else
                groups_and_parts[new_object.groupname] << new_object
            end
        end
        return groups_and_parts
    end

    # Public: Extracts the part which has the forwarded id
    #
    # product_id - Integer in form of the product id which the part should be bound to
    # groupname - String in form of the group name
    # partname - String in form of the part name
    # bonus_price - Integer in form of the part price
    #
    # Examples
    #  Product_part.create(1, "a", "b", 125)
    #  # => nil
    #
    # Returns nothing
    def self.create(product_id, groupname, partname, bonus_price)
        sql = self.get_sql({
            operation: 'INSERT',
            columns: ['product_id', 'groupname', 'partname', 'bonus_price']
        })
        @db.execute(sql, product_id, groupname, partname, bonus_price)
    end
end
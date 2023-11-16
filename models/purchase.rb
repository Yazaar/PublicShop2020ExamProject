require_relative 'superclass'
require_relative 'purchase_config'

class Purchase < Superclass
    
    attr_reader :id, :user_id, :product_id, :product_name, :base_price, :shop_owner, :shop_owner_name, :timestamp, :checked_out, :configs

    # Create a new Purchase_config instance, not to be run manually
    #
    # db              - SQLite3 object, open database instance
    # id              - Integer, the id of the purchase
    # user_id         - Integer, the user who made the purchase
    # product_id      - Integer, the id of the product
    # product_name    - String, the name of the purchased product
    # base_price      - Integer, the price of the product alone
    # shop_owner      - Integer, the id of the user who owns the purchased product
    # shop_owner_name - String, the username of the user who owns the product
    # timestamp       - String, timestamp of when the purchase was done
    # checked_out     - Integer, 0 if not payed and 1 if payed
    #
    # Examples
    #  purchase::Purchase.new(SQLite3::Database, 1, 1, 1, "product name", 100, 1, "shopownername", "2020-03-11 11:03:59", 0)
    #  # => purchase::Purchase
    #
    # Returns a new instance of the class Purchase
    def initialize(db, id, user_id, product_id, product_name, base_price, shop_owner, shop_owner_name, timestamp, checked_out)
        @db = db
        @id = id
        @user_id = user_id
        @product_id = product_id
        @product_name = product_name
        @base_price = base_price
        @shop_owner = shop_owner
        @shop_owner_name = shop_owner_name
        @timestamp = timestamp
        @checked_out = checked_out
        @configs = []
        @tablename = 'purchases'
    end

    # Appends a configuration to the purchase (part/group)
    # 
    # id          - Integer in form of the purchase_config id
    # groupname   - String in form of the groupname of the purchase_config
    # partname    - String in form of the partname of the purchase_config
    # bonus_price - Integer in form of the price of the part
    #
    # Examples
    #  p1.add_config(1, "a", "b", 100)
    #  # => nil
    #
    # Returns nothing
    def add_config(id, groupname, partname, bonus_price)
        @configs << Purchase_config.new(id, groupname, partname, bonus_price)
    end

    # Public: Remove the purchase from the database
    #
    # Examples
    #  purchase.delete()
    #  # => nil
    #
    # Returns nothing
    def delete()
        sql = self.get_sql({
            operation: 'DELETE',
            tablename: 'purchase_configs',
            where: 'purchase_id'
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'DELETE',
            where: 'id'
        })
        @db.execute(sql, @id)

        sql = self.get_sql({
            operation: 'UPDATE',
            tablename: 'products',
            set: [{method: 'add', column: 'stock'}],
            where: 'id'
        })
        @db.execute(sql, 1, @product_id)
    end

    # Builds a Purchase object, should not be run manually
    #
    # table_row - SQLite3 response object with hashes enabled which should be parsed
    #
    # Examples
    #  Purchase.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => purchase::Purchase
    #
    # Returns Purchase object on success and nil on failure
    def self.build(table_row)
        if table_row.class != SQLite3::ResultSet::HashWithTypesAndFields || table_row['id'] == nil || table_row['user_id'] == nil || table_row['product_id'] == nil || table_row['product_name'] == nil || table_row['base_price'] == nil || table_row['shop_owner'] == nil || table_row['shop_owner_name'] == nil || table_row['timestamp'] == nil || table_row['checked_out'] == nil
            return nil
        end
        return self.new(@db, table_row['id'], table_row['user_id'], table_row['product_id'], table_row['product_name'], table_row['base_price'], table_row['shop_owner'], table_row['shop_owner_name'], table_row['timestamp'], table_row['checked_out'])
    end

    # Public: Fetches all purchases for a specific user
    #
    # user_id - Integer in form of the user id to be fetched
    #
    # Examples
    #  Purchase.get_all_by_user_id(1)
    #  # => [purchase::Purchase, purchase::Purchase, purchase::Purchase, purchase::Purchase]
    #
    # Returns an Array of Purchase objects
    def self.get_all_by_user_id(user_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['purchases.*', 'purchase_configs.groupname', 'purchase_configs.partname', 'purchase_configs.bonus_price', {column: 'purchase_configs.id', rename: 'part_id'}],
            left_join: [['purchase_configs', 'purchases.id = purchase_configs.purchase_id']],
            where: ['purchases.user_id', 'purchases.checked_out'],
            order_by: [['DESC', 'purchases.id']]
        })
        cart = @db.execute(sql, user_id, 0)
        history = []
        cart.each do |row|
            if history.length == 0 || history.last.id != row['id']
                item = self.build(row)
                if item != nil
                    history << item
                end
            end
            if row['groupname'] != nil && row['partname'] != nil && row['bonus_price'] != nil && row['part_id'] != nil
                history.last.add_config(row['part_id'], row['groupname'], row['partname'], row['bonus_price'])
            end
        end
        return history
    end

    # Public: Get a specific purchase by the id
    #
    # purchase_id - Integer in form of the purchase id to be fetched
    #
    # Examples
    #  Purchase.get_by_id(1)
    #  # => purchase::Purchase
    #
    # Returns a Purchase object or nil if it were not found
    def self.get_by_id(purchase_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['purchases.*', 'purchase_configs.groupname', 'purchase_configs.partname', 'purchase_configs.bonus_price', {column: 'purchase_configs.id', rename: 'part_id'}],
            left_join: [['purchase_configs', 'purchases.id = purchase_configs.purchase_id']],
            where: 'purchases.id'
        })
        cart = @db.execute(sql, purchase_id)
        if cart.length == 0
            return nil
        end
        purchase = self.build(cart[0])
        if purchase == nil
            return nil
        end
        cart.each do |row|
            if row['groupname'] != nil && row['partname'] != nil && row['bonus_price'] != nil && row['part_id'] != nil
                purchase.add_config(row['part_id'], row['groupname'], row['partname'], row['bonus_price'])
            end
        end
        return purchase
    end

    # Public: Create a new purchase and save it to the database
    #
    # user_id      - Integer in form of the id of the user who owns the product
    # product_data - product::Product object of the purchased item
    # parts        - Hash of selected all parts (key = groupname, value = partname)
    #
    # Examples
    #  Product.create(1, product::Product, {"a" => "b", "c" => "d"})
    #  # => nil
    #
    # Returns nothing
    def self.create(user_id, product_data, parts)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        sql = self.get_sql({
            operation: 'INSERT',
            columns: ['user_id', 'product_id', 'product_name', 'base_price', 'shop_owner', 'shop_owner_name', 'timestamp']
        })
        @db.execute(sql, user_id, product_data.id, product_data.name, product_data.price, product_data.user_id, product_data.username, timestamp)
        purchase_id = @db.execute('SELECT id FROM purchases WHERE user_id = ? AND product_id = ? AND timestamp = ? ORDER BY id DESC LIMIT 1', user_id, product_data.id, timestamp)[0]['id']
        parts.each do |part|
            if product_data.addons[part[0]] == nil
                next
            end
            
            price = -1
            product_data.addons[part[0]].each do |existing_part|
                if existing_part.partname == part[1]
                    price = existing_part.bonus_price
                    break
                end
            end
            if price != -1
                sql = self.get_sql({
                    operation: 'SELECT',
                    tablename: 'purchase_configs',
                    columns: ['purchase_id', 'groupname', 'partname', 'bonus_price']
                })
                @db.execute(sql, purchase_id, part[0], part[1], price)
            end
        end
    end
end
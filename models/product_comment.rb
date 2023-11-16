require_relative 'superclass'

class Product_comment < Superclass
    
    attr_reader :id, :user_id, :username, :product_id, :timestamp, :rating, :comment

    # Create a new Product_comment instance, not to be run manually
    #
    # db         - SQLite3 object, open database instance
    # id         - Integer, the comments id
    # user_id    - Integer, the user id of the one who made the comment
    # username   - String, the username of the one who made the comment
    # product_id - Integer, the id of the product which has the comment
    # timestamp  - String, with a formatted date and time
    # rating     - Integer, the amount of stars the comment gave the product
    # comment    - String, the actual comment
    #
    # Examples
    #  product_comment::Product_comment.new(SQLite3::SQLite3::Database, 1, 1, "username", 1, "2020.02.15 11:11", 5, "Amazing comment")
    #  # => product_comment::Product_comment
    #
    # Returns a new instance of the class Product_comment
    def initialize(db, id, user_id, username, product_id, timestamp, rating, comment)
        @db = db
        @id = id
        @user_id = user_id
        @username = username
        @product_id = product_id
        @timestamp = timestamp
        @rating = rating
        @comment = comment
        @tablename = 'product_comments'
    end

    # Builds an Product_comment object, should be run through Product_comment.get_by_product_id()
    #
    # row - SQLite3 response object with hashes enabled which should be parsed
    #
    # Examples
    #  Product_comment.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => product_comment::Product_comment
    #
    # Returns Product_comment object on success and nil on error
    def self.build(row)
        if row['id'] == nil || row['user_id'] == nil || row['username'] == nil || row['product_id'] == nil || row['timestamp'] == nil || row['rating'] == nil || row['comment'] == nil
            return nil
        end
        return self.new(@db, row['id'], row['user_id'], row['username'], row['product_id'], row['timestamp'], row['rating'], row['comment'])
    end

    # Public: create a new comment on a specific product
    #
    # user_id    - Integer in form of the user_id which made the comment
    # product_id - Integer in form of the product_id which the comment is commented on
    # comment    - String which is the actual comment to set
    # rating     - Integer between 1 and 5
    #
    # Examples
    #  Product_comment.create(1, 2, "Hello world", 3)
    #  # => nil
    #
    # Returns nothing
    def self.create(user_id, product_id, comment, rating)
        if rating.is_a?(Integer) == false || rating > 5 || rating < 0
            return
        end
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['product_comments.*', 'users.username'],
            left_join: [['users', 'users.id = product_comments.user_id']],
            where: ['product_comments.user_id', 'product_comments.product_id']
        })
        current_comment = @db.execute(sql, user_id, product_id)[0]
        if current_comment == nil
            
            sql = self.get_sql({
                operation: 'INSERT',
                columns: ['user_id', 'product_id', 'timestamp', 'rating', 'comment'],
            })
            @db.execute(sql, user_id, product_id, Time.now().strftime('%Y.%m.%d_%H:%M'), rating, comment)

            sql = self.get_sql({
                operation: 'UPDATE',
                tablename: 'products',
                set: [{method: 'add', column: 'reviewcount'}, {method: 'add', column: 'stars'}],
                where: 'id'
            })
            @db.execute(sql, 1, rating, product_id)
        elsif current_comment['rating'] == rating && current_comment['comment'] == comment
            return
        else
            sql = self.get_sql({
                operation: 'UPDATE',
                tablename: 'products',
                set: [{method: 'add', column: 'stars'}],
                where: 'id'
            })
            @db.execute(sql, rating-current_comment['rating'], product_id)

            sql = self.get_sql({
                operation: 'UPDATE',
                set: ['timestamp', 'rating', 'comment'],
                where: ['product_id', 'user_id']
            })
            @db.execute(sql, Time.now().strftime('%Y.%m.%d %H:%M:%S'), rating, comment, product_id, user_id)
        end
    end

    # Public: Get all comments on a specific product
    #
    # product_id - Integer in form of the id of the product
    #
    # Examples
    #  Product_comment.get_by_user_id(1)
    #  # => [product_comment::Product_comment, product_comment::Product_comment]
    #
    # Returns an Array of Product_comment objects
    def self.get_by_product_id(product_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['product_comments.*', 'users.username'],
            left_join: [['users', 'product_comments.user_id = users.id']],
            where: 'product_id'
        })
        sql = @db.execute(sql, product_id)
        comments = []
        sql.each do |comment|
            comment_object = self.build(comment)
            if comment_object != nil
                comments << comment_object
            end
        end
        return comments
    end
end
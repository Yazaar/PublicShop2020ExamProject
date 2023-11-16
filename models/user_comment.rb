require_relative 'superclass'

class User_comment < Superclass
    
    attr_reader :id, :user_id, :visitor_id, :username, :timestamp, :rating, :comment

    # Create a new User_comment instance, not to be run manually
    #
    # db         - SQLite3 object, open database instance
    # id         - Integer, the comments id
    # user_id    - Integer, the user id of the one who has the comment
    # visitor_id - Integer, the id of the user which made the comment
    # username   - String, the username of the one who made the comment
    # timestamp  - String, with a formatted date and time
    # rating     - Integer, the amount of stars the comment gave the product
    # comment    - String, the actual comment
    #
    # Examples
    #  user_comment::User_comment.new(SQLite3::SQLite3::Database, 1, 1, 2, "username", "2020.02.15 11:11", 5, "Amazing comment")
    #  # => user_comment::User_comment
    #
    # Returns a new instance of the class User_comment
    def initialize(db, id, user_id, visitor_id, username, timestamp, rating, comment)
        @db = db
        @id = id
        @user_id = user_id
        @visitor_id = visitor_id
        @username = username
        @timestamp = timestamp
        @rating = rating
        @comment = comment
        @tablename = 'profile_comments'
    end

    # Builds an User_comment object, should be run through User_comment.get_by_user_id()
    #
    # row - SQLite3 response object with hashes enabled which should be parsed
    #
    # Examples
    #  User_comment.build(SQLite3::ResultSet::HashWithTypesAndFields)
    #  # => user_comment::User_comment
    #
    # Returns User_comment object on success and nil on error
    def self.build(row)
        if row.class != SQLite3::ResultSet::HashWithTypesAndFields || row['id'] == nil || row['user_id'] == nil || row['username'] == nil || row['visitor_id'] == nil || row['timestamp'] == nil || row['rating'] == nil || row['comment'] == nil
            return nil
        end
        return self.new(@db, row['id'], row['user_id'], row['visitor_id'], row['username'], row['timestamp'], row['rating'], row['comment'])
    end

    # Public: create a new comment on a specific user
    #
    # user_id    - Integer in form of the user_id which the comment is commented on
    # visitor_id - Integer in form of the user_id which made the comment
    # comment    - String which is the actual comment to set
    # rating     - Integer between 1 and 5
    #
    # Examples
    #  User_comment.create(1, 2, "Hello world", 3)
    #  # => nil
    #
    # Returns nothing
    def self.create(user_id, visitor_id, comment, rating)
        if rating.is_a?(Integer) == false || rating > 5 || rating < 0
            return nil
        end
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['rating', 'comment'],
            where: ['user_id', 'visitor_id']
        })
        current_comment = @db.execute(sql, user_id, visitor_id)[0]
        
        if current_comment == nil
            sql = self.get_sql({
                operation: 'INSERT',
                columns: ['user_id', 'visitor_id', 'timestamp', 'rating', 'comment']
            })
            @db.execute(sql, user_id, visitor_id, Time.now().strftime('%Y.%m.%d %H:%M:%S'), rating, comment)

            sql = self.get_sql({
                operation: 'UPDATE',
                tablename: 'users',
                set: [{method: 'add', column: 'reviewcount'}, {method: 'add', column: 'stars'}],
                where: 'id'
            })
            @db.execute(sql, 1, rating, user_id)
        elsif current_comment['rating'] == rating && current_comment['comment'] == comment
            return nil
        else
            sql = self.get_sql({
                operation: 'UPDATE',
                tablename: 'users',
                set: {method: 'add', column: 'stars'},
                where: 'id'
            })
            @db.execute(sql, rating-current_comment['rating'], user_id)

            sql = self.get_sql({
                operation: 'UPDATE',
                set: ['timestamp', 'rating', 'comment'],
                where: ['visitor_id', 'user_id']
            })
            @db.execute(sql, Time.now().strftime('%Y.%m.%d_%H:%M'), rating, comment, visitor_id, user_id)
        end
        return nil
    end

    # Public: Get all comments on a specific user
    #
    # user_id - Integer in form of the id of the user
    #
    # Examples
    #  User_comment.get_by_user_id(1)
    #  # => [user_comment::User_comment, user_comment::User_comment]
    #
    # Returns an Array of User_comment objects
    def self.get_by_user_id(user_id)
        sql = self.get_sql({
            operation: 'SELECT',
            columns: ['profile_comments.*', 'users.username'],
            left_join: [['users', 'profile_comments.visitor_id = users.id']],
            where: 'user_id'
        })
        sql = @db.execute(sql, user_id)
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
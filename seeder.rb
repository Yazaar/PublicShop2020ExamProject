require 'sqlite3'
require 'bcrypt'

class Seeder
    # Creates a new database-instance
    #
    # filename - String in form of the database name
    #
    # Examples
    #  seeder::Seeder.openDB("database.db")
    #  # => SQLite3::Database
    #
    # Returns database object
    def self.open_db(filename)
        SQLite3::Database.new 'db/' + filename
    end

    # Drops the tables in the forwared database
    #
    # db - SQLite3::Database object to drop tables out of
    #
    # Examples
    #  seeder::Seeder.drop_tables(SQLite3::Database)
    #  # => nil
    #
    # Returns nothing
    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS users;')
        db.execute('DROP TABLE IF EXISTS profile_comments;')
        db.execute('DROP TABLE IF EXISTS products;')
        db.execute('DROP TABLE IF EXISTS product_parts;')
        db.execute('DROP TABLE IF EXISTS product_comments;')
        db.execute('DROP TABLE IF EXISTS purchases;')
        db.execute('DROP TABLE IF EXISTS purchase_configs;')
    end

    # Creates tables in the forwared database
    #
    # db - SQLite3::Database object to fill with tables
    #
    # Examples
    #  seeder::Seeder.createTables(SQLite3::Database)
    #  # => nil
    #
    # Returns nothing
    def self.create_tables(db)
        db.execute(%{
            CREATE TABLE "users" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "username"	    TEXT NOT NULL UNIQUE COLLATE NOCASE,
                "email"	        TEXT NOT NULL UNIQUE,
                "pass_hash"	    TEXT NOT NULL,
                "birth"	        TEXT NOT NULL,
                "stars"         INTEGER NOT NULL DEFAULT 0,
                "reviewcount"   INTEGER NOT NULL DEFAULT 0,
                "description"	TEXT DEFAULT '',
                "admin"         INTEGER NOT NULL DEFAULT 0
            );}
        )
        db.execute(%{
            CREATE TABLE "profile_comments" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id"	    INTEGER NOT NULL,
                "visitor_id"	INTEGER NOT NULL,
                "timestamp"      TEXT NOT NULL,
                "rating"	    INTEGER,
                "comment"	    TEXT NOT NULL
            );}
        )
        db.execute(%{
            CREATE TABLE "products" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"	        TEXT NOT NULL COLLATE NOCASE,
                "price"	        INTEGER NOT NULL,
                "stars" 	    INTEGER NOT NULL DEFAULT 0,
                "reviewcount"   INTEGER NOT NULL DEFAULT 0,
                "stock"	        INTEGER NOT NULL,
                "description"	TEXT NOT NULL DEFAULT '',
                "user_id"	    INTEGER NOT NULL
            );}
        )
        db.execute(%{
            CREATE TABLE "product_parts" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "product_id"    INTEGER NOT NULL,
                "groupname"     TEXT NOT NULL,
                "partname"      TEXT NOT NULL,
                "bonus_price"   INTEGER NOT NULL
            );}
        )
        db.execute(%{
            CREATE TABLE "product_comments" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id"	    INTEGER NOT NULL,
                "product_id"	INTEGER NOT NULL,
                "timestamp"     TEXT NOT NULL,
                "rating"	    INTEGER,
                "comment"	    TEXT NOT NULL
            );}
        )
        db.execute(%{
            CREATE TABLE "purchases" (
                "id"	            INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id"	        INTEGER NOT NULL,
                "product_id"        INTEGER NOT NULL,
                "product_name"	    TEXT NOT NULL,
                "base_price"        INTEGER NOT NULL,
                "shop_owner"        INTEGER NOT NULL,
                "shop_owner_name"   TEXT NOT NULL,
                "timestamp"         TEXT NOT NULL,
                "checked_out"	    INTEGER NOT NULL DEFAULT 0
            );}
        )
        db.execute(%{
            CREATE TABLE "purchase_configs" (
                "id"	        INTEGER PRIMARY KEY AUTOINCREMENT,
                "purchase_id"   INTEGER NOT NULL,
                "groupname"	    TEXT NOT NULL,
                "partname"      TEXT NOT NULL,
                "bonus_price"   INTEGER NOT NULL
            );}
        )
    end

    # Fill tables in the forwarded database object
    #
    # db - SQLite3::Database object to fill tables in
    #
    # Examples
    #  seeder::Seeder.fill_tables(SQLite3::Database)
    #  # => nil
    #
    # Returns nothing
    def self.fill_tables(db)
        users = [
            {username: 'Bob', email: 'bob@publicshop.io', pass_hash: BCrypt::Password.create('bobross'), birth: '2000.12.24', description: 'Love shopping', admin: 0},
            {username: 'Ulf', email: 'ulf@publicshop.io', pass_hash: BCrypt::Password.create('secure'), birth: '1995.08.20', description: 'Hate shopping', admin: 0},
            {username: 'Rasmus', email: 'rasmus@publicshop.io', pass_hash: BCrypt::Password.create('Kissemisse'), birth: '2001.03.14', description: 'Love shopping', admin: 0},
            {username: 'Adam', email: 'adam@publicshop.io', pass_hash: BCrypt::Password.create('VarEMinLaddare'), birth: '2001.08.10', description: 'Love shopping', admin: 0},
            {username: 'Jesper', email: 'jesper@publicshop.io', pass_hash: BCrypt::Password.create('OurAdmin'), birth: '2001.05.05', description: 'I own this place, try me bro!', admin: 1},
            {username: 'Marcus', email: 'marcus@publicshop.io', pass_hash: BCrypt::Password.create('naturaren'), birth: '2001.10.15', description: 'Why am I here', admin: 0}
        ]

        profile_comments = []

        products = [
            {name: 'images', price: 100, stock: 150, description: 'Exclusively cat photos, promise.', user_id: 3},
            {name: 'mysterious delivery', price: 1500, stock: 10, description: 'Mysterious, just like my profile.', user_id: 3},
            {name: 'potatoes', price: 399, stock: 25, description: 'Round, just like our Earth.', user_id: 4},
            {name: 'rocks', price: 750, stock: 100, description: 'Expensive and hard.', user_id: 4, rating: 1.0, rating_count: 2},
            {name: 'Empty', price: 10, stock: 10, description: 'Cheap and hollow.', user_id: 5},
            {name: 'know your biology!', price: 1000, stock: 10, description: 'Expensive but genius.', user_id: 6},
            {name: 'life advice', price: 10000, stock: 9999, description: 'Expensive but awesome.', user_id: 6},
            {name: 'skumtomtar', price: 500, stock: 3, description: 'Expensive but tasty.', user_id: 6},
        ]

        product_parts = [
            {product_id: 8, groupname: 'animal', partname: 'duck', bonus_price: 100},
            {product_id: 8, groupname: 'animal', partname: 'goose', bonus_price: 125},
            {product_id: 8, groupname: 'animal', partname: 'chicken', bonus_price: 150}
        ]

        product_comments = []
        
        users.each do |i|
            db.execute("INSERT INTO users (username, email, pass_hash, birth, description, admin) VALUES(?,?,?,?,?,?)", i[:username], i[:email], i[:pass_hash], i[:birth], i[:description], i[:admin])
        end
        profile_comments.each do |i|
            db.execute("INSERT INTO profile_comments (user_id, visitor_id, timestamp, rating, comment) VALUES(?,?,?,?,?)", i[:user_id], i[:visitor_id], i[:timestamp], i[:rating], i[:comment])
        end
        products.each do |i|
            db.execute("INSERT INTO products (user_id, name, price, stock, description) VALUES(?,?,?,?,?)", i[:user_id], i[:name], i[:price], i[:stock], i[:description])
        end
        product_parts.each do |i|
            db.execute("INSERT INTO product_parts (product_id, groupname, partname, bonus_price) VALUES(?,?,?,?)", i[:product_id], i[:groupname], i[:partname], i[:bonus_price])
        end
        product_comments.each do |i|
            db.execute("INSERT INTO product_comments (user_id, product_id, timestamp, rating, comment, parent_id) VALUES(?,?,?,?,?,?)", i[:user_id], i[:product_id], i[:timestamp], i[:rating], i[:comment], i[:parent_id])
        end
    end
    
    # Main function to start the whole database process (create/open database > drop tables > create tables > fill tables)
    #
    # Examples
    #  seeder::Seeder.seed!()
    #  # => nil
    #
    # Returns nothing
    def self.seed!()
        db = open_db('database.db')
        drop_tables(db)
        create_tables(db)
        fill_tables(db)
    end
end

Seeder.seed!()
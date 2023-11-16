require 'sqlite3'
require 'sinatra'
require_relative 'models/user'
require_relative 'models/user_comment'
require_relative 'models/product'
require_relative 'models/product_comment'
require_relative 'models/product_part'
require_relative 'models/purchase'

class App < Sinatra::Base

    debug = false # auto login as admin if true

    @db = SQLite3::Database.new('db/database.db')
    @db.results_as_hash = true

    # connect the database to all database subclasses
    User.load(@db, 'users')
    Product.load(@db, 'products')
    Product_comment.load(@db, 'product_comments')
    User_comment.load(@db, 'profile_comments')
    Product_part.load(@db, 'product_parts')
    Purchase.load(@db, 'purchases')

    enable :sessions

    # executed on each HTTP request
    before do
        if !session[:user_id] && debug == true
            session[:user_id] = 5 # user_id 5 = Jesper = admin user
        end
        if session[:user_id]
            @current_user = User.get_by_id(session[:user_id])
        end
    end

    # Get route which displays the index page, shows top 10 users and top 10 products compared to star rating, permission: everyone
    #
    # Examples
    #  get("/")
    #  # => index.slim
    #
    # Returns slim file for the index page
    get '/' do
        @top10users = User.get_top_rated(10)
        @top10products = Product.get_top_rated(10)
        slim :index
    end

    # Get route which show specific product, permission: everyone
    #
    # id - Integer in form of the id of the product
    #
    # Examples
    #  get("/product/3")
    #  # => product.slim
    #
    #  get("/product/aaa")
    #  # => redirect("/")
    #
    # Returns a redirect to / (root) on error and returns the slim file for the product page on success
    get '/product/:id/?' do |id|
        if id.to_i.to_s != id
            redirect '/'
            return
        end
        @product_info = Product.get_by_id(id)
        if @product_info == nil
            redirect '/'
            return
        end
        @title = "product #{@product_info.name}"
        @comments = Product_comment.get_by_product_id(id)
        slim :product
    end

    # Get route which show specific user, permission: everyone
    #
    # username - String in form of the user which is visited
    #
    # Examples
    #  get("/u/Jesper")
    #  # => userpage.slim
    #
    #  get("/u/InvalidUsername")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the username is invalid and loads the slim file for the user page if the user exists
    get '/u/:username/?' do |username|
        @searched_user = User.get_by_username(username)

        if @searched_user == nil
            return redirect '/'
        end

        @products = Product.all(@searched_user.id)
        @comments = User_comment.get_by_user_id(@searched_user.id)

        @title = @searched_user.username
        slim :userpage
    end

    # Get route which to change settings for a specific user, permission: self, admin
    #
    # username - String in form of the user which is managed
    #
    # Examples
    #  get("/u/Jesper/manage")
    #  # => userpage.slim
    #
    #  get("/u/InvalidUsername/manage")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the username is invalid or if the signed in user has no permission, else returns the slim file for the manage page
    get '/u/:username/manage/?' do |username|
        @managed_user = User.get_by_username(username)
        if @managed_user == nil || !@current_user
            redirect '/'
            return
        end
        if @current_user.id != @managed_user.id && @current_user.admin != 1
            redirect '/'
            return
        end
        @managed_products = Product.all(@managed_user.id)
        @title = "managing #{@managed_user.username}"
        slim :adminpage
    end
    
    # Get route which show the shopping cart for user, permission: self, admin
    #
    # username - String in form of the user which is managed
    #
    # Examples
    #  get("/u/Jesper/cart")
    #  # => userpage.slim
    #
    #  get("/u/InvalidUsername/cart")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the username is invalid or if the signed in user has no permission, else returns the slim file for the cart page
    get '/u/:username/cart/?' do |username|
        @managed_user = User.get_by_username(username)
        if @managed_user == nil || !@current_user 
            redirect '/'
            return
        end
        if @current_user.id != @managed_user.id && @current_user.admin != 1
            redirect '/'
            return
        end
        @managed_cart = Purchase.get_all_by_user_id(@managed_user.id)
        @title = 'cart'
        slim :cart
    end

    # Get route which shows the profile picture of user, permission: everyone
    #
    # username - String in form of the user which is managed
    #
    # Examples
    #  get("/u/Jesper/profile/picture/")
    #  # => redirect("/img/profile_pictures/jesper.png")
    #
    #  get("/u/InvalidUsername/profile/picture/")
    #  # => redirect("/img/nouser.png")
    #
    # Returns a redirect to the users profile picture if it exists, else a redirect to a default profile picture
    get '/u/:username/profile_picture/?' do |username|
        filematches = Dir.glob("img/profile_pictures/#{username.downcase()}.*", base: 'public')
        if filematches.length == 0
            redirect(to('/img/nouser.png'))
        else
            redirect(to(filematches[0]))
        end
    end
    
    # Get route which shows the login form, permission: everyone who is not logged in
    #
    # Examples
    #  get("/login")
    #  # => login.slim
    #
    #  get("/login")
    #  # => redirect("/")
    #
    # Returns the slim file for the login form if the user is signed out, else redirects to root
    get '/login/?' do
        if @current_user
            redirect '/'
            return
        end
        if params['status'] == 'invalid_cridentials' 
            @error_message = 'Invalid email or password'
        elsif params['status'] == 'out_of_tries' 
            @error_message = 'Out of login tries, try again later'
        elsif params['status'] == 'user_created' 
            @success_message = 'User was sucessfully created'
        end
        @title = 'login'
        slim :login
    end
    
    # Get route which shows the register form, permission: everyone who is not logged in
    #
    # Examples
    #  get("/register")
    #  # => register.slim
    #
    #  get("/register")
    #  # => redirect("/")
    #
    # Returns the slim file for the register form if the user is signed out, else redirects to root
    get '/register/?' do
        if @current_user
            redirect '/'
            return
        end
        if params['status'] == 'email_registered'
            @error_message = 'e-mail already registered'
        elsif params['status'] == 'email_invalid'
            @error_message = 'e-mail does not follow the rules'
        elsif params['status'] == 'password_no_match'
            @error_message = 'the passwords does not match'
        elsif params['status'] == 'password_invalid'
            @error_message = 'password does not follow the rules'
        elsif params['status'] == 'username_invalid'
            @error_message = 'username does not follow the rules'
        elsif params['status'] == 'invalid_birth_date'
            @error_message = 'please specify a valid birth date'
        elsif params['status'] == 'username_registered'
            @error_message = 'username already exists'
        end
        @title = 'register'
        slim :register
    end

    # Get route which shows the users and products who matches the search query, permission: everyone
    #
    # Examples
    #  get("/search")
    #  # => search.slim
    #
    # Returns the slim file for the search page
    get '/search/?' do
        search_term = params['q']
        if search_term == nil
            redirect '/'
            return
        end
        @query_user = User.get_by_username(search_term)
        @query_products = Product.search_by_name(search_term)
        @title = 'Search: ' + search_term
        slim :search
    end

    # Get route which signs out the current user, permission: everyone
    #
    # Examples
    #  get("/logout")
    #  # => redirect("/")
    #
    # Returns a redirect to root
    get '/logout/?' do
        session.clear()
        redirect '/'
    end

    # Post route which logs in the user, permission: everyone
    #
    # Examples
    #  post("/login")
    #  # => redirect("/login")
    #  
    #  post("/login")
    #  # => redirect("/")
    #
    # Returns redirect to root on success and to /login on error
    post '/login' do
        email = params['email']
        password = params['password']
        if email == nil || password == nil || email.length == 0 || password.length == 0
            redirect '/login'
            return
        end
        tries = session[:tries]
        tries_time_limit = session[:tries_time_limit]
        current_time = Time.now()
        if tries_time_limit != nil
            tries_time_limit = tries_time_limit.split(':')
            tries_time_limit = Time.new(tries_time_limit[0], tries_time_limit[1], tries_time_limit[2], tries_time_limit[3], tries_time_limit[4], tries_time_limit[5])
        end
        if tries != nil && tries_time_limit != nil
            if tries_time_limit > current_time && tries > 4
                redirect '/login?status=out_of_tries'
                return
            end
        end
        user = User.login(email, password)
        
        if user == nil
            if tries_time_limit != nil && tries != nil && tries_time_limit > current_time
                session[:tries] += 1
            else
                session[:tries_time_limit] = (current_time + 300).strftime('%Y:%m:%d:%H:%M:%S')
                session[:tries] = 1
            end
            redirect '/login?status=invalid_cridentials'
            return
        end

        session[:user_id] = user.id

        redirect '/'
        return
    end

    # Post route which adds an item to the shopping cart, permission: logged in users
    #
    # username - String of the user who teoretically owns the cart (has no real value)
    #
    # Examples
    #  post("/u/:username/cart/add")
    #  # => redirect("/product/:id")
    #
    #  post("/u/:username/cart/add")
    #  # => redirect("/")
    #
    # Redirects to root on error and to the bought product page on success
    post '/u/:username/cart/add' do
        if params['productId'] == nil || params['productId'].to_i.to_s != params['productId']
            redirect "/"
        end
        if !@current_user
            redirect "/product/#{params['productId']}"
            return
        end
        partgroups = {}
        params.each do |item|
            if item[0].start_with?('part_') && item[1] != ''
                partgroups[item[0].split('_', 2)[1]] = item[1]
            end
        end
        bought_product = Product.get_by_id(params['productId'])
        if bought_product == nil
            redirect "/product/#{params['productId']}"
            return
        end
        if bought_product.stock > 0
            bought_product.stock = bought_product.stock - 1
            bought_product.save()
            Purchase.create(@current_user.id, bought_product, partgroups)
            redirect "/product/#{params['productId']}?status=purchase_added"
        else
            redirect "/product/#{params['productId']}?status=out_of_stock"
        end
    end

    post '/u/:username/cart/delete' do |username|
        if params['purchaseId'] == nil || !@current_user || params['purchaseId'].to_i.to_s != params['purchaseId']
            redirect '/'
            return
        end
        managed_purchase = Purchase.get_by_id(params['purchaseId'])
        
        if @current_user.id != managed_purchase.user_id && @current_user.admin == 0
            redirect '/'
            return
        end
        managed_purchase.delete()
        redirect "/u/#{username}/cart"
    end

    # Post route which adds comment to user, permission: logged in users (not self)
    #
    # username - String in form of the user to make a comment on
    #
    # Examples
    #  post("/u/ExistingUser/setcomment")
    #  # => redirect("/u/ExistingUser")
    #
    #  post("/u/NonExistingUser/setcomment")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the user does not exist, else redirects to the user page
    post '/u/:username/setcomment' do |username|
        if !@current_user || params['rating'] != params['rating'].to_i().to_s() || (params['comment'] == nil || params['comment'].length == 0)
            redirect "/u/#{username}"
            return
        end

        user_target = User.get_by_username(username)
        if user_target == nil
            redirect "/"
            return
        end
        
        if user_target.id == @current_user.id
            redirect "/u/#{username}"
            return
        end
        
        User_comment.create(user_target.id, @current_user.id, params['comment'], params['rating'].to_i())
        redirect "/u/#{username}"
    end

    # Post route which adds comment to product, permission: logged in users (not self)
    #
    # product_id - String in form of the user to make a comment on
    #
    # Examples
    #  post("/product/1/setcomment")
    #  # => redirect("/product/1")
    #
    #  post("/product/InvalidProduct/setcomment")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the product does not exist, else redirects to the product page
    post '/product/:product_id/setcomment' do |product_id|
        if !@current_user || params['rating'] != params['rating'].to_i().to_s() || (params['comment'] == nil || params['comment'].length == 0)
            redirect "/product/#{product_id}"
            return
        end
        
        product_data = Product.get_by_id(product_id)
        if product_data == nil
            redirect "/"
            return
        end
        
        if product_data.user_id == @current_user.id
            redirect "/product/#{product_id}"
            return
        end
        
        Product_comment.create(@current_user.id, product_id, params['comment'], params['rating'].to_i())
        redirect "/product/#{product_id}"
    end

    # toggles an users admin access, permission: admin
    #
    # username - String in form of the username to toggle admin access on
    #
    # Examples
    #  post("/u/Rasmus/manage/toggle_admin")
    #  # => redirect("/")
    #  
    #  post("/u/Rasmus/manage/toggle_admin")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user has no access to manage user or if the user does not exist, else a redirect to the users manage page
    post '/u/:username/manage/toggle_admin' do |username|
        if params['confirm'] == nil || params['confirm'].downcase != username.downcase || @current_user.admin == 0
            redirect '/'
            return
        end
        managed_user = User.get_by_username(username)
        if managed_user == nil
            redirect '/'
            return    
        end
        if managed_user.admin == 1
            managed_user.admin = 0
        else
            managed_user.admin = 1
        end
        managed_user.save()
        redirect "/u/#{username}/manage"
    end

    # deletes an user, permission: admin
    #
    # username - String in form of the username which should be deleted
    #
    # Examples
    #  post("/u/Rasmus/manage/delete_user")
    #  # => redirect("/")
    #  
    # Returns a redirect to root
    post '/u/:username/manage/delete_user' do |username|
        if !@current_user
            redirect '/'
            return
        end
        if params['confirm'] == nil || params['confirm'].downcase != username.downcase
            redirect '/'
            return
        end
        managed_user = User.get_by_username(username)
        if @current_user.id == managed_user.id
            managed_user.delete()
            session.clear()
        elsif @current_user.admin == 1
            managed_user.delete()
        end
        redirect '/'
    end
    
    # edit product details, permission: self, admin
    #
    # product_id - Integer in form of the product to be edited 
    # 
    # Examples
    #  post("/product/1/edit")
    #  # => redirect("/u/#{managed_product.username}/manage")
    #
    #  post("/product/InvalidProduct/edit")
    #  # => redirect("/")
    #
    # Returns a redirect to root if the user has no access to manage the product or if the product does not exist, else redirects to the owners manage page
    post '/product/:product_id/edit' do |product_id|
        if !@current_user
            redirect "/"
            return
        end
        managed_product = Product.get_by_id(product_id)
        if managed_product == nil
            redirect "/"
            return
        end
        if managed_product.user_id != @current_user.id && @current_user.admin == 0
            redirect "/u/#{managed_product.username}/manage"
            return
        end
        if params['name'] == nil || params['price'] == nil || params['stock'] == nil || params['description'] == nil
            redirect "/u/#{managed_product.username}/manage"
        end
        if managed_product.user_id != @current_user.id && @current_user.admin != 1
            redirect "/u/#{managed_product.username}/manage"
            return
        end
        managed_product.name = params['name']
        managed_product.price = params['price']
        managed_product.stock = params['stock']
        managed_product.description = params['description']
        managed_product.save()

        redirect "/u/#{managed_product.username}/manage"
    end

    # edit product part, permission: self, admin
    #
    # username - String of the user which is managed
    #
    # Examples
    #  post("/u/Rasmus/manage/part/update")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/part/update")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no access to the part, else redirects to the manage page
    post '/u/:username/manage/part/update' do |username|
        if !@current_user
            redirect "/"
            return
        end
        if params['partname'] == nil || params['bonusprice'] == nil || params['part_id'] == nil
            redirect "/u/#{username}/manage"
            return
        end
        managed_part = Product_part.get_by_id(params['part_id'])
        if managed_part == nil
            redirect '/'
            return
        end
        managed_product = Product.get_by_id(managed_part.product_id)
        if @current_user.id != managed_product.user_id && @current_user.admin != 1
            redirect '/'
            return
        end
        if params['bonusprice'] == params['bonusprice'].to_i().to_s() && params['bonusprice'].to_i() >= 0
            managed_part.partname = params['partname']
            managed_part.bonus_price = params['bonusprice'].to_i()
            managed_part.save()
        end
        redirect "/u/#{username}/manage"
        return
    end
    
    # delete group of parts on specific product, permission: self, admin
    #
    # username - String of the user which is managed
    #
    # Examples
    #  post('/u/Rasmus/manage/group/delete')
    #  # => redirect("/")
    #
    #  post('/u/Rasmus/manage/group/delete')
    #  # => redirect("/u/Rasmus/manage")
    #
    # Redirects to root if the user is not signed in or if the user has no access to the asked product which owns group, else redirects to the manage page of the user
    post '/u/:username/manage/group/delete' do |username|
        if params['product_id'] == nil || params['group_name'] == nil || !@current_user
            redirect '/'
        end
        managed_product = Product.get_by_id(params['product_id'])
        if @current_user.id != managed_product.user_id && @current_user.admin != 1
            redirect '/'
            return
        end
        managed_parts = Product_part.get_by_product_id(params['product_id'])
        if managed_parts[params['group_name']] == nil
            redirect "/u/#{username}/manage"
            return
        end
        managed_parts[params['group_name']][0].delete_group()
        redirect "/u/#{username}/manage"
    end
    
    # create new group on product, permission: self, admin
    #
    # username - String of the managed user
    #
    # Examples
    #  post('/u/Rasmus/manage/group/new')
    #  # => redirect("/")
    #
    #  post('/u/Rasmus/manage/group/new')
    #  # => redirect("/u/Rasmus/manage")
    #
    # Redirects to root if the user is not signed in or if the user has no access to the asked product, else redirects to the manage page of the user
    post '/u/:username/manage/group/new/?' do |username|
        if params['product_id'] == nil || params['groupname'] == nil || params['partname'] == nil || params['bonusprice'] == nil || !@current_user
            redirect '/'
            return
        end
        managed_user = User.get_by_username(username)
        if @current_user.id != managed_user.id && @current_user.admin != 1
            redirect '/'
            return
        end
        if params['bonusprice'] == params['bonusprice'].to_i().to_s() && params['bonusprice'].to_i() >= 0
            Product_part.create(params['product_id'], params['groupname'], params['partname'], params['bonusprice'])
        end
        redirect "/u/#{username}/manage"
    end
    
    # delete a product, permission: self, admin
    #
    # username - String of the managed user
    #
    # Examples
    #  post('/product/1/delete')
    #  # => redirect("/")
    #
    #  post('/product/1/delete')
    #  # => redirect("/u/Rasmus/manage")
    #
    # Redirects to root if the user is not signed in or if the user has no access to the asked product, else redirects to the manage page of the user
    post '/product/:product_id/delete' do |product_id|
        if !@current_user || product_id.to_i.to_s != product_id
            redirect '/'
            return
        end
        managed_product = Product.get_by_id(product_id)
        if @current_user.id != managed_product.user_id && @current_user.admin != 1
            redirect '/'
            return
        end
        managed_product.delete()
        redirect "/u/#{managed_product.username}/manage"
        return
    end

    # create a new product, permission: self, admin
    #
    # username - String of the managed user
    #
    # Examples
    #  post("/u/Rasmus/manage/product/new")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/product/new")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no admin access for the user, else redirects to the users manage page
    post '/u/:username/manage/product/new/?' do |username|
        if !@current_user
            redirect '/'
            return
        end
        managed_user = User.get_by_username(username)
        productname = params['name']
        price = params['price']
        stock = params['stock']
        description = params['description']

        if @current_user.id != managed_user.id && @current_user.admin != 1
            redirect '/'
            return
        end
        Product.create(managed_user.id, productname, price, stock, description)

        redirect "/u/#{managed_user.username}/manage"
    end

    # edit (add/delete) product preivew pictures, permission: self, admin
    #
    # Username - String of the managed user
    #
    # Examples
    #  post("/u/Rasmus/manage/product_pictures")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/product_pictures")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no admin access for the user or if the product does not exist, else redirect to the manage page
    post '/u/:username/manage/product_pictures/?' do |username|
        if !params['action'] || !params['imageId'] || !params['productId'] || params['productId'] != params['productId'].to_i.to_s || !@current_user
            redirect "/"
            return
        end

        product = Product.get_by_id(params['productId'])

        if product == nil
            redirect '/'
            return
        end
        
        if @current_user.id != product.user_id && @current_user.admin != 1
            redirect '/'
            return
        end
        
        if params['action'] == 'delete'
            filepath = "public/img/product_pictures/#{params['productId']}/#{params['imageId']}"
            if File.file?(filepath)
                File.delete(filepath)
                redirect "/u/#{username}/manage?status=image_delete_complete"
                return
            else
                redirect "/u/#{username}/manage?status=image_not_found"
                return
            end
        elsif params['action'] == 'upload'
            if !params['base64Image']
                redirect "/u/#{username}/manage?status=no_image_found"
                return
            end
            # group 1 = file type
            # group 2 = file data
            filedata = /data:image\/([^;]+);base64,(.+)/.match(params['base64Image'])
            if filedata == nil
                redirect "/u/#{username}/manage?status=invalid_image"
                return
            end
            filetype = filedata[1]
            byte_file = Base64.decode64(filedata[2])
            filename = "public/img/product_pictures/#{params['productId']}/#{Time.now().strftime('%Y%m%d_%H%M%S')}"
            if !File.directory?("public/img/product_pictures/#{params['productId']}")
                Dir.mkdir("public/img/product_pictures/#{params['productId']}")
            end
            unique_separator = 0
            if File.file?(filename + '.' + filetype)
                while File.file?(filename + '_' + unique_separator.to_s() + '.' + filetype) == true
                    unique_separator += 1
                end
                filename = filename + '_' + unique_separator.to_s() + '.' + filetype
            else
                filename = filename + '.' + filetype
            end
            file_object = File.open(filename, 'wb')
            file_object.write(byte_file)
            file_object.close()
            
            redirect "/u/#{username}/manage?status=image_uploaded"
            return
        else
            redirect "/u/#{username}/manage?status=invalid_action"
            return
        end
    end

    # upload new profile picture, permission: self, admin
    #
    # Username - String of the managed user
    #
    # Examples
    #  post("/u/Rasmus/manage/product_pictures")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/product_pictures")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no admin access for the user or if the user does not exist, else redirect to the manage page
    post '/u/:username/manage/profile_picture/?' do |username|
        user = User.get_by_username(username)
        if (user == nil || !@current_user)
            redirect '/'
            return
        end
        if @current_user.id != user.id && @current_user.admin != 1
            redirect '/'
            return
        end
        if !params['image']
            redirect "/u/#{username}/manage"
            return
        end
        
        # group 1 = file type
        # group 2 = file data
        filedata = /data:image\/([^;]+);base64,(.+)/.match(params['image'])
        if filedata == nil
            redirect "/u/#{username}/manage"
            return
        end
        filetype = filedata[1]
        byte_file = Base64.decode64(filedata[2])
        filematches = Dir.glob("public/img/profile_pictures/#{username.downcase()}.*")
        filematches.each do |filename|
            File.delete(filename)
        end
        file_object = File.open("public/img/profile_pictures/#{username.downcase()}.#{filetype}", 'wb') 
        file_object.write(byte_file)
        file_object.close()
        redirect "/u/#{username}/manage"
    end

    # delete a product part, permission: self, admin
    #
    # Username - String of the managed user
    #
    # Examples
    #  post("/u/Rasmus/manage/part/delete")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/part/delete")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no admin access for the user or if the product does not exist, else redirect to the manage page
    post '/u/:username/manage/part/delete/?' do |username|
        part_id = params['part_id']
        if part_id == nil
            redirect '/'
            return
        end
        part_info = Product_part.get_by_id(part_id)
        if part_info == nil || !@current_user
            redirect '/#b'
            return
        end
        if @current_user.id != part_info.user_id && @current_user.admin != 1
            redirect '/#c'
            return
        end
        part_info.delete()
        redirect "/u/#{username}/manage"
    end

    # add new product part, permission: self, admin
    #
    # Username - String of the managed user
    #
    # Examples
    #  post("/u/Rasmus/manage/part/new")
    #  # => redirect("/")
    #
    #  post("/u/Rasmus/manage/part/new")
    #  # => redirect("/u/Rasmus/manage")
    #
    # Returns a redirect to root if the user is not signed in or if the user has no admin access for the user or if the product does not exist, else redirect to the manage page
    post '/u/:username/manage/part/new/?' do |username|
        if params['product_id'] == nil || params['groupname'] == nil || params['partname'] == nil || params['bonusprice'] == nil
            redirect '/'
            return
        end
        product_info = Product.get_by_id(params['product_id'])
        if (product_info == nil || !@current_user)
            redirect '/'
            return
        end
        if @current_user.id != product_info.user_id && @current_user.admin != 1
            redirect '/'
            return
        end
        if params['bonusprice'] == params['bonusprice'].to_i().to_s() && params['bonusprice'].to_i() >= 0
            Product_part.create(params['product_id'], params['groupname'], params['partname'], params['bonusprice'])
        end
        redirect "/u/#{username}/manage"
    end
    
    # Post route to register an user, permission: everyone
    #
    # Username - String of the managed user
    #
    # Examples
    #  post("/register")
    #  # => redirect("/login")
    #
    #  post("/register")
    #  # => redirect("/register")
    #
    # Returns a redirect to /register on error, else to /login
    post '/register' do
        email = params['email']
        username = params['username']
        password = params['password']
        password_copy = params['passwordCopy']
        birth_date = params['birthDate']

        if password != password_copy
            redirect '/register?status=password_no_match'
            return
        end
        
        register_response = User.register(username, email, password, birth_date)
        if register_response[:status] == true
            redirect '/login?status=user_created'
        else
            redirect "/register?status=#{register_response[:error]}"
        end
        return
    end
end
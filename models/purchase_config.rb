class Purchase_config
    
    attr_reader :id, :groupname, :partname, :bonus_price
    
    # Public: Create a new Purchase_config instance
    #
    # id          - Integer, the parts id
    # groupname   - String, the group which the part is a part of
    # partname    - String, the name of the part
    # bonus_price - Integer, the price of the part
    #
    # Examples
    #  product::Product.new(SQLite3::Database, 1, 1, 1, "groupname", "partname", 1)
    #  # => product::Product
    #
    # Returns a new instance of the class Purchase_config
    def initialize(id, groupname, partname, bonus_price)
        @id = id
        @groupname = groupname
        @partname = partname
        @bonus_price = bonus_price
    end
end
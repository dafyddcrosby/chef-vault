class ChefVault
  class User
    attr_accessor :username

    def initialize(data_bag, username, chef_config_file)
      @username = username
      @data_bag = data_bag

      if chef_config_file
        chef = ChefVault::ChefOffline.new(chef_config_file)
        chef.connect
      end
    end

    def decrypt_password
      # use the private client_key file to create a decryptor
      private_key = open(Chef::Config[:client_key]).read
      private_key = OpenSSL::PKey::RSA.new(private_key)
      
      begin
        keys = Chef::DataBagItem.load(@data_bag, "#{username}_keys")
      rescue
        throw "Could not find data bag item #{username}_keys in data bag #{@data_bag}"
      end

      unless keys[Chef::Config[:node_name]]
        throw "Password for #{username} is not encrypted for you!  Rebuild the password data bag"
      end

      node_key = Base64.decode64(keys[Chef::Config[:node_name]])
      shared_secret = private_key.private_decrypt(node_key)
      cred = Chef::EncryptedDataBagItem.load(@data_bag, @username, shared_secret)

      cred["password"]
    end
  end
end
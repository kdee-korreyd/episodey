module Episodey
	class User < Episodey::Base
		# @!attribute email
		#   @return [String] this users email address
		attr_accessor :email	

		# constructor
		# @param name [name] users full name
		# @param email [email] users email address
		# @return [User] new User object
		def initialize(name,email)
			@name = name
			@email = email
		end

		# save this user to the database
		# @return [User] if successfully added to database.  raises Exception on failure.
		# @return [false] if user has not been initialized.  (email is required)
		def save
			r = Episodey::DB::User.create(
				:name => self.name,
				:email => self.email
			)
			@id = r.id
			return self
		end
	end
end

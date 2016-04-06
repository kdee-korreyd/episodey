module Episodey
	#references a media posting on a website.
	class Posting < Episodey::Base
		# @!attribute url
		#   @return [String] the url of this posting
		attr_accessor :url

		# @!attribute media
		#   @return [Media] reference to the {Media} that this Posting refers to.
		attr_accessor :media

		# constructor
		# @param url [String] the url of this posting
		# @return [Posting] self.
		def initialize(url)
			@url = url;
		end

		# save this Posting object to the database
		# @return [Boolean] true on success.  false if Posting object has not been initialized.  raises Exception on failure.
		def save
		end
	end
end

module Episodey
	#base Media object
	class Media < Episodey::Base
		# @!attribute media_set
		#   @return [MediaSet] reference to the MediaSet that this Media belongs to.
		attr_accessor :media_set

		# @!attribute posting
		#   @return [Posting] reference to the Posting that refers to this Media.
		attr_accessor :posting

		# constructor
		# @return [Episodey::Media] new Media
		def initialize
		end

		# set the posting reference, and update postings media reference
		# @param posting [Episodey::Posting] the Posting object to use to create this Media.
		# @return [Episodey::Media] self.  raises Exception on failure.
		def set_posting(posting)
			@posting = posting
			@posting.media = self
		end

		# prints media information.
		# @return [nil]
		def info
		end

		# create a Notification object from this Media
		# @return [Episody::Notification] Notification object.  raises Exception on failure. 
		# @return [false] if the Media object has not been initialized.  
		def notify
		end

		# save this Media object to the database
		# @return [Boolean] true on success.  false if Media object has not been initialized.  raises Exception on failure.
		def save
		end
	end

	class Episode < Episodey::Media
	end

	class Video < Episodey::Episode
	end

	class Audio < Episodey::Episode
	end

	class TV < Episodey::Video
	end

	class Movie < Episodey::Video
	end
end

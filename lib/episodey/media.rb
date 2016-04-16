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

		# converts all records in the db_media_list list from active record objects to Episodey::Media objects
		# @param db_media_list [Array<Episodey::DB::Media>] the {Media} list to convert
		# @return [Array<Episodey::Media>] converted list
		def self.db_to_object(db_media_list)
			db_media_list.map do |m|
				media = YAML.load(m.object_yaml)
				media.id = m.id

				posting = Episodey::DB::Posting.where(media_id: media.id).first
				if !posting.nil?
					media.set_posting(Episodey::Posting.db_to_object([posting])[0])
				end

				media
			end
		end

		# inverse of {db_to_object}
		# @param  [Array<Episodey::Media>] the Media list to convert
		# @return [Array<Episodey::DB::Media>] converted list
		def self.object_to_db(media_list)
			media_list.map do |m|
				r = nil
				if m.id.nil? 
					r = Episodey::DB::Media.new
				else
					r = Episodey::DB::Media.find(m.id)
				end
				r.u_id = m.u_id
				r.name = m.name
				r.media_set_id = !m.media_set.nil? ? m.media_set.id : nil
				r.posting_id = !m.posting.nil? ? m.posting.id : nil
				r.media_type = m.class.name[/::([^:]+)$/,1]

				#dont store media_set or posting with yaml
				tmp_media_set = m.media_set
				tmp_posting = m.posting
				m.media_set = nil
				m.posting = nil
				#store yaml
				r.object_yaml = m.to_yaml
				#put objects back
				m.media_set = tmp_media_set
				m.posting = tmp_posting
				r
			end
		end

		# prints media information.
		# @return [nil]
		def info
		end

		# create a Notification object from this Media
		# @return [Episody::Notification] Notification object.  raises Exception on failure. 
		# @return [false] if the Media object has not been initialized.  
		def notify
			return false if !self.is_initialized

			notification = Episodey::Notification.new
			if !@media_set.nil? 
				notification.subject = "A new #{@media_set.name} episode is available"
			else
				notification.subject = "A new #{@name} episode is available"
			end

			notification.message = "I found a new episode for you!<br/>"
			notification.message << "Episode: #{@name}"
			if !@posting.nil?
				notification.message << "The link I found it at: #{@posting.url}"
			end

			notification.user_id = Episodey::Session.user.id
			notification.media_id = @id
			return notification
		end

		# save this Media object to the database
		# @return [Boolean] true on success.  false if Media object has not been initialized.  raises Exception on failure.
		def save
			if !self.is_initialized
				return false
			end

			r = Episodey::Media.object_to_db([self])[0]
			r.save

			@id = @id.nil? ? r.id : @id

			#save posting
			@posting.save if !@posting.nil?
			
			return !@id.nil?
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

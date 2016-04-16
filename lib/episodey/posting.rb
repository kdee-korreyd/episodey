module Episodey
	#references a media posting on a website.
	class Posting < Episodey::Base
		# @!attribute html
		#   @return [String] the html included in this posting
		attr_accessor :html

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

		# checks to see if this object is initialized. 
		# @return [Boolean] true if initialized, false if not initialized
		def is_initialized
			if self.url.to_s.empty?
				return false
			end	
			return true
		end

		# converts all records in the db_posting_list list from active record objects to Episodey::Posting objects
		# @param db_posting_list [Array<Episodey::DB::Posting>] the {Posting} list to convert
		# @return [Array<Episodey::Posting>] converted list
		def self.db_to_object(db_posting_list)
			db_posting_list.map do |p|
				posting = self.new p.link
				posting.html = p.html
				posting.id = p.id
				posting
			end
		end

		# inverse of {db_to_object}
		# @param  [Array<Episodey::Posting>] the Posting list to convert
		# @return [Array<Episodey::DB::Posting>] converted list
		def self.object_to_db(posting_list)
			posting_list.map do |p|
				r = nil
				if p.id.nil? 
					r = Episodey::DB::Posting.new
				else
					r = Episodey::DB::Posting.find(p.id)
				end
				r.link = p.u_id
				r.html = p.html
				r.media_id = !p.media.nil? ? p.media.id : nil
				r
			end
		end

		# save this Posting object to the database
		# @return [Boolean] true on success.  false if Posting object has not been initialized.  raises Exception on failure.
		def save
			if !self.is_initialized
				return false
			end

			r = Episodey::Posting.object_to_db([self])[0]
			r.save

			@id = @id.nil? ? r.id : @id
			return !@id.nil?
		end
	end
end

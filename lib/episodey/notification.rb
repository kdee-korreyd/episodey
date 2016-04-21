module Episodey
	#notification object
	class Notification < Episodey::Base
		# @!attribute user
		#   @return [Integer] the id of the user this notification is for
		attr_accessor :user_id

		# @!attribute subject
		#   @return [String] notification subject
		attr_accessor :subject

		# @!attribute message
		#   @return [String] notification message/body
		attr_accessor :message

		# @!attribute is_sent
		#   @return [Boolean] true if this notification has been sent before
		attr_accessor :is_sent

		# @!attribute ntype
		#   @return [String] the type of media being notified about [eg. Media, Info, Warning, etc...]
		attr_accessor :ntype

		# @!attribute ntype_id
		#   @return [Integer] id of the media(if any) this notification is for
		attr_accessor :ntype_id

		# @!attribute media
		#   @return [Episodey::Media] the media object this notification is associated with
		attr_accessor :media

		# constructor
		# @return [Episodey::Notification] new Notification
		def initialize
		end

		# checks to see if this object is initialized. 
		# @return [Boolean] true if initialized, false if not initialized
		def is_initialized
			if self.subject.to_s.empty? || self.message.to_s.empty?
				return false
			end	
			return true
		end

		# set and return the media id for this Notfication (if @media exists). or else just return {#ntype_id}
		# @return [Integer] the media id
		def media_id
			@ntype_id = @media.id if (!@media.nil? && !@media.id.nil? && @ntype_id.nil?)
			return @ntype_id
		end

		# converts all records in the db_notification_list list from active record objects to Episodey::Notification objects
		# @param db_notification_list [Array<Episodey::DB::Notification>] the {Notification} list to convert
		# @return [Array<Episodey::Notification>] converted list
		def self.db_to_object(db_notification_list)
			db_notification_list.map do |n|
				notification = self.new
				notification.subject = n.subject
				notification.message = n.message
				notification.is_sent = n.is_sent
				notification.user_id = n.user_id
				notification.ntype = n.ntype
				notification.ntype_id = n.ntype_id
				notification.id = n.id
				notification
			end
		end

		# inverse of {db_to_object}
		# @param notification_list [Array<Episodey::Notification>] the Notification list to convert
		# @return [Array<Episodey::DB::Notification>] converted list
		def self.object_to_db(notification_list)
			notification_list.map do |n|
				r = nil
				if n.id.nil? 
					r = Episodey::DB::Notification.new
				else
					r = Episodey::DB::Notification.find(n.id)
				end
				r.user_id = n.user_id
				r.ntype = n.ntype
				r.ntype_id = n.media_id
				r.subject = n.subject
				r.message = n.message
				r.is_sent = n.is_sent
				r
			end
		end

		# create and return smtp config for use with Mail library
		#   falls back to Episodey::Test.smtp_config if it exists
		# @return [Hash] smtp config hash
		def self.smtp
			smtp = {}
			if ( defined?(Episodey::Test) )
				smtp = Episodey::Test.smtp_config
			else
				smtp = Episodey::Session.config[:smtp]
			end
			smtp
		end

		# send an email notification, uses {smtp} method for config
		# @param to [String] the to address for this email
		# @param subject [String] the subject line for the email
		# @param body [String] the body of the email
		# @return raises Exception on failure.
		def send_email(to, subject, body)
			smtp = self.class.smtp
			if smtp.nil?
				raise Exception, "no smtp configuration given."
			end
			Mail.defaults { delivery_method :smtp, smtp }
			mail = Mail.new do
				from smtp[:user_name]
				to to
				subject subject
				html_part do
					content_type 'text/html; charset=UTF-8'
					body body
				end
			end
			mail.deliver!
		end

		# send this notification to {#user}
		# @return [Boolean] true if sent successfully. false if not initialized or already sent.  raises Exception on failure.
		def send
			if (@is_sent && !@is_sent.zero?) || !self.is_initialized
				return false
			end

			#must be a user id to send a notification
			if !@user_id
				raise Exception, "empty user id"
			end
			#grab the user (must exist)
			user = Episodey::DB::User.find(@user_id)
			if !user
				raise Exception, "user not found"
			end

			#get media if there is any (currently not used, do I need this?)
			media = nil
			if @ntype == 'Media' && !@ntype_id.nil?
				media = Episdoey::DB::Media.find(@ntype_id)
			end

			#get email (fall to debug email if it exists)
			email = user.email
			if ( defined?(Episodey::Test) && Episodey::Test.debug_email )
				email = Episodey::Test.debug_email
			end

			if Episodey::Session.email_on
				#send email notification
				self.send_email email, @subject, @message

				#if no exceptions mark as sent
				@is_sent = 1
				return true
			else
				return true
			end
		end

		# group notifications in notification_list by {#user} and send batched notifications to each user.
		# 1 notification per user
		# @param notification_list [Array<Notification>] list of notifications to group send.
		# @return [Integer] number of notifications sent. raises Exception on failure.
		def self.send_grouped(notification_list)
			num_sent = 0

			#group lists by user
			groups = {}
			notification_list.each do |n|
				if !n.user_id.to_s.empty? && !n.user_id.zero?
					if groups[n.user_id].nil?
						groups[n.user_id] = []
					end
					groups[n.user_id] << n
				end
			end

			groups.each do |user| 
				user_id = user.first
				notifications = user.last
				n_sent = []
				subject = "Episodey: [#{user.length}] notifications."
				message = ""
				notifications.each do |n|
					if !n.is_sent || n.is_sent.zero?
						#build the notification
						message << <<-EOF
						<div style='padding:10px;margin-bottom:20px'>
							<h2>#{n.subject}</h2>	
							<p>#{n.message}</p>
						</div>
						EOF
						n.is_sent = 1
						n_sent << n
					end
				end

				#send the notification
				notification = Episodey::Notification.new
				notification.subject = subject
				notification.message = message
				notification.user_id = user_id
				rollback = false
				begin
					if notification.send
						num_sent += 1
					else
						rollback = true
					end
				rescue
					rollback = true
				ensure
					if rollback
						n_sent.each {|n| n.is_sent = 0}
					end
				end
			end

			return num_sent
		end

		# prints notification information.
		# @return [String]
		def info
			nl = Episodey.nl
			tab = Episodey.tab
			header = "[#{self.id}]"
			body = ""

			user = !@user_id.nil? ? Episodey::DB::User.find(@user_id) : nil
			if !user.nil?
				header += ", #{user.email}"
			end

			type_id = self.media_id #get the type_id 
			media = (@ntype == 'Media' && !type_id.nil?) ? Episodey::DB::Media.find(type_id) : nil
			if !media.nil?
				header += ", #{media.u_id}"
			end

			msg_length_limit = 50
			msg = !@message.nil? && @message.length > msg_length_limit ? @message[0..50] + "..." : @message
			body += "#{tab}Subject: #{@subject.to_s}#{nl}#{tab}Body: #{msg.to_s}"

			print header.colorize(:light_green) + nl
			print body.colorize(:light_cyan)
			puts nl
		end

		# save this Notification object to the database
		# @return [Boolean] true on success.  false if Notification object has not been initialized.  raises Exception on failure.
		def save
			if !self.is_initialized
				return false
			end

			r = Episodey::Notification.object_to_db([self])[0]
			r.save

			@id = @id.nil? ? r.id : @id
			return !@id.nil?
		end
	end
end

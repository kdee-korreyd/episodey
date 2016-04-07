module Episodey
	#notification object
	class Notification < Episodey::Base
		# @!attribute user
		#   @return [Episodey::User] the user this notification is for
		attr_accessor :user

		# @!attribute subject
		#   @return [String] notification subject
		attr_accessor :subject

		# @!attribute message
		#   @return [String] notification message/body
		attr_accessor :message

		# @!attribute is_sent
		#   @return [Boolean] true if this notification has been sent before
		attr_accessor :is_sent

		# @!attribute media
		#   @return [Episodey::Media] reference to the media(if any) this notification is for
		attr_accessor :media

		# constructor
		# @return [Episodey::Notification] new Notification
		def initialize
		end

		# send this notification to {#user}
		# @return [true] if sent successfully. raises Exception on failure.
		def send
			smtp = { 
				:address => 'smtp.gmail.com', 
				:port => 587, 
				:domain => 'gmail.com', 
				:user_name => 'username',
				:password => 'password', 
				:enable_starttls_auto => true, 
				:openssl_verify_mode => 'none' 
			}
			Mail.defaults { delivery_method :smtp, smtp }
			mail = Mail.new do
				from 'kdeebug.info@gmail.com'
				to @user.email
				subject 'Scanlan Shorthalt'
				body 'Grog StrongJaw'
			end
			mail.deliver!
		end

		# group notifications in notification_list by {#user} and send batched notifications to each user.
		# 1 notification per user
		# @param notification_list [Array<Notification>] list of notifications to group send.
		# @return [Integer] number of notifications sent. raises Exception on failure.
		def self.send_grouped(notification_list)
			#group lists by user
			groups = {}
			notification_list.each do |n|
				if !n.user.nil?
					if groups[n.user.object_id].nil?
						groups[n.user.object_id] = []
					end
					groups[n.user.object_id] << n
				end
			end

			groups.each do |user| 
				user.each do |n|
					#build the notification
				end

				#send the notification
			end
		end

		# save this Notification object to the database
		# @return [Boolean] true on success.  false if Notification object has not been initialized.  raises Exception on failure.
		def save
		end
	end
end

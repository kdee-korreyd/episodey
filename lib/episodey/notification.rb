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

		# send this notification to {#user}
		# @return [true] if sent successfully. raises Exception on failure.
		def send
		end

		# group notifications in notification_list by {#user} and send batched notifications to each user.
		# 1 notification per user
		# @param notification_list [Array<Notification>] list of notifications to group send.
		# @return [Integer] number of notifications sent. raises Exception on failure.
		def self.send_grouped(notification_list)
		end
	end
end

#require '../lib/episodey'
require 'episodey'
require 'pry'

Episodey::Session.load_config '../episodey.yml'
Episodey::Session.config[:database][:database] = './episodey.db'
puts "done configing"
Episodey::DB.sqlite_update_schema
Episodey::DB.active_record_connect
if !Episodey::Session.set_user_by_id(1)
	Episodey::DB::User.create(
		:name => "Debug User",
		:email => "korreyd@abstractspacecraft.com"
	)
	if !Episodey::Session.set_user_by_id(1)
		raise Exception, "I couldn't set the user"
	end
end
Episodey::Session.email_on = true

epi = Episodey.Episodey
epi.load './config'

puts <<-EOF
===============================
epi.scan
puts @new_media
puts @new_notifications
===============================
EOF

binding.pry

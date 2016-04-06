module Episodey
	#database module
	module DB
		# @!attribute db_adapter
		#   @!scope class
		#   @return [String] database adapter.  options [sqlite3] 
		@@db_adapter = 'sqlite3'

		# @!attribute db_name
		#   @!scope class
		#   @return [String] default database name. 
		@@db_name = 'default.db'

		# create/update db schema with sqlite3 gem (because sqlite doesn't like alter table 
		# and alter table is the only way to create foreign keys through activerecord
		# @return [true] if schema creation was successful.  raises Exception on failure.
		def sqlite_update_schema
			begin
				db = SQLite3::Database.open @@db_name

				#create media table
				r = db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "media" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"u_id" varchar,
						"media_set_id" integer, 
						"posting_id" integer, 
						"media_type" varchar,
						"object_yaml" text,
						FOREIGN KEY (media_set_id) REFERENCES media_sets(id)
					);
				SQL

			rescue SQLite3::Exception => e 

				puts "Exception occurred"
				puts e

			ensure
				db.close if db
			end
		end

		# enables foreign_keys flag for sqlite3. 
		# @return [true] if successful.  raises Exception on failure.
		def sqlite_enable_foreign_keys
		end

		# create/update db schema using active_record
		# @return [true] if schema creation was successful.  raises Exception on failure.
		def active_record_update_schema
		end

		# establish an  ActiveRecord connection to the database
		# @return [true] if schema creation was successful.  raises Exception on failure.
		def active_record_connect
			#if using sqlite3, enable foreign keys

			ActiveRecord::Base.establish_connection(
				:adapter => @@db_adapter,
				:database => @@db_name
			)			
		end

		class Website < ActiveRecord::Base
		end

		class MediaSet < ActiveRecord::Base
		end

		class Media < ActiveRecord::Base
			self.table_name = "media"
		end

		class Posting < ActiveRecord::Base
		end

		class Notification < ActiveRecord::Base
		end

		class User < ActiveRecord::Base
		end
	end
end

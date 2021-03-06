require 'active_record'
require 'sqlite3'

module Episodey
	#database module
	module DB
		# @!attribute db_adapter
		#   @!scope class
		#   @return [String] database adapter.  options [sqlite3] 
		mattr_writer :db_adapter do
			'sqlite3'
		end
		def self.db_adapter
			c = Episodey::Session.config[:database]
			@@db_adapter = c[:adapter] if !c.nil? && !c[:adapter].nil?
			@@db_adapter
		end


		# @!attribute db_name
		#   @!scope class
		#   @return [String] default database name. 
		mattr_writer :db_name do
			'default.db'
		end
		def self.db_name
			c = Episodey::Session.config[:database]
			@@db_name = c[:database] if !c.nil? && !c[:database].nil?
			@@db_name
		end

		class << self
			# create/update db schema with sqlite3 gem (because sqlite doesn't like alter table 
			# and alter table is the only way to create foreign keys through activerecord
			# @return [true] if schema creation was successful.  raises Exception on failure.
			def sqlite_update_schema
				begin
					db = SQLite3::Database.open self.db_name

					#create users table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "users" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"name" varchar(100),
						"email" varchar(255),
						"created_at" datetime,
						"updated_at" datetime
					);
					SQL

					#create media_sets table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "media_sets" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"u_id" varchar(100),
						"name" varchar(255), 
						"default_media_type" varchar(100), 
						"search_regex_json" text, 
						"identity_format_str" varchar(255),
						"object_yaml" text,
						"created_at" datetime,
						"updated_at" datetime
					);
					SQL

					#create media table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "media" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"u_id" varchar(100),
						"name" varchar(255), 
						"media_set_id" integer, 
						"posting_id" integer, 
						"media_type" varchar(100),
						"object_yaml" text,
						"created_at" datetime,
						"updated_at" datetime,
						FOREIGN KEY (media_set_id) REFERENCES media_sets(id) ON UPDATE CASCADE ON DELETE CASCADE
					);
					SQL

					#create postings table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "postings" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"media_id" integer, 
						"link" varchar(255),
						"html" text,
						"created_at" datetime,
						"updated_at" datetime,
						FOREIGN KEY (media_id) REFERENCES media(id) ON UPDATE CASCADE ON DELETE CASCADE
					);
					SQL

					#create websites table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "websites" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"u_id" varchar(100),
						"name" varchar(255), 
						"urls_yaml" text,
						"args_yaml" text,
						"created_at" datetime,
						"updated_at" datetime
					);
					SQL

					#create notifications table
					db.execute <<-SQL
					CREATE TABLE IF NOT EXISTS "notifications" (
						"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
						"user_id" integer,
						"ntype" varchar(50),
						"ntype_id" integer,
						"subject" varchar(500), 
						"message" text, 
						"is_sent" integer,
						"created_at" datetime,
						"updated_at" datetime,
						FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
					);
					SQL

				rescue SQLite3::Exception => e 
					raise e
				ensure
					db.close if db
				end
			end

			# enables foreign_keys flag for sqlite3. 
			# @return [true] if successful.  raises Exception on failure.
			def sqlite_enable_foreign_keys
				if ( self.db_adapter == 'sqlite3' )
					ActiveRecord::Base.connection.execute( "PRAGMA foreign_keys=1" )
				end
			end

			# create/update db schema using active_record
			# @return [true] if schema creation was successful.  raises Exception on failure.
			def active_record_update_schema
			end

			# establish an  ActiveRecord connection to the database
			# @return [true] if schema creation was successful.  raises Exception on failure.
			def active_record_connect
				ActiveRecord::Base.establish_connection(
					:adapter => self.db_adapter,
					:database => self.db_name
				)			

				#if using sqlite3, enable foreign keys
				self.sqlite_enable_foreign_keys
			end
		end

		class Website < ActiveRecord::Base
			def self.find_by_u_id(u_id)
				self.where(u_id: u_id).first
			end
		end

		class MediaSet < ActiveRecord::Base
			def self.find_by_u_id(u_id)
				self.where(u_id: u_id).first
			end
		end

		class Media < ActiveRecord::Base
			self.table_name = "media"

			def self.find_by_u_id(u_id)
				self.where(u_id: u_id).first
			end
		end

		class Posting < ActiveRecord::Base
		end

		class Notification < ActiveRecord::Base
			def self.find_unsent
				self.where("is_sent is null or is_sent <> ?" ,1).all
			end

			def self.find_by_key(user_id,ntype,ntype_id)
				self.where("user_id=? and ntype=? and ntype_id=?" ,user_id, ntype, ntype_id).first
			end
		end

		class User < ActiveRecord::Base
			def self.find_by_email(email)
				self.where("email=?",email).first
			end
		end
	end
end

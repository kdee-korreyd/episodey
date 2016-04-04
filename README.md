## Synopsis

episody is a gem which will scan bb type sites of your choosing and notify you when there are new episodes of shows you watch available.  But strongly discourages downloading those shows of course.

## Code Example
require 'episodey'

>all of the examples below are run from irb which is currently the main command line interface for episodey, as such you may use the same commands within a ruby script to perform the same actions and it will work just fine

#create a new episodey object
ep=EPISODEY::episodey

#initialize an episodey object with config and database info 
#	including scan config, websites, and media sets
'ep.load [scancfgfile]'

#scan websites specified in scan config for media sets specified in scan config
#	and hold all new media and create notifications about newly found media
ep.scan

#prints the new media list found by ep.scan
ep.list

#prints info for all media sets
ep.info

#send out any unsent notifications
ep.notify

#save current session (media sets, websites, notifications) for later use
ep.save

#clear out any currently saved scan information 
#	note: this does not remove data saved with ep.save it just clears out
#		the scan cache so you can run a new clean scan if you want
ep.clear

#flush first runs ep.save and then runs ep.clear
ep.flush

#enable a mod
ep.enmod [modname]

#disable a mod
ep.dismod [modname]

#list all available mods
ep.list\_mods

#list all enable mods
ep.list\_enmods


This application uses a sqlite3 db to store media, media set, website, and notification data.

You may also explicitly set media set & website data through their corresponding config files

#media set configs may be stored in
/media\_sets
	*.cfg <= json format

example:
#create a media set for episodes of the show 'Elementary'
#"name": => human readable name
#"u\_id": => uniq id for this media set (used as reference from other objects)
#"default\_media\_class": => instance type for media in this set
#"search\_url\_keys": => keys for website url entry points to search using
#"search": => regex list used to search for positings related to this media set
#"id\_format\_string": => a format string used to create a uniform u\_id for any media to be added to this media set
elementary.cfg
[
{
	"name": "elementary",
	"u_id": "elementary",
	"default_media_class": "Episode",
	"search_url_keys": ["home","shows"],
	"search": [
		"elementary.*s(\d{1,2})[^\d]*(\d{1,2})",
		"elementary.*season(\d{1,2})[ ]*episode(\d{1,2})"
	],
	"id_format_string": "elementary_s%02de%02d"
}
]

#website data may be stored in
/websites
	*.cfg <= json format
:name
:u\_id
:urls
-	:home
	:shows
	:movies
	:music
	:books
	:rss

example:
#create a website object
#"name": => human readable name
#"u\_id": => uniq id for this website (used as reference from other objects)
#"urls": => hash of entry point urls
rlsbb.cfg
[
{
	"name": "rlsbb",
	"u_id": "rlsbb",
	"urls": {
		"home": "http://rlsbb.com",
		"rss": "http://feeds.feedburner.com/rlsbb/MrCi",
		"shows": "http://rlsbb.com/category/tv-shows/",
		"movies": "http://rlsbb.com/category/movies/"
	},
}
]

## Scan Config File
scan config files (json format) may be stored anywhere and are referenced as the first parameter to ep.load

it has 2 params 
	*mediasets
	*websites

>each param is a list of regex which will determine which websites are crawled and which media sets episody will look for. the regex will be checked against the u\_id of each param type.

example:
#the following example will scan the websites dentoted by string rlsbb and divxcentral for new media from the 
#	media sets dentoed by elementary and fringe
scan.cfg
{
	"websites": [
		"^rlsbb$",
		"divxcentral"
	],

	"media_sets": [
		"^elementary$",
		"fringe"
	]
}


## Installation

git install episodey #thats all


## Contributors

fork me

you may add issues here or yell at me on:
@twitter

## License

the do whatever you want license

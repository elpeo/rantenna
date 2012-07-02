# antenna.rb $Revision: 1.20 $
# ＃
#
# Copyright (C) 2004  Michitaka Ohno <elpeo@mars.dti.ne.jp>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
# USA.

require 'net/http'
require 'timeout'
require 'time'
require 'cgi'
require 'nkf'
require 'digest/md5'

RANTENNA_VERSION = '0.0.7_20060821'

class Antenna
	attr_reader :antenna_url

	def initialize( conf = nil )
		@generator = "Powered by rAntenna #{RANTENNA_VERSION} and Ruby #{RUBY_VERSION}"
		@request_header = {
			'User-Agent' => "Mozilla/5.0 (compatible; MSIE6.0) rAntenna #{RANTENNA_VERSION}",
			'Accept-Language' => "ja, en-us"
		}

		@dir = File::dirname( __FILE__ )
		conf_path = conf || File.expand_path( 'antenna.conf', @dir )
		@confdir = File::dirname( conf_path )

		eval( File::open( conf_path ){|f| f.read }.untaint )

		@urls ||= []
		@rdf_path ||= 'index.rdf'
		@cache_path ||= 'antenna.cache'

		if defined?( NKF::UTF8 ) then
			@rdf_encoding = 'UTF-8'
			@rdf_encoder = Proc::new {|s| NKF::nkf( '-m0 -Ew', s ) }
		else
			begin
				require 'uconv'
				@rdf_encoding = 'UTF-8'
				@rdf_encoder = Proc::new {|s| Uconv.euctou8( s ) }
			rescue LoadError
				@rdf_encoding = 'EUC-JP'
				@rdf_encoder = Proc::new {|s| s }
			end
		end

		@last_modified = Hash.new
		@last_detected = Hash.new
		@content_length = Hash.new
		@auth_url = Hash.new
		@md5sum = Hash.new

		@input_procs = []
		@output_procs = []

		Dir::glob( File.join( @dir, 'plugin', '*.rb' ) ).sort.each do |file|
			instance_eval( File::open( file.untaint ){|f| f.read }.untaint )
		end
	end

	def add_input_proc( block = Proc::new )
		@input_procs << block
	end

	def add_output_proc( block = Proc::new )
		@output_procs << block
	end

	def include_range( s, e )
		return /#{Regexp.escape( s )}.+?#{Regexp.escape( e )}/mie
	end
	
	def exclude_range( s, e )
		return /^(.*)#{Regexp.escape( s )}.+?#{Regexp.escape( e )}(.*)$/mie
	end
	
	def get_filter( url )
		return unless @filters
		@filters.each do |key, value|
			if key.instance_of?( Regexp ) ? key =~ url : key == url then
				return value if value.instance_of?( Proc )
				return Proc::new do |s|
					if value =~ s then
						$~[1] ? $~[1..-1].to_s : $~[0]
					else
						s
					end
				end
			end
		end
		nil
	end

	def parse_url( url, key, redirected = false )
		return unless %r|^http://([^/]+)(/.*)?$| =~ url
		path = $2||'/'
		host, port = $1.split( /:/ )
		port = '80' unless /^[0-9]+$/ =~ port
		f = get_filter( key )
		Net::HTTP.version_1_2
		Net::HTTP.start( host.untaint, port.to_i.untaint ) do |http|
			response = f ? http.get( path, @request_header ) : http.head( path, @request_header )
			date = response['Date'] ? Time.parse( response['Date'] ) : Time.now
			lm = Time.parse( response['Last-Modified'] ) if response['Last-Modified']
			if !redirected && response['Location'] then
				if %r|^https?://| =~ response['Location'] then
					parse_url( response['Location'], key, true )
				else
					begin
						require 'uri'
						parse_url( URI.join( url, response['Location'] ).to_s, key, true )
					rescue LoadError
					end
				end
 			elsif lm && lm < date then
				@last_modified[key] = lm.localtime
				@content_length[key] = response['Content-Length'].to_i
				@last_detected[key] = Time.now
				@auth_url[key] = @antenna_url
			else
				if !response.body then
					begin
						response = http.get( path, @request_header )
					rescue
						http.finish
						http.start
						response = http.get( path, @request_header )
					end
				end
				body = response.body
				body = f.call( NKF::nkf( '-m0 -e', body ) ) if f
				lm = get_last_modified( body )
				if lm then
		 			@last_modified[key] = lm
					@last_detected[key] = Time.now
					@auth_url[key] = @antenna_url
				end
				@content_length[key] = response['Content-Length'].to_i
				if f then
					@md5sum[key] = Digest::MD5.hexdigest( body )
				else
					@md5sum[key] = Digest::MD5.hexdigest( body.gsub( /<(script|style)[^<>]*>[^<>]*<\/\1>|<[^<>]*>|\s+/i, '' ) )
				end
			end
		end
	end

	def go_round
		@input_procs.each do |proc|
			proc.call
		end

		limittime = 10

		@urls.each do |item|
			next if @last_modified[item[2]]
			timeout( limittime ) do
				begin
					parse_url( item[3]||item[2], item[2], item[4] )
				rescue Exception
				rescue
				end
			end
		end
	end

	def output
		input_cache
		output_rdf
		output_cache
		@output_procs.each do |proc|
			proc.call
		end
	end

	def output_rdf
		output_file = File.expand_path( @rdf_path, @confdir )

		sorted_urls = @urls.sort {|a, b| urls_compare( a, b ) }

		r = ""
		r << <<-RDF
<?xml version="1.0" encoding="#{@rdf_encoding}"?>
<?xml-stylesheet href="index.xsl" type="text/xsl" media="screen"?>

<rdf:RDF xmlns="http://purl.org/rss/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:syn="http://purl.org/rss/1.0/modules/syndication/" xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/">
<channel rdf:about="#{CGI::escapeHTML( @rdf_url )}">
<title>#{CGI::escapeHTML( @title )}</title>
<link>#{CGI::escapeHTML( @antenna_url )}</link>
<description>#{CGI::escapeHTML( @title )}</description>
<dc:date>#{Time.now.xmlschema}</dc:date>
<dc:language>ja</dc:language>
<dc:rights>#{CGI::escapeHTML( @copyright )}</dc:rights>
<dc:publisher>#{CGI::escapeHTML( @generator )}</dc:publisher>
<items>
<rdf:Seq>
RDF

		sorted_urls.each do |item|
			next unless item
			linkurl = get_link( item[2] )
			r << <<-RDF
<rdf:li rdf:resource="#{CGI::escapeHTML( linkurl )}"/>
RDF
		end

		r << <<-RDF
</rdf:Seq>
</items>
</channel>
RDF

		sorted_urls.each do |item|
			next unless item
			linkurl = get_link( item[2] )
			r << <<-RDF
<item rdf:about="#{CGI::escapeHTML( linkurl )}">
<title>#{CGI::escapeHTML( item[0] )}</title>
<link>#{CGI::escapeHTML( linkurl )}</link>
<description/>
<dc:creator>#{CGI::escapeHTML( item[1] )}</dc:creator>
RDF
			if @last_modified[item[2]] then
				r << <<-RDF
<dc:date>#{@last_modified[item[2]].xmlschema}</dc:date>
RDF
			end
			r << <<-RDF
</item>
RDF
		end

		r << <<-RDF
</rdf:RDF>
RDF

		open( output_file,  "w" ) do |f|
			f.print @rdf_encoder.call( r )
		end
	end

	def input_cache
		input_file = File.expand_path( @cache_path, @confdir )
		return unless File.exist?( input_file )
		IO.foreach( input_file ) do |line|
			url, date, md5 = line.strip.split( /\t/ )
			next if @last_modified[url]
			if @md5sum[url] && md5 && @md5sum[url] != md5 then
				@last_modified[url] = Time.now
				@last_detected[url] = Time.now
				@auth_url[url] = @antenna_url
			elsif date.to_i != 0 then
				@last_modified[url] = Time.at( date.to_i )
			end
		end
	end

	def output_cache
		output_file = File.expand_path( @cache_path, @confdir )
		open( output_file,  "w" ) do |f|
			@urls.each do |item|
				next unless item
				f.puts "#{item[2]}\t#{@last_modified[item[2]].to_i}\t#{@md5sum[item[2]]}"
			end
		end
	end

	def urls_compare( a, b )
		atime = @last_modified[a[2]]
		btime = @last_modified[b[2]]
		if atime && btime then
			btime <=> atime
		elsif atime then
			-1
		elsif btime then
			1
		else
			0
		end
	end

	def get_link( url )
		return url unless @link_format && @last_modified[url]
		format =  @link_format.gsub( /%(antenna_url|url)%/ ){ eval( $1 ) }
		@last_modified[url].strftime( format )
	end

	def get_last_modified( str )
		if /<rdf:RDF[>\s]/ =~ str && %r|<dc:date>\s*([^<>]+)\s*</dc:date>| =~ str then
			return Time.parse( $1, nil ).localtime
		end
		if /<rss[>\s]/ =~ str && %r|<pubDate>\s*([^<>]+)\s*</pubDate>| =~ str then
			return Time.parse( $1, nil ).localtime
		end
		lm = nil
		alter = nil
		data = NKF::nkf( '-m0 -e', str ).gsub( /<(?!meta|!--)[^>]*>/im, '' ).split( /\s*[\r\n]+\s*/ )
		data.each_index do |i|
			if /http-equiv=\"?last-modified.+content=\"([^\"]+)\"/i =~ data[i] then
				begin
					date = Time.parse( $1, nil ).localtime
					lm ||= date
					lm = date if date > lm
					break
				rescue Exception
				rescue
				end
			elsif /name=\"?wwwc.+content=\"([^\"]+)\"/i =~ data[i] then
				begin
					date = Time.parse( $1, nil ).localtime
					lm ||= date
					lm = date if date > lm
					break
				rescue Exception
				rescue
				end
			elsif /更新|update|modified/ie =~ data[i] then
				s = (data[i-1]||'') + data[i] + (data[i+1]||'')
				begin
					if /(?:([0-9]+)年\s*)?([0-9]+)月\s*([0-9]+)日/e =~ s then
						y = $1
						unless y then
							n = Time.now
							y = ($2.to_i>n.month) ? (n.year-1) : n.year
						end
						d = Time.parse( "#{y}-#{$2}-#{$3}" )
					elsif /(?:([0-9]+)[\/\.\-])?([0-9]+)[\/\.\-]([0-9]+)/ =~ s then
						y = $1
						unless y then
							n = Time.now
							y = ($2.to_i>n.month) ? (n.year-1) : n.year
						end
						d = Time.parse( "#{y}-#{$2}-#{$3}" )
					elsif /[0-9]+-[A-Z][a-z]+-[0-9]+/ =~ s then
						d = Time.parse( $& )
					elsif / [0-9]{1,2} [A-Z][a-z]{2} [0-9]{4} / =~ s then
						d = Time.parse( $& )
					else
						next
					end
					if /([0-9]+)時\s*([0-9]+)分(?:\s*([0-9]+)秒)?/e =~ s then
						t = Time.parse( "#{$1}:#{$2}:#{$3}" )
					elsif /[0-9]+:[0-9]+(:[0-9]+)?/ =~ s then
						t = Time.parse( $& )
					elsif /([0-9]+)：([0-9]+)/ =~ s then
						t = Time.parse( "#{$1}:#{$2}" )
					else
						next
					end
					if /GMT/ =~ s then
						date = Time.gm( d.year, d.month, d.day, t.hour, t.min , t.sec ).localtime
					elsif /UTC/ =~ s then
						date = Time.utc( d.year, d.month, d.day, t.hour, t.min , t.sec ).localtime
					else
						date = Time.local( d.year, d.month, d.day, t.hour, t.min , t.sec )
					end
					if date < Time.now then
						lm ||= date
						lm = date if date > lm
					end
				rescue Exception
				rescue
				end
			elsif /\d+[\/\.\-]\s*\d+[\/\.\-]\s*\d+.+\d+:\d+(:\d+)?/ =~ data[i] then
				begin
					date = Time.parse( $&.gsub( /[\.\/]\s*/, '-' ), nil )
					if date < Time.now then
						alter ||= date
						alter = date if date > alter
					end
				rescue Exception
				rescue
				end
			end
		end
		lm || alter
	end
end


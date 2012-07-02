# input_lirs.rb $Revision: 1.5 $
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
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# Last modified Information Relaying Specification ver.2.1
# http://aniki.haun.org/natsu/natsu3.1b/doc/LIRS.html

# antenna.conf
# @input_lirs_urls = [
# 'http://natsu.tnh.jp/natsumican.lirs',
# ]

require 'net/http'
require 'timeout'

eval( <<-TOPLEVEL_CLASS, TOPLEVEL_BINDING )
class String
	def csplit
		r = []
		s = ""
		each_byte do |byte|
			if byte == ?, && s[-1] != ?\\\\ then
				r << s
				s = ""
			else
				s << byte
			end
		end
		r << s
	end
end
TOPLEVEL_CLASS

class StringReader
	def initialize( s )
		@str = s
			@index = 0
	end
	def read( length = nil )
		if @index < @str.length then
			nth = @index
			len = length || @str.lenth
			@index += len
			@str[nth, len]
		else
			length ? nil : ""
		end
	end
end

def input_lirs
	lirs_urls = @input_lirs_urls||[]

	limittime = 10

	lirs_urls.each do |url|
		next unless %r[^http://([^/]+)(/.*)?$] =~ url
		path = $2 || '/'
		host, port = $1.split( /:/ )
		port = '80' unless /^[0-9]+$/ =~ port
		timeout( limittime ) do
			begin
				Net::HTTP.version_1_1
				Net::HTTP.start( host.untaint, port.to_i.untaint ) do |http|
					response, = http.get( path )
					buf = response.body
					if /gzip/i =~ response['Content-Encoding'] || /.gz$/i =~ url then
						begin
							require 'zlib'
							sr = StringReader.new( buf )
							gz = Zlib::GzipReader.new( sr )
							buf = gz.read
							gz.close
						rescue LoadError
						end
					end
					buf.each do |line|
#						lirs = line.strip.split( /\,/ )
						lirs = line.strip.csplit
						next unless lirs[0] == 'LIRS'
						lm = lirs[1].to_i
						ld = lirs[2].to_i
						cl = lirs[4].to_i
						site = lirs[5]
						au = lirs[8]
						next if lm == 0
						date = Time.at( lm )
						next if @last_modified[site] && @last_modified[site] > date
						@last_modified[site] = date
						@last_detected[site] =  ld == 0 ? nil : Time.at( ld )
						@content_length[site] = cl
						if au && au != "" && au != "0" then
							@auth_url[site] = au
						else
							@auth_url[site] = File.dirname( url ) + '/'
						end
					end
				end
			rescue Exception
			rescue
			end
		end
	end
end

add_input_proc do
	input_lirs
end

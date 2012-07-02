# output_html.rb $Revision: 1.6 $
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

# antenna.conf
# @output_html_templates = [
# ['template.html','index.html'],
# ]
#

require 'cgi'

def output_html
	templates = @output_html_templates || [ ['template.html','index.html'] ]

	update = Time.now.to_s

	templates.each do |i|
		next unless i && i[0] && i[1]
		template = File.expand_path( i[0], @confdir )
		output = File.expand_path( i[1], @confdir )
		next unless File.exist?( template )
		html = open( template ) do |f|
			f.read
		end
		html.gsub!( /%(title|copyright|antenna_url|rdf_url|update|generator)%/i ) do
			CGI::escapeHTML( eval( "defined?( #{$1} ) ? #{$1} : @#{$1}" ) )
		end
		html.gsub!( /%begin%\s*(.+)%end%\s*/im ) do
			line = $1
			r = ""
			@urls.sort {|a, b| urls_compare( a, b ) }.each do |item|
				next unless item
				name, author, url = item
				link = get_link( url )
				auth_url = @auth_url[url]||@antenna_url
				format = line.gsub( /%(name|author|url|link|auth_url)%/i ) do
					CGI::escapeHTML( eval( "defined?( #{$1} ) ? #{$1} : @#{$1}" ).gsub( /%/, '%%' ) )
				end
				if @last_modified[url] then
					r << @last_modified[url].strftime( format )
				else
					r << format.gsub( /%(.)/ ) do
						if $1 == '%' then
							'%'
						else
							'-' * Time.now.strftime( "%#{$1}" ).length
						end
					end
				end
			end
			r
		end

		open( output, "w" ) do |f|
			f.print html
		end
	end
end

add_output_proc do
	output_html
end

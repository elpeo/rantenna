# output_imode.rb $Revision: 1.2 $
#
# Copyright (C) 2005  Michitaka Ohno <elpeo@mars.dti.ne.jp>
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
# @output_imode_path = [
# 'imode.html',
# ]
#

require 'cgi'

def output_imode
	paths = @output_imode_path || ['imode.html']

	title = CGI::escapeHTML( NKF::nkf( '-m0 -s', @title ) )
	html = <<-HTML
<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=Shift_JIS">
<TITLE>#{title}</TITLE>
</HEAD>
<BODY>
<H1>#{title}</H1>
HTML

	sorted_urls = @urls.sort {|a, b| urls_compare( a, b ) }
	sorted_urls.each_index do |i|
		next unless sorted_urls[i]
		name = CGI::escapeHTML( NKF::nkf( '-m0 -s', sorted_urls[i][0] ) )
		url = CGI::escapeHTML( NKF::nkf( '-m0 -s', sorted_urls[i][2] ) )
		sa = i < 10 ? [63879+i].pack( "n" ) : "\x81\xa0"
		ac = i < 10 ? %Q[ACCESSKEY="#{(i+1)%10}"] : ''
		if i == 10 then
			sa = "\xf9\x85"
			ac = 'ACCESSKEY="#"'
		end
		html << <<-HTML
<A HREF="#{url}" #{ac}>#{sa}#{name}</A><BR>
HTML
	end

	html << <<-HTML
</BODY>
</HTML>
HTML

	paths.each do |item|
		next unless item
		open( File.expand_path( item, @confdir ), "w" ) do |f|
			f.print html
		end
	end
end

add_output_proc do
	output_imode
end

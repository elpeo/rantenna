#!/usr/bin/env ruby
#
# go.rb $Revision: 1.4 $
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

# Inspired by a discussion of following URL:
# http://mput.dip.jp/mput/?date=20040316#p05

BEGIN { $defout.binmode }

require 'cgi'

if ENV['PATH_INFO'] then
	url = ENV['PATH_INFO'].split( /\//, 3 )[2].sub( /^http:\/+/, 'http://' )
	if ENV['QUERY_STRING'] && ENV['QUERY_STRING'] != "" then
		url << '?' + ENV['QUERY_STRING']
	end
else
	require File.expand_path( 'antenna.rb', File::dirname( __FILE__ ) )
	url = Antenna.new.antenna_url
end

print CGI.new.header( {"status" => "REDIRECT", "Location" => url} ) 


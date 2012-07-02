#!/usr/bin/env ruby
#
# update.rb $Revision: 1.4 $
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

BEGIN { $defout.binmode }

require File.expand_path( 'antenna.rb', File::dirname( __FILE__ ) )

if ENV['REQUEST_METHOD'] then
	require 'cgi'
	path = Antenna.new.antenna_url
	print CGI.new.header( {'type' => 'text/html'} )
	print <<-HTML
	<html>
	<head>
	<meta http-equiv="refresh" content="0;url=#{path}">
	<title>moving...</title>
	</head>
	<body>Wait or <a href="#{path}">Click here!</a></body>
	</html>
	HTML
elsif ARGV.empty? then
	a = Antenna.new
	a.go_round
	a.output
else
	ARGV.each do |item|
		a = Antenna.new( item )
		a.go_round
		a.output
	end
end


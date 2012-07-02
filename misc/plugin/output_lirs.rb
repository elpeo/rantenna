# output_lirs.rb $Revision: 1.3 $
#
# Copyright (C) 2004  Norihiro Hattori <tnh@webmasters.gr.jp>
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
# @output_lirs_path = [
# 'natsumican.lirs',
# ]
#

def output_lirs
	lirs_paths = @output_lirs_path || ['rantenna.lirs']

	l = ""
	@urls.each do |item|
		next unless item
		l << <<-LIRS
LIRS,#{@last_modified[item[2]].to_i},#{@last_detected[item[2]].to_i},32400,#{@content_length[item[2]]||0},#{item[2]},#{item[0]},#{item[1]},#{@auth_url[item[2]]},#{item[3]},
LIRS
	end

	lirs_paths.each do |item|
		next unless item
		file = File.expand_path( item, @confdir )
		open( file,  "w" ) do |f|
			f.print l
		end
		begin
			require 'zlib'
			Zlib::GzipWriter.open( "#{file}.gz" ) do |gz|
				gz.write l
			end
		rescue LoadError
		end
	end
end

add_output_proc do
	output_lirs
end

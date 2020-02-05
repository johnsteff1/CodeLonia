# frozen_string_literal: true

# Copyright (c) 2020 Denis Treshchev
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'loog'
require_relative 'xia'
require_relative 'reviews'
require_relative 'badges'

# Project.
# Author:: Denis Treshchev (denistreshchev@gmail.com)
# Copyright:: Copyright (c) 2020 Denis Treshchev
# License:: MIT
class Xia::Project
  attr_reader :id
  attr_reader :author

  def initialize(pgsql, author, id, log: Loog::NULL)
    @pgsql = pgsql
    @author = author
    @id = id
    @log = log
  end

  def coordinates
    row['coordinates']
  end

  def reviews
    Xia::Reviews.new(@pgsql, self, log: @log)
  end

  def badges
    Xia::Badges.new(@pgsql, self, log: @log)
  end

  def delete
    raise Xia::Urror, 'Not enough karma to delete a project' if @author.karma.points < 500
    @pgsql.exec(
      'UPDATE project SET deleted = $2 WHERE id=$1',
      [@id, "Deleted by @#{@author.login} on #{Time.now.utc.iso8601}"]
    )
  end

  private

  def row
    row = @pgsql.exec(
      'SELECT * FROM project WHERE id=$1',
      [@id]
    )[0]
    raise Xia::Urror, "Project ##{@id} not found in the database" if row.nil?
    row
  end
end

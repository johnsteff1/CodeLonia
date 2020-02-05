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
require_relative 'urror'
require_relative 'projects'
require_relative 'withdrawals'
require_relative 'karma'

# One author.
# Author:: Denis Treshchev (denistreshchev@gmail.com)
# Copyright:: Copyright (c) 2020 Denis Treshchev
# License:: MIT
class Xia::Author
  attr_reader :id

  def initialize(pgsql, id, log: Loog::NULL)
    @pgsql = pgsql
    @id = id
    @log = log
  end

  def vip?
    login == 'denistreshchev' || login == '-test-'
  end

  def login
    row['login']
  end

  def karma
    Xia::Karma.new(@pgsql, self, log: @log)
  end

  def projects
    Xia::Projects.new(@pgsql, self, log: @log)
  end

  def withdrawals
    Xia::Withdrawals.new(@pgsql, self, log: @log)
  end

  private

  def row
    row = @pgsql.exec('SELECT * FROM author WHERE id=$1', [@id])[0]
    raise Xia::Urror, "Author @#{@login} not found in the database" if row.nil?
    row
  end
end

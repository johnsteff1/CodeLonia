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

# The rank of an author.
# Author:: Denis Treshchev (denistreshchev@gmail.com)
# Copyright:: Copyright (c) 2020 Denis Treshchev
# License:: MIT
class Xia::Rank
  def initialize(author, log: Loog::NULL)
    @author = author
    @log = log
  end

  def legend
    [
      {
        task: 'withdraw',
        min: 100,
        text: 'pay that much'
      },
      {
        task: 'projects.submit',
        min: 0,
        text: 'submit a new project'
      },
      {
        task: 'projects.delete',
        min: 500,
        text: 'delete an existing project'
      },
      {
        task: 'reviews.post',
        min: 0,
        text: 'post a review'
      },
      {
        task: 'reviews.delete',
        min: 500,
        text: 'delete an existing review'
      },
      {
        task: 'reviews.upvote',
        min: 100,
        text: 'upvote a review'
      },
      {
        task: 'reviews.downvote',
        min: 200,
        text: 'downvote a review'
      },
      {
        task: 'badges.attach',
        min: 100,
        text: 'attach a new badge'
      },
      {
        task: 'badges.detach',
        min: 500,
        text: 'detach an existing badge'
      }
    ]
  end

  def enter(task, safe: false)
    return if @author.vip?
    info = legend.find { |i| i[:task] == task }
    raise "Unknown task #{task.inspect}" if info.nil?
    karma = @author.karma.points(safe: safe)
    txt = format('%+d', karma)
    if info[:min] && karma < info[:min]
      raise Xia::Urror, "Can't #{info[:text]} with a negative karma #{txt}" if karma.negative?
      raise Xia::Urror, "Not enough karma #{txt} to #{info[:text]}"
    end
    karma
  end
end

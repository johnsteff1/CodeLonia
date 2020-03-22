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
require_relative 'withdrawals'

# Karma.
# Author:: Denis Treshchev (denistreshchev@gmail.com)
# Copyright:: Copyright (c) 2020 Denis Treshchev
# License:: MIT
class Xia::Karma
  attr_reader :author

  def initialize(pgsql, author, log: Loog::NULL)
    @pgsql = pgsql
    @author = author
    @log = log
  end

  def legend
    [
      {
        points: +1,
        query: 'SELECT * FROM project AS t WHERE author=$1 AND deleted IS NULL',
        terms: 'each project you submitted',
        history: 'The project #[id]:[coordinates] you submitted'
      },
      {
        points: +5,
        query: [
          'SELECT t.* FROM (',
          '  SELECT *, (SELECT COUNT(*) FROM badge WHERE badge.project=project.id) AS badges',
          '  FROM project',
          '  WHERE author=$1 AND deleted IS NULL',
          ') AS t WHERE badges >= 10'
        ].join(' '),
        terms: 'each project with more than one badge',
        history: 'The project #[id]:[coordinates] you submitted got a few badges'
      },
      {
        points: +1,
        query: 'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NULL',
        terms: 'each review you submitted',
        history: 'The review #[id] you submitted'
      },
      {
        points: +10,
        query: [
          'SELECT t.* FROM (',
          '  SELECT *, (SELECT COUNT(*) FROM vote WHERE review.id=vote.review AND positive=true) AS votes',
          '  FROM review',
          '  WHERE author=$1 AND deleted IS NULL',
          ') AS t WHERE votes >= 10'
        ].join(' '),
        terms: 'each review of yours, which collected 10+ upvotes',
        history: 'Your review #[id] was upvoted 10+ times'
      },
      {
        points: 0,
        query: [
          'SELECT t.* FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=true'
        ].join(' '),
        terms: 'each review of yours, which was up-voted',
        history: 'You review #[id] was up-voted'
      },
      {
        points: -5,
        query: [
          'SELECT t.* FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=false'
        ].join(' '),
        terms: 'each review of yours, which was down-voted',
        history: 'Your review #[id] was down-voted'
      },
      {
        points: -25,
        query: 'SELECT * FROM project AS t WHERE author=$1 AND deleted IS NOT NULL',
        terms: 'each project you submitted, which was deleted later',
        history: 'The roject #[id]:[coordinates] you submitted was deleted'
      },
      {
        points: -50,
        query: 'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NOT NULL',
        terms: 'each review you submitted, which was deleted later',
        history: 'The review #[id] you submitted was deleted'
      }
    ]
  end

  def points(safe: false)
    earned = legend.reject { |g| g[:points].negative? && @author.bot? }.map do |g|
      @pgsql.exec(
        [
          "SELECT COUNT(*) FROM (#{g[:query]}) AS q",
          safe ? 'WHERE q.created < NOW() - INTERVAL \'2 DAY\'' : ''
        ].join(' '),
        [@author.id]
      )[0]['count'].to_i * g[:points]
    end.inject(&:+)
    paid = @pgsql.exec('SELECT SUM(points) FROM withdrawal WHERE author=$1', [@author.id])[0]['sum'].to_i
    earned -= 100 if safe
    @points ||= earned - paid
  end

  def recent(limit: 10)
    legend.map do |g|
      @pgsql.exec("#{g[:query]} ORDER BY t.created DESC LIMIT $2", [@author.id, limit]).map do |r|
        {
          text: g[:history].gsub(/\[([a-z]+)\]/) { r[Regexp.last_match[1]] },
          points: g[:points],
          created: Time.parse(r['created'])
        }
      end
    end.flatten.reject { |r| r[:points].zero? }.sort_by { |r| r[:created] }.reverse.take(limit)
  end
end

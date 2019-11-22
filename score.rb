require 'net/http'
require 'json'

# 1. Get data from http
# 2. Parsing JSON
# 3. Calculate score
# 4. Show score

class Http
  attr_reader :client

  def initialize(client = Net::HTTP)
    @client = client
  end

  def get(url)
    begin
      client.get(url)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
       p "Error while fetching event list :: ",e
    end
  end
end

class Github
  BASE_URI = "https://api.github.com"

  attr_reader :http

  def initialize(http: Http.new)
    @http = http
  end

  def events(user)
    json http.get(URI.join(BASE_URI, "/users/#{user}/events/public"))
  end

  private

  def json(body)
    JSON.parse(body)
  end
end

class CalculateUserScore
  EVENT_WITH_SCORE = {
            :IssuesEvent => 7,
            :IssueCommentEvent =>  6,
            :PushEvent => 5,
            :PullRequestReviewCommentEvent => 4,
            :WatchEvent => 3,
            :CreateEvent => 2
         }
  def initialize(user_name)
    @user_name = user_name
    @score = 0
  end

  def total_score
    calculate
    puts "#{@user_name} github score is #{@score}"
  end

  private

  def calculate
    events = Github.new.events(@user_name)
    return 0 if events.empty?
    grouped_event_types = events.group_by {|x| x["type"]}.transform_values{|v| v = v.count }.transform_keys!(&:to_sym)
    @score = grouped_event_types.map{|k,v|
      if EVENT_WITH_SCORE.key? k
          v * EVENT_WITH_SCORE[k]
      else
          v
      end
    }.inject(:+)
  end
end

puts CalculateUserScore.new("dhh").total_score

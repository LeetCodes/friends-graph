require 'open-uri'
require 'net/http'
require 'set'
require 'json'

class Scraper
  UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/40.0.2214.111 Chrome/40.0.2214.111 Safari/537.36'
  MUTUAL_FRIENDS_URI = "https://www.facebook.com/ajax/browser/list/mutualfriends/?uid=%s&view=list&location=other&infinitescroll=0&node=%s&start=%d&dpr=1&__user=%s&__a=1&__dyn=%s"

  def initialize(user, auth, dyn)
    @user = user
    @auth = auth
    @dyn  = dyn
    @cookies = ["c_user=#{@user}", "xs=#{@auth}"].join(";\s")
  end

  def get_id(username)
    return username if username.match(/^\d+$/)
    get_html("https://mbasic.facebook.com/#{username}/about")[/block\/confirm\/\?bid=(\d+)/, 1]
  end

  def get_username(id)
    return id unless id.match(/^\d+$/)
    get_html("https://www.facebook.com/#{id}")[/URL=\/([\w.]+)\?_fb_noscript=1/, 1] || id
  end

  def get_friends(user_id)
    friends = []
    user_id = get_id(user_id)
    url = "https://mbasic.facebook.com/profile.php?v=friends&id=#{user_id}&startindex=0"
    loop do
      html = get_html(url)
      friends += extract_friends(html)
      url = more_friends(html)
      break if url.nil?
    end
    return friends
  end

  def get_mutual_friends(user_id1, user_id2)
    mutual_friends = []
    user_id1, user_id2 = get_id(user_id1), get_id(user_id2)
    index = 0
    loop do
      url  = MUTUAL_FRIENDS_URI % [user_id1, user_id2, index, @user, @dyn]
      html = JSON.parse(get_html(url).sub('for (;;);', ''))['domops'][0][3]['__html']
      mutual_friends += html.scan(/&quot;eng_tid&quot;:&quot;(\d+)&quot;/).flatten
      break if html[/See More/].nil?
      index += 30
    end
    return mutual_friends
  end

  def get_hidden_friends(initial_friends, user, used_friends = nil)
    friends = initial_friends.to_set
    used_friends = used_friends.nil? ? Set.new : used_friends.to_set

    while not friends.subset?(used_friends)
      (friends - used_friends).each do |friend|
        used_friends.add(friend)
        friends += get_mutual_friends(user, friend)
      end
    end

    return friends
  end

  def are_friends?(user_one, user_two, common_friend)
    get_mutual_friends(common_friend, user_one).map{ |f| f[:id] }.member?(get_username(user_two))
  end

  private

  def more_friends(html)
    path = html.gsub('&amp;', '&')[/id="m_more_(?:mutual_)?friends"><a href="([^"]+)">/, 1]
    return "https://mbasic.facebook.com#{path}" unless path.nil?
  end

  def extract_friends(html)
    regex = Regexp.new('/></td><td class="[^"]+"><a class="[^"]+" href="([^"]+)">([^<]+)</a>')
    html.scan(regex).map { |f|
      { :name => f[1],
        :id   => f[0].match(/\/(?:profile\.php\?id=)?([^?&]+)/)[1]
      }
    }
  end

  def get_html(url)
    puts url
  begin
    open(url, { 'cookie' => @cookies, 'user-agent' => UA }).read
  rescue
    return ''
  end
  end

  def get_head(url)
    puts "HEAD:\s#{url}"
    uri = URI url
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https') do |http|
      http.head uri.request_uri, { 'cookie' => @cookies, 'user-agent' => UA }
    end
  end
end


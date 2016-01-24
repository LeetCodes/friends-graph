require 'open-uri'

UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/40.0.2214.111 Chrome/40.0.2214.111 Safari/537.36'

class Scraper
  @user = ''
  @auth = ''

  def initialize(user, auth)
    @user = user
    @auth = auth
  end

  def get_id(username)
    return username if username.match(/^\d+$/)
    get_html("https://mbasic.facebook.com/#{username}/about").match(/block\/confirm\/\?bid=(\d+)/)[1]
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
    url = "https://mbasic.facebook.com/profile.php?v=friends&mutual=1&id=#{user_id1}&and=#{user_id2}&startindex=0"
    loop do
      html = get_html(url)
      mutual_friends += extract_friends(html)
      url = more_friends(html)
      break if url.nil?
    end
    return mutual_friends
  end

  def are_friends?(user_one, user_two, common_friend)
    get_mutual_friends(common_friend, user_one).map{ |f| f[:id] }.member?(get_username(user_two))
  end

  private

  def more_friends(html)
    regex = Regexp.new('id="m_more_(?:mutual_)?friends"><a href="([^"]+)">')
    match = html.match(regex)
    match.nil? ? nil : 'https://mbasic.facebook.com' + match[1].gsub('&amp;', '&')
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
    c_user = 'c_user=' + @user
    xs = 'xs=' + @auth
  begin
    open(url, { 'cookie' => [c_user, xs].join(";\s"), 'user-agent' => UA }).read
  rescue
    return ''
  end
  end

end


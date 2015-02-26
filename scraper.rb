require 'open-uri'

class Scraper
  @user = ''
  @auth = ''

  def initialize(user, auth)
    @user = user
    @auth = auth
  end

  def get_friends(user_id)
    friends = []
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
    url = "https://mbasic.facebook.com/profile.php?v=friends&mutual=1&id=#{user_id1}&and=#{user_id2}&startindex=0"
    loop do
      html = get_html(url)
      mutual_friends += extract_friends(html)
      url = more_friends(html)
      break if url.nil?
    end
    return mutual_friends
  end

  #private

  def more_friends(html)
    regex = Regexp.new('<div class="[^"]+" id="m_more_(?:mutual_)?friends"><a href="([^"]+)"><span>[^<]+</span></a></div>')
    match = html.match(regex)
    match.nil? ? nil : 'https://mbasic.facebook.com' + match[1].gsub('&amp;', '&')
  end

  def extract_friends(html)
    regex = Regexp.new('<a href="[^"]+"><span class="[^"]+">([^<]+)</span></a><br />')
    html.scan(regex).flatten
  end

  def get_html(url)
    c_user = 'c_user=' + @user
    xs = 'xs=' + @auth
    open(url, { 'cookie' => [c_user, xs].join(";\s") }).read
  end

end


require_relative 'scraper.rb'

class PhotosScraper < Scraper
  def get_albums(user)
    albums = []
    url = "https://mbasic.facebook.com/#{get_username(user)}/photos/albums/?owner_id=#{get_id(user)}"
    loop do
      html = get_html(url)
      albums += extract_albums(html)
      url = more_albums(html)
      break if url.nil?
    end
    return albums
  end

  def get_photos(album_url)
    photos = []
    url = album_url
    loop do
      html = get_html(url)
      photos += extract_photos(html)
      url = more_photos(html)
      break if url.nil?
    end
    return photos
  end

  def get_photos_of(user)
    id = get_id(user)
    url = "https://mbasic.facebook.com/#{get_username(user)}/photoset/t.#{id}/?owner_id=#{id}"
    get_photos(url)
  end

  def get_uploads(user)
    get_photos(get_uploads_album(user))
  end

  def get_uploads_album(user)
    m = get_html("https://mbasic.facebook.com/profile.php?id=#{get_id(user)}&v=photos")
    .gsub('&amp;', '&')[/Uploads.*?<a href="(.*?)">See All<\/a>/, 1]
    "https://mbasic.facebook.com#{m}"
  end

  def get_photo_url(id)
    # XXX: actually downloads the file
    open("https://www.facebook.com/photo/download/?fbid=#{id}").base_uri.to_s
  end

  def get_photo_dl_url(id)
    "https://www.facebook.com/photo/download/?fbid=#{id}"
  end

  private

  def more_albums(html)
    m = html.gsub('&amp;', '&')[/<a href="([^"]+)"><span class="[^"]+">See \d+ More Albums/, 1]
    return "https://mbasic.facebook.com#{m}" unless m.nil?
  end

  def extract_albums(html)
    html.scan(/<a href="(\/.+?\/albums\/\d+\/)">(.*?)<\/a>/).map do |url, name|
      { url: "https://mbasic.facebook.com#{url}", name: name }
    end
  end

  def more_photos(html)
    m = html.gsub('&amp;', '&')[/<div class=".*?" id="m_more_item"><a href="(.*?)">/, 1]
    return "https://mbasic.facebook.com#{m}" unless m.nil?
  end

  def extract_photos(html)
    html.scan(/href="\/photo\.php\?fbid=(\d+)/).flatten
  end
end


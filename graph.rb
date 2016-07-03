require './scraper.rb'

def friends_graph(user, cookies)
  s = Scraper.new(cookies[:user], cookies[:auth])
  friends = s.get_friends(user[:id])

  friends_of_friends = friends.map do |f|
    { :name    => f[:name],
      :friends => s.get_mutual_friends(user[:id], f[:id])
    }
  end

  friends_of_friends.push({ :name => user[:name], :friends => friends })

  edges = friends_of_friends.map do |ff|
    [
      "\t\"#{ff[:name]}\"", '--', '{',
      ff[:friends].map{ |f| "\"#{f[:name]}\"" }.join("\s"),
      '};'
    ].join("\s")
  end

  return ["strict graph \"#{user[:name]} friends\" {", edges.join("\n"), '}'].join("\n")
end


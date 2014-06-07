require './lib/notary/client'

c = Notary::Client.new(['http://naven.local:4567'])
c.get('ponape')

20.times {
  c.replies << JSON.parse(c.replies.first.to_json)
  c.replies.last = "49F707A1CB366C580E625B3C456032D717A4CD9#{[1,2,3].sample}"
}

binding.pry

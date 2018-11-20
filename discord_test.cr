require "./src/**"
require "kemal"

redirect_uri = "http://127.0.0.1:3000/auth/callback"

MultiAuth.config("discord", ENV["CLIENT_ID"], ENV["CLIENT_SECRET"])

auth = MultiAuth.make("discord", redirect_uri)

get "/auth/" do |env|
  env.redirect(auth.authorize_uri("identify"))
end

get "/auth/callback" do |env|
  user = auth.user(env.params.query)
  pp user
end

Kemal.run

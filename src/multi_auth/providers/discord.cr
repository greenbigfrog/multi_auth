class MultiAuth::Provider::Discord < MultiAuth::Provider
  def authorize_uri(scope = nil)
    client.get_authorize_uri(scope)
  end

  def user(params : Hash(String, String))
    discord_user = fetch_discord_user(params["code"])

    User.new(
      "discord",
      discord_user.id,
      discord_user.username,
      discord_user.raw_json.to_s,
      discord_user.access_token.not_nil!
    ).tap do |buser|
      buser.email = discord_user.email
    end
  end

  private class DiscordUser
    # https://discordapp.com/developers/docs/resources/user#user-object
    property raw_json : String?
    property access_token : OAuth2::AccessToken?

    JSON.mapping(
      id: {type: String, converter: String::RawConverter},
      username: String,
      discriminator: String,
      avatar: String?,
      email: String?,
      bot: Bool?,
      mfa_enabled: Bool?,
      verified: Bool?,
      locale: String?
    )
  end

  private def fetch_discord_user(code)
    access_token = client.get_access_token_using_authorization_code(code)

    client = HTTP::Client.new("discordapp.com", tls: true)
    access_token.authenticate(client)

    raw_json = client.get("/api/users/@me").body

    DiscordUser.from_json(raw_json).tap do |user|
      user.access_token = access_token
      user.raw_json = raw_json
    end
  end

  private def consumer
    @consumer ||= OAuth::Consumer.new("discordapp.com", key, secret)
  end

  private def client
    OAuth2::Client.new(
      "discordapp.com",
      key,
      secret,
      authorize_uri: "/api/oauth2/authorize",
      token_uri: "/api/oauth2/token",
      redirect_uri: redirect_uri
    )
  end
end

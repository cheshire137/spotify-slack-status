# spotify-slack-status

Update your Slack status based on the track currently playing in Spotify.

## How to Develop

You will need PostgreSQL, Bundler, RubyGems, and Ruby installed.

Create a [Spotify app](https://developer.spotify.com/my-applications/#!/).
Add `http://localhost:9292/callback/spotify` as a redirect URI.

Create a [Slack app](https://api.slack.com/apps). Add
`http://localhost:9292/callback/slack` as a redirect URI.

```bash
bundle install
cp dotenv.sample .env
```

Edit .env to set your Spotify and Slack client IDs and secrets. Run
`rake generate:secret` and put the output of that as the `SESSION_SECRET`
value in your `.env`.

```bash
createdb spotify_slack_status_dev
rake db:migrate
rackup
open http://localhost:9292/
```

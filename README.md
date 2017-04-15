# Spotify Slack Status

Update your Slack status based on the track currently playing in Spotify.

You can update your status in two ways:

- Once you've deployed your app to Heroku (see below), visit
  `https://your-heroku-app.herokuapp.com/` to sign in with Spotify and
  Slack, then hit "Update Slack Status".
- Once you have installed the app into your team's Slack, you can run
  the command `/spotify-status` from within Slack.

## How to Develop

You will need PostgreSQL, Bundler, RubyGems, and Ruby installed.

Create a [Spotify app](https://developer.spotify.com/my-applications/#!/).
Add `http://localhost:9292/callback/spotify` as a redirect URI.

Create a [Heroku app](https://dashboard.heroku.com/apps).

Create a [Slack app](https://api.slack.com/apps). Add
`http://localhost:9292/callback/slack` as a redirect URI. Set up a
"Slash Command" on your app with the name `/spotify-status` and
the request URL `https://your-heroku-app.herokuapp.com/command/spotify-status`.

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

## Deploying to Heroku

Set `https://your-heroku-app.herokuapp.com/callback/spotify`
as a redirect URI on your Spotify app. Set
`https://your-heroku-app.herokuapp.com/callback/slack` as a redirect
URI on your Slack app.

```bash
heroku git:remote -a your-heroku-app
git push heroku master
heroku run rake db:migrate
heroku restart
```

Set environment variables on your Heroku app via:

```bash
heroku config:set SPOTIFY_CLIENT_ID=
heroku config:set SPOTIFY_CLIENT_SECRET=
heroku config:set SLACK_CLIENT_ID=
heroku config:set SLACK_CLIENT_SECRET=
heroku config:set SLACK_VERIFICATION_TOKEN=
heroku config:set SESSION_SECRET=
```

# spotify-slack-status

Update your Slack status based on the track currently playing in Spotify.

## How to Develop

Create a [Spotify app](https://developer.spotify.com/my-applications/#!/).
Add `http://localhost:9292/callback/spotify` as a redirect URI.

```bash
bundle install
cp dotenv.sample .env
```

Edit .env to set your Spotify app client ID.

```bash
rackup
open http://localhost:9292/
```

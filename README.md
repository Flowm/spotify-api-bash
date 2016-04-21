# Spotify API bash utils
Some small scripts to quickly communicate with the spotify web api

## create_playlist_from_artists.sh
Creates a spotify playlist from the top tracks of a list of artists.

Useful for easily creating festival playlists with the top 10 tracks of each artist by pasting the list of artists to a file and invoking the script.

### Usage
* Obtain Auth token
```
Open this URL to obtain the auth token:
https://accounts.spotify.com/authorize?client_id=109e36592e9c471bb5bb15a83a4a78de&response_type=token&redirect_uri=http%3A%2F%2Flocalhost%3A9876&scope=playlist-modify-private

Obtain the access_token from the redirected URI. Example URI:
http://localhost:9876/#access_token=XXYOURTOKENHEREXX&token_type=Bearer&expires_in=3600
```

* Invoke the script with a file containing a list of artists separated by newlines
```
./create_playlist_from_artists.sh <filename>
```

## Requirements
* [jq](https://github.com/stedolan/jq) - For json parsing
* [curl](https://curl.haxx.se/) - For web requests

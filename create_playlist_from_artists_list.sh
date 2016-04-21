#!/usr/bin/env bash
set -eu

# Creates a spotify playlist from the top tracks of a list of artist read from a file
# Usage: ./create_playlist_from_artists.sh <filename>
# Requires: curl and jq

# Open this URL to obtain the auth token:
#	https://accounts.spotify.com/authorize?client_id=109e36592e9c471bb5bb15a83a4a78de&response_type=token&redirect_uri=http%3A%2F%2Flocalhost%3A9876&scope=playlist-modify-private
# Obtain the access_token from the redirected URI
#	Example URI: http://localhost:9876/#access_token=XXYOURTOKENHEREXX&token_type=Bearer&expires_in=3600
access_token=""


# Internal settings
client_id="109e36592e9c471bb5bb15a83a4a78de"
country="DE"
headers=(-H "Accept application/json" -H "Authorization: Bearer ${access_token}" )
user_id=$(curl -s -X GET "https://api.spotify.com/v1/me" "${headers[@]}" | jq -r ".id")


get_artist_id() {
	# Get the first artist from search
	curl -s -X GET "https://api.spotify.com/v1/search" -G --data-urlencode "q=$1" --data-urlencode "type=artist" --data-urlencode "limit=1" -H "Accept: application/json" | jq -r ".artists.items[0]?.id?"
}

get_tracks_from_artist() {
	# Get the top 10 tracks from an artist
	if [ -z "$1" ] || [ "$1" == "null" ]; then
		return
	fi
	curl -s -X GET "https://api.spotify.com/v1/artists/$1/top-tracks?country=$country" -H "Accept: application/json" | jq -r ".tracks[].id"
}

get_artists_top_tracks() {
	# Reads the list of artists from file and obtains the top track_ids of each artist
	filename=$1
	tracks=""

	while read artist; do
		echo "$artist"
		artist_id=$(get_artist_id "$artist")
		artist_tracks=$(get_tracks_from_artist $artist_id)
		echo "$artist_tracks"
		tracks=$(echo -e "$tracks\n$artist_tracks")
		sleep 1
	done < $filename
	echo $tracks > "$filename-tracks"
}

create_playlist() {
	# Creates a new private playlist
	name=$1
	curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists" --data "{\"name\":\"$name\", \"public\":false}" "${headers[@]}" | jq -r ".id"
}

add_tracks_to_playlist() {
	# Add track_ids from a file to a playlist_id
	filename=$1
	playlist=$2
	count=1
	trackuris=""

	for track in $(cat $filename-tracks); do
		if [ $count -lt 10 ]; then
			trackuris="${trackuris}spotify:track:$track,"
			count=$(expr $count + 1)
		else
			trackuris="${trackuris}spotify:track:$track"
			echo $trackuris
			curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}"
			trackuris=""
			count=1
			sleep 1
		fi
	done
	if [ -n "$trackuris" ]; then
		curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}"
	fi
}


run() {
	filename=$1

	get_artists_top_tracks $filename
	playlist=$(create_playlist $(basename $filename))
	add_tracks_to_playlist $filename $playlist
	rm $filename-tracks
}

if [ -z "$access_token" ]; then
	echo "Please enter your access token in the script"
	exit 1
fi
if [ -z "$1" ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi
run $1

data "http" "o" {
  url = "https://api.heardle.app/api/o"
}

locals {
  json = jsondecode(data.http.o.body)
  o    = local.json.o
  artist_title = merge(flatten([
    for a in local.o : [
      for s in a.songs : { "${a.artist} - ${s}" = {
        artist = a.artist
        title  = s
        }
      }
    ]
  ])...)
}

output "debug2" {
  value = local.artist_title
}

data "spotify_search_track" "candidate" {
  for_each = local.artist_title
  artist   = each.value.artist
  name     = each.value.title
}


resource "spotify_playlist" "playlist" {
  name        = "Heardle Study Guide"
  description = "I was tired of losing Heardle. Updates nightly."
  public      = true

  // TODO don't be case sensitive when sorting by artist - title
  tracks = [for s in sort(keys(data.spotify_search_track.candidate)) : data.spotify_search_track.candidate[s].tracks[0].id if length(data.spotify_search_track.candidate[s].tracks) > 0]
}

output "lost_songs" {
  value = [for s in data.spotify_search_track.candidate : "${s.artist} - ${s.name}" if length(s.tracks) == 0]
}

output "playlist_url" {
  value       = "https://open.spotify.com/playlist/${spotify_playlist.playlist.id}"
  description = "Visit this URL in your browser to listen to the playlist"
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  property var currentPlayer: null
  readonly property var available: Mpris.players.values.filter(player =>
      [clean(player.trackTitle),
       clean(player.trackArtist) || clean(player.trackAlbum),
       clean(player.trackArtUrl)].filter(field => field !== "").length >= 2)
  readonly property var playing: available.filter(player => player.isPlaying)
  readonly property bool anyPlaying: Mpris.players.values.some(player => player.isPlaying)
  readonly property bool hasPlayer: currentPlayer !== null && (anyPlaying || hideDelay.running)
  readonly property bool isPlaying: currentPlayer?.isPlaying ?? false
  readonly property string title: clean(currentPlayer?.trackTitle)
  readonly property string subtitle: {
    const artist = clean(currentPlayer?.trackArtist);
    const album = clean(currentPlayer?.trackAlbum);
    return [album, artist].filter(text => text !== "").join(" • ");
  }
  readonly property string artUrl: currentPlayer?.trackArtUrl ?? ""
  readonly property string identity: currentPlayer?.identity || currentPlayer?.desktopEntry || ""
  readonly property bool canPlayPause: currentPlayer
      ? (isPlaying ? currentPlayer.canPause : currentPlayer.canPlay) : false
  readonly property bool canNext: currentPlayer?.canGoNext ?? false
  readonly property bool canPrevious: currentPlayer?.canGoPrevious ?? false

  onAvailableChanged: selectPlayer()
  onPlayingChanged: selectPlayer()
  onAnyPlayingChanged: {
    if (anyPlaying) hideDelay.stop();
    else hideDelay.restart();
  }

  Timer {
    id: hideDelay
    interval: 10 * 60 * 1000
  }

  function clean(value) {
    return String(value || "").replace(/[\r\n]+/g, " ").trim();
  }

  function selectPlayer() {
    // Retain a paused track until another producer plays or it disappears.
    currentPlayer = playing[0] || (available.includes(currentPlayer)
        ? currentPlayer : available[0]) || null;
  }

  function playPause() {
    if (canPlayPause) currentPlayer.togglePlaying();
  }

  function next() {
    if (canNext) currentPlayer.next();
  }

  function previous() {
    if (canPrevious) currentPlayer.previous();
  }

  function shortcut(action) {
    // Hardware keys must also work for players without enough metadata to
    // show a sidebar card (for example, a video with only a title).
    const players = Mpris.players.values;
    const player = players.find(p => p.isPlaying) ||
        (players.includes(currentPlayer) ? currentPlayer : players[0]);
    if (!player) return;
    if (action === "playPause" && (player.isPlaying ? player.canPause : player.canPlay))
      player.togglePlaying();
    else if (action === "next" && player.canGoNext) player.next();
    else if (action === "previous" && player.canGoPrevious) player.previous();
  }
}

.pragma library
function rows(players) {
    return players.map(p => ({key: p.dbusName, label: p.trackTitle || p.identity,
        sub: p.trackArtist || '', state: p.isPlaying, icon: ''}));
}

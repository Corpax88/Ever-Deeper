"""Skip music gain writes only for the same request and unchanged player state."""
import hashlib,re
EXPECTED_SHA256='933ac6a2aa43499e6cbfda68343881867eac31af2516c45dc638668116f0fe4c'
RESOURCE='scripts/audio/audio_director.gd'

def transform(text):
    assert hashlib.sha256(text.encode()).hexdigest()==EXPECTED_SHA256
    text=text.replace('var _music_players: Array[AudioStreamPlayer] = []','var _music_players: Array[AudioStreamPlayer] = []\nvar _music_gain_requests: Dictionary = {}',1)
    count=0
    def replace(m):
        nonlocal count
        count+=1
        return m[1]+'_set_music_gain('+m[2]+', '+m[3]+')'
    text=re.sub(r'(?m)^(\t+)(active|music_player|player|_music_players\[[^\n]+?\])\.volume_db = ([^\n]+)$',replace,text)
    assert count==7,count
    return text+'''

# Requests are 64-bit GDScript floats; AudioStreamPlayer stores a 32-bit float.
# Retain both to avoid treating ordinary float rounding as a volume change.
# Checking the live value/bus also respects any later direct external edit.
func _set_music_gain(player: AudioStreamPlayer, requested: float) -> void:
\tif _music_gain_requests.has(player):
\t\tvar previous: Array = _music_gain_requests[player]
\t\tif previous[0] == requested and previous[1] == player.volume_db and previous[2] == player.bus:
\t\t\treturn
\tplayer.volume_db = requested
\t_music_gain_requests[player] = [requested, player.volume_db, player.bus]
'''

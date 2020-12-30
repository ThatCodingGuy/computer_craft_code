return {
  --protocols
  MUSIC_CLIENT_PROTOCOL='music_client',
  MUSIC_SERVER_PROTOCOL='music_server',

  --commands
  GET_MUSIC_STATE_COMMAND='get_music_state',
  STOP_COMMAND='stop',
  PLAY_COMMAND='play',
  INCREASE_SPEED_COMMAND='increase_speed',
  DECREASE_SPEED_COMMAND='decrease_speed',
  INCREASE_VOLUME_COMMAND='increase_volume',
  DECREASE_VOLUME_COMMAND='decrease_volume',

  --special responses
  TAPE_WRITE_PROGRESS_RESPONSE_TYPE='tape_write_progress',
  PLAYING_PROGRESS_RESPONSE_TYPE='playing_progress'
}
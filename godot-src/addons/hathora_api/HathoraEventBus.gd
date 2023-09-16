extends Node

#region       -- Auth
# V1
signal on_login_anonymous(response)
signal on_login_nickname(response)
signal on_login_google(response)
#endregion    -- Auth

#region       -- Room
# V2
## TODO: explain
signal on_create_room(response)
signal on_get_room_info(response)
signal on_get_active_rooms_for_process(response)
signal on_get_inactive_rooms_for_process(response)
signal on_destroy_room(response)
signal on_suspend_room(response)
signal _internal_get_connection_info(response)
signal on_get_connection_info(response)
#endregion    -- Room

#region       -- Lobby
# V2
signal on_create_lobby(response)
signal on_list_active_public_lobbies(response)
signal on_get_lobby_info(response)
signal on_set_lobby_state(response)
#endregion    -- Lobby

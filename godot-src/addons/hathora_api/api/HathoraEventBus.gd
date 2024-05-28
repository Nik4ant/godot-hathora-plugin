extends Node

#region app
signal on_get_apps_v1(response)
signal on_create_app_v1(response)
signal on_update_app_v1(response)
signal on_get_app_info_v1(response)
signal on_delete_app_v1(response)
#endregion

#region auth
signal on_login_anonymous_v1(response)
signal on_login_nickname_v1(response)
signal on_login_google_v1(response)
#endregion

#region billing
signal on_get_balance_v1(response)
signal on_get_payment_method_v1(response)
signal on_init_stripe_customer_portal_url_v1(response)
signal on_get_invoices_v1(response)
#endregion

#region build
signal on_get_builds_v1(response)
signal on_get_build_info_v1(response)
signal on_create_build_v1(response)
signal on_delete_build_v1(response)
#endregion

#region deployment
signal on_get_deployments_v1(response)
signal on_get_latest_deployment_v1(response)
signal on_get_deployment_info_v1(response)
signal on_create_deployment_v1(response)
#endregion

#region discovery
signal on_get_ping_service_endpoints_v1(response)
#endregion

#region lobby
signal on_create_lobby_v3(response)
signal on_list_active_public_lobbies_v3(response)
signal on_get_lobby_info_by_room_id_v3(response)
signal on_get_lobby_info_by_short_code_v3(response)
#endregion

#region log
signal on_get_logs_for_process_v1(response)
signal on_download_log_for_process_v1(response)
#endregion

#region management
signal on_send_verification_email_v1(response)
#endregion

#region metrics
signal on_get_metrics_v1(response)
#endregion

#region processes
signal on_get_process_info_v2(response)
signal on_get_latest_processes_v2(response)
signal on_stop_process_v2(response)
#endregion

#region room
signal on_create_room_v2(response)
signal on_get_room_info_v2(response)
signal on_get_active_rooms_for_process_v2(response)
signal on_get_inactive_rooms_for_process_v2(response)
signal on_destroy_room_v2(response)
signal on_suspend_room_v2(response)
signal on_get_connection_info_v2(response)
signal on_update_room_config_v2(response)
#endregion

#region orgtokens
signal on_get_org_tokens_v1(response)
signal on_create_org_token_v1(response)
signal on_revoke_org_token_v1(response)
#endregion


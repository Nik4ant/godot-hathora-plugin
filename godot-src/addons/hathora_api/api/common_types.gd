class Lobby:
	var initial_config: Dictionary
	var created_at_unix: int
	var created_by: String
	var visibility: String
	var region: String
	var room_id: String
	var app_id: String
	
	static func deserialize(data: Dictionary) -> Lobby:
		var result: Lobby = Lobby.new()
		assert(data.has("initialConfig"), "ASSERT! Missing parameter \"initialConfig\" in lobby's json")
		result.initial_config = data["initialConfig"]
		
		assert(data.has("createdAt"), "ASSERT! Missing parameter \"createdAt\" during json parsing in lobby creation")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "ASSERT! Missing parameter \"createdBy\" during json parsing in lobby creation")
		result.created_by = data["createdBy"]
		
		assert(data.has("visibility"), "ASSERT! Missing parameter \"visibility\" during json parsing in lobby creation")
		result.visibility = data["visibility"]
		
		assert(data.has("region"), "ASSERT! Missing parameter \"region\" during json parsing in lobby creation")
		result.region = data["region"]
		
		assert(data.has("roomId"), "ASSERT! Missing parameter \"roomId\" during json parsing in lobby creation")
		result.room_id = data["roomId"]
		
		assert(data.has("appId"), "ASSERT! Missing parameter \"appId\" during json parsing in lobby creation")
		result.app_id = data["appId"]
		
		return result


class ExposedPort:
	var host: String
	var name: String
	var port: int
	## tcp, udp or tls
	var transport_type: String
	
	static func deserialize(data: Dictionary) -> ExposedPort:
		var result: ExposedPort = ExposedPort.new()
		
		assert(data.has("host"), "ASSERT! Missing parameter \"host\" in exposedPort's json")
		result.host = data["host"]
		
		assert(data.has("name"), "ASSERT! Missing parameter \"name\" in exposedPort's json")
		result.name = data["name"]
		
		assert(data.has("port"), "ASSERT! Missing parameter \"port\" in exposedPort's json")
		result.port = int(data["port"])
		
		assert(data.has("transportType"), "ASSERT! Missing parameter \"transportType\" in exposedPort's json")
		result.transport_type = data["transportType"]
		
		return result


class RoomAllocation:
	## If room still exists equal 0 (by default) 
	var unscheduled_at_unix: int = 0
	var scheduled_at_unix: int
	var process_id: String
	var room_allocation_id: String
	
	static func deserialize(data: Dictionary) -> RoomAllocation:
		var result: RoomAllocation = RoomAllocation.new()
		
		if data.has("unscheduledAt"):
			result.unscheduled_at_unix = Time.get_unix_time_from_datetime_string(data["unscheduledAt"])
		
		assert(data.has("scheduledAt"), "ASSERT! Missing parameter \"scheduledAt\" in roomAllocation's json")
		result.scheduled_at_unix = Time.get_unix_time_from_datetime_string(data["scheduledAt"])
		
		assert(data.has("processId"), "ASSERT! Missing parameter \"processId\" in roomAllocation's json")
		result.process_id = data["processId"]
		
		assert(data.has("roomAllocationId"), "ASSERT! Missing parameter \"roomAllocationId\" in roomAllocation's json")
		result.room_allocation_id = data["roomAllocationId"]
		
		return result


class Room:
	var room_id: String
	var room_config: Dictionary
	var status: String
	var current_allocation: RoomAllocation
	
	static func deserialize(data: Dictionary) -> Room:
		var result: Room = Room.new()
		
		assert(data.has("status"), "ASSERT! Missing parameter \"status\" in get_room_info response")
		result.status = data["status"]
		
		if data.has("currentAllocation"):
			result.current_allocation = RoomAllocation.deserialize(data["current_allocation"])
		
		assert(data.has("roomConfig"), "ASSERT! Missing parameter \"roomConfig\" in get_room_info response")
		result.room_config = Hathora.Http.json_parse_or(data["roomConfig"], {})
		
		assert(data.has("roomId"), "ASSERT! Missing parameter \"roomId\" in get_room_info response")
		result.room_id = data["roomId"]
		
		return result


# TODO: TYPES BELOW DECLARED AS DUMMY TYPES
# (replace them with a real once later)
class AuthConfiguration:
	pass
class ApplicationWithDeployment:
	pass
class Invoice:
	pass
class LinkPaymentMethod:
	pass
class AchPaymentMethod:
	pass
class CardPaymentMethod:
	pass
class Build:
	pass
class Deployment:
	pass
class RoomWithoutAllocations:
	pass
class Process:
	pass
class ProcessWithRooms:
	pass
class LobbyV3:
	pass
class MetricValue:
	pass
class ContainerPort:
	pass

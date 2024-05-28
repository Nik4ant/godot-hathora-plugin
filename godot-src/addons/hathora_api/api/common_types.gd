## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
class AuthConfiguration:
	## Enable google auth for your application.
	## (optional)
	var google: Dictionary = {}
	## Construct a type with a set of properties K of type T
	## (optional)
	var nickname: Dictionary = {}
	## Construct a type with a set of properties K of type T
	## (optional)
	var anonymous: Dictionary = {}

	static func deserialize(data: Dictionary) -> AuthConfiguration:
		var result: AuthConfiguration
		
		if data.has("google"):
			result.google = data["google"]
		
		if data.has("nickname"):
			result.nickname = data["nickname"]
		
		if data.has("anonymous"):
			result.anonymous = data["anonymous"]
		
		return result


## An application object is the top level namespace for the game server.
class Application:
	## UserId or email address for the user that deleted the application.
	var deleted_by: String
	## When the application was deleted.
	var deleted_at_unix: int
	## When the application was created.
	var created_at_unix: int
	## UserId or email address for the user that created the application.
	var created_by: String
	## System generated unique identifier for an organization. Not guaranteed to have a specific format.
	var org_id: String
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Secret that is used for identity and access management.
	var app_secret: String
	## System generated unique identifier for an application.
	var app_id: String
	## Readable name for an application. Must be unique within an organization.
	var app_name: String

	static func deserialize(data: Dictionary) -> Application:
		var result: Application
		
		assert(data.has("deletedBy"), "Missing parameter \"deletedBy\"")
		result.deleted_by = data["deletedBy"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		result.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		result.org_id = data["orgId"]
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		result.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appSecret"), "Missing parameter \"appSecret\"")
		result.app_secret = data["appSecret"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		result.app_name = data["appName"]
		
		return result


## A container port object represents the transport configruations for how your server will listen.
class ContainerPort:
	## Transport type specifies the underlying communication protocol to the exposed port.
	var transport_type: String
	var port: int
	## Readable name for the port.
	var name: String

	static func deserialize(data: Dictionary) -> ContainerPort:
		var result: ContainerPort
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		result.transport_type = data["transportType"]
		
		assert(data.has("port"), "Missing parameter \"port\"")
		result.port = int(data["port"])
		
		assert(data.has("name"), "Missing parameter \"name\"")
		result.name = data["name"]
		
		return result


## Deployment is a versioned configuration for a build that describes runtime behavior.
class Deployment:
	## Option to shut down processes that have had no new connections or rooms
	## for five minutes.
	## (optional)
	var idle_timeout_enabled: bool = false
	## The environment variable that our process will have access to at runtime.
	var env: Array[Dictionary]
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	## A plan defines how much CPU and memory is required to run an instance of your game server.
	## `tiny`: shared core, 1gb memory
	## `small`: 1 core, 2gb memory
	## `medium`: 2 core, 4gb memory
	## `large`: 4 core, 8gb memory
	var plan_name: String
	## Additional ports your server listens on.
	var additional_container_ports: Array[ContainerPort]
	## A container port object represents the transport configruations for how your server will listen.
	var default_container_port: ContainerPort
	var transport_type: String
	var container_port: float
	## When the deployment was created.
	var created_at_unix: int
	## UserId or email address for the user that created the deployment.
	var created_by: String
	## The amount of memory allocated to your process.
	var requested_memory_mb: int
	## The number of cores allocated to your process.
	var requested_cpu: float
	## System generated id for a deployment. Increments by 1.
	var deployment_id: int
	## System generated id for a build. Increments by 1.
	var build_id: int
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> Deployment:
		var result: Deployment
		
		if data.has("idleTimeoutEnabled"):
			result.idle_timeout_enabled = data["idleTimeoutEnabled"]
		
		assert(data.has("env"), "Missing parameter \"env\"")
		for item: Dictionary in data["env"]:
			result.env.push_back(item)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		result.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		result.plan_name = data["planName"]
		
		assert(data.has("additionalContainerPorts"), "Missing parameter \"additionalContainerPorts\"")
		for item: Dictionary in data["additionalContainerPorts"]:
			result.additional_container_ports.push_back(ContainerPort.deserialize(item))
		
		assert(data.has("defaultContainerPort"), "Missing parameter \"defaultContainerPort\"")
		result.default_container_port = ContainerPort.deserialize(data["defaultContainerPort"])
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		result.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		result.container_port = float(data["containerPort"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("requestedMemoryMb"), "Missing parameter \"requestedMemoryMb\"")
		result.requested_memory_mb = int(data["requestedMemoryMb"])
		
		assert(data.has("requestedCpu"), "Missing parameter \"requestedCpu\"")
		result.requested_cpu = float(data["requestedCpu"])
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		result.deployment_id = int(data["deploymentId"])
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		result.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


## An application object is the top level namespace for the game server.
class ApplicationWithDeployment:
	## UserId or email address for the user that deleted the application.
	var deleted_by: String
	## When the application was deleted.
	var deleted_at_unix: int
	## When the application was created.
	var created_at_unix: int
	## UserId or email address for the user that created the application.
	var created_by: String
	## System generated unique identifier for an organization. Not guaranteed to have a specific format.
	var org_id: String
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Secret that is used for identity and access management.
	var app_secret: String
	## System generated unique identifier for an application.
	var app_id: String
	## Readable name for an application. Must be unique within an organization.
	var app_name: String
	## Deployment is a versioned configuration for a build that describes runtime behavior.
	## (optional)
	var deployment: Deployment = null

	static func deserialize(data: Dictionary) -> ApplicationWithDeployment:
		var result: ApplicationWithDeployment
		
		assert(data.has("deletedBy"), "Missing parameter \"deletedBy\"")
		result.deleted_by = data["deletedBy"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		result.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		result.org_id = data["orgId"]
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		result.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appSecret"), "Missing parameter \"appSecret\"")
		result.app_secret = data["appSecret"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		result.app_name = data["appName"]
		
		if data.has("deployment"):
			result.deployment = Deployment.deserialize(data["deployment"])
		
		return result


class AppConfig:
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Readable name for an application. Must be unique within an organization.
	var app_name: String

	static func deserialize(data: Dictionary) -> AppConfig:
		var result: AppConfig
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		result.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		result.app_name = data["appName"]
		
		return result


class ApiError:
	var message: String

	static func deserialize(data: Dictionary) -> ApiError:
		var result: ApiError
		
		assert(data.has("message"), "Missing parameter \"message\"")
		result.message = data["message"]
		
		return result


class CardPaymentMethod:
	var last_4: String
	var brand: String

	static func deserialize(data: Dictionary) -> CardPaymentMethod:
		var result: CardPaymentMethod
		
		assert(data.has("last4"), "Missing parameter \"last4\"")
		result.last_4 = data["last4"]
		
		assert(data.has("brand"), "Missing parameter \"brand\"")
		result.brand = data["brand"]
		
		return result


class AchPaymentMethod:
	## (optional)
	var last_4: String = ''
	## (optional)
	var bank_name: String = ''

	static func deserialize(data: Dictionary) -> AchPaymentMethod:
		var result: AchPaymentMethod
		
		if data.has("last4"):
			result.last_4 = data["last4"]
		
		if data.has("bankName"):
			result.bank_name = data["bankName"]
		
		return result


class LinkPaymentMethod:
	## (optional)
	var email: String = ''

	static func deserialize(data: Dictionary) -> LinkPaymentMethod:
		var result: LinkPaymentMethod
		
		if data.has("email"):
			result.email = data["email"]
		
		return result


## Make all properties in T optional
class PaymentMethod:
	## (optional)
	var card: CardPaymentMethod = null
	## (optional)
	var ach: AchPaymentMethod = null
	## (optional)
	var link: LinkPaymentMethod = null

	static func deserialize(data: Dictionary) -> PaymentMethod:
		var result: PaymentMethod
		
		if data.has("card"):
			result.card = CardPaymentMethod.deserialize(data["card"])
		
		if data.has("ach"):
			result.ach = AchPaymentMethod.deserialize(data["ach"])
		
		if data.has("link"):
			result.link = LinkPaymentMethod.deserialize(data["link"])
		
		return result


class CustomerPortalUrl:
	var return_url: String

	static func deserialize(data: Dictionary) -> CustomerPortalUrl:
		var result: CustomerPortalUrl
		
		assert(data.has("returnUrl"), "Missing parameter \"returnUrl\"")
		result.return_url = data["returnUrl"]
		
		return result


class Invoice:
	var status: String
	var amount_due: float
	var pdf_url: String
	var due_date_unix: int
	var year: float
	var month: float
	var id: String

	static func deserialize(data: Dictionary) -> Invoice:
		var result: Invoice
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("amountDue"), "Missing parameter \"amountDue\"")
		result.amount_due = float(data["amountDue"])
		
		assert(data.has("pdfUrl"), "Missing parameter \"pdfUrl\"")
		result.pdf_url = data["pdfUrl"]
		
		assert(data.has("dueDate"), "Missing parameter \"dueDate\"")
		result.due_date_unix = Time.get_unix_time_from_datetime_string(data["dueDate"])
		
		assert(data.has("year"), "Missing parameter \"year\"")
		result.year = float(data["year"])
		
		assert(data.has("month"), "Missing parameter \"month\"")
		result.month = float(data["month"])
		
		assert(data.has("id"), "Missing parameter \"id\"")
		result.id = data["id"]
		
		return result


## A build represents a game server artifact and its associated metadata.
class Build:
	## Tag to associate an external version with a build. It is accessible via [`GetBuildInfo()`](https://hathora.dev/api#tag/BuildV1/operation/GetBuildInfo).
	var build_tag: String
	var regional_container_tags: Array[Dictionary]
	## The size (in bytes) of the Docker image built by Hathora.
	var image_size: int
	## Current status of your build.
	## `created`: a build was created but not yet run
	## `running`: the build process is actively executing
	## `succeeded`: the game server artifact was successfully built and stored in the Hathora registries
	## `failed`: the build process was unsuccessful, most likely due to an error with the `Dockerfile`
	var status: String
	## When the build was deleted.
	var deleted_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) finished executing.
	var finished_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) is called.
	var started_at_unix: int
	## When [`CreateBuild()`](https://hathora.dev/api#tag/BuildV1/operation/CreateBuild) is called.
	var created_at_unix: int
	## UserId or email address for the user that created the build.
	var created_by: String
	## System generated id for a build. Increments by 1.
	var build_id: int
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> Build:
		var result: Build
		
		assert(data.has("buildTag"), "Missing parameter \"buildTag\"")
		result.build_tag = data["buildTag"]
		
		assert(data.has("regionalContainerTags"), "Missing parameter \"regionalContainerTags\"")
		for item: Dictionary in data["regionalContainerTags"]:
			result.regional_container_tags.push_back(item)
		
		assert(data.has("imageSize"), "Missing parameter \"imageSize\"")
		result.image_size = int(data["imageSize"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		result.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("finishedAt"), "Missing parameter \"finishedAt\"")
		result.finished_at_unix = Time.get_unix_time_from_datetime_string(data["finishedAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		result.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		result.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


## User specified deployment configuration for your application at runtime.
class DeploymentConfig:
	## Option to shut down processes that have had no new connections or rooms
	## for five minutes.
	## (optional)
	var idle_timeout_enabled: bool = false
	## The environment variable that our process will have access to at runtime.
	var env: Array[Dictionary]
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	## A plan defines how much CPU and memory is required to run an instance of your game server.
	## `tiny`: shared core, 1gb memory
	## `small`: 1 core, 2gb memory
	## `medium`: 2 core, 4gb memory
	## `large`: 4 core, 8gb memory
	var plan_name: String
	## Additional ports your server listens on.
	## (optional)
	var additional_container_ports: Array[ContainerPort] = []
	## Transport type specifies the underlying communication protocol to the exposed port.
	var transport_type: String
	## Default port the server listens on.
	var container_port: int

	static func deserialize(data: Dictionary) -> DeploymentConfig:
		var result: DeploymentConfig
		
		if data.has("idleTimeoutEnabled"):
			result.idle_timeout_enabled = data["idleTimeoutEnabled"]
		
		assert(data.has("env"), "Missing parameter \"env\"")
		for item: Dictionary in data["env"]:
			result.env.push_back(item)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		result.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		result.plan_name = data["planName"]
		
		if data.has("additionalContainerPorts"):
			for item: Dictionary in data["additionalContainerPorts"]:
				result.additional_container_ports.push_back(ContainerPort.deserialize(item))
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		result.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		result.container_port = int(data["containerPort"])
		
		return result


## A lobby object allows you to store and manage metadata for your rooms.
class Lobby:
	## User-defined identifier for a lobby.
	var short_code: String
	## JSON blob to store metadata for a room. Must be smaller than 1MB.
	## (optional)
	var state: Dictionary = {}
	## User input to initialize the game state. Object must be smaller than 64KB.
	var initial_config: Dictionary
	## When the lobby was created.
	var created_at_unix: int
	## UserId or email address for the user that created the lobby.
	var created_by: String
	var local: bool
	## Types of lobbies a player can create.
	## `private`: the player who created the room must share the roomId with their friends
	## `public`: visible in the public lobby list, anyone can join
	## `local`: for testing with a server running locally
	var visibility: String
	var region: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> Lobby:
		var result: Lobby
		
		assert(data.has("shortCode"), "Missing parameter \"shortCode\"")
		result.short_code = data["shortCode"]
		
		if data.has("state"):
			result.state = data["state"]
		
		assert(data.has("initialConfig"), "Missing parameter \"initialConfig\"")
		result.initial_config = data["initialConfig"]
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("local"), "Missing parameter \"local\"")
		result.local = data["local"]
		
		assert(data.has("visibility"), "Missing parameter \"visibility\"")
		result.visibility = data["visibility"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		result.region = data["region"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


## A lobby object allows you to store and manage metadata for your rooms.
class LobbyV3:
	## User-defined identifier for a lobby.
	var short_code: String
	## When the lobby was created.
	var created_at_unix: int
	## UserId or email address for the user that created the lobby.
	var created_by: String
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Types of lobbies a player can create.
	## `private`: the player who created the room must share the roomId with their friends
	## `public`: visible in the public lobby list, anyone can join
	## `local`: for testing with a server running locally
	var visibility: String
	var region: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> LobbyV3:
		var result: LobbyV3
		
		assert(data.has("shortCode"), "Missing parameter \"shortCode\"")
		result.short_code = data["shortCode"]
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		result.room_config = data["roomConfig"]
		
		assert(data.has("visibility"), "Missing parameter \"visibility\"")
		result.visibility = data["visibility"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		result.region = data["region"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


class MetricValue:
	var value: float
	var timestamp: float

	static func deserialize(data: Dictionary) -> MetricValue:
		var result: MetricValue
		
		assert(data.has("value"), "Missing parameter \"value\"")
		result.value = float(data["value"])
		
		assert(data.has("timestamp"), "Missing parameter \"timestamp\"")
		result.timestamp = float(data["timestamp"])
		
		return result


## Connection details for an active process.
class ExposedPort:
	## Transport type specifies the underlying communication protocol to the exposed port.
	var transport_type: String
	var port: int
	var host: String
	var name: String

	static func deserialize(data: Dictionary) -> ExposedPort:
		var result: ExposedPort
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		result.transport_type = data["transportType"]
		
		assert(data.has("port"), "Missing parameter \"port\"")
		result.port = int(data["port"])
		
		assert(data.has("host"), "Missing parameter \"host\"")
		result.host = data["host"]
		
		assert(data.has("name"), "Missing parameter \"name\"")
		result.name = data["name"]
		
		return result


## A process object represents a runtime instance of your game server and its metadata.
class Process:
	## Measures network traffic leaving the process in bytes.
	var egressed_bytes: int
	var idle_since_unix: int
	var active_connections_updated_at_unix: int
	## Tracks the number of active connections to a process.
	var active_connections: int
	var rooms_allocated_updated_at_unix: int
	## Tracks the number of rooms that have been allocated to the process.
	var rooms_allocated: int
	var room_slots_available_updated_at_unix: int
	var room_slots_available: float
	## Process in drain will not accept any new rooms.
	var draining: bool
	## When the process has been terminated.
	var terminated_at_unix: int
	## When the process is issued to stop. We use this to determine when we should stop billing.
	var stopping_at_unix: int
	## When the process bound to the specified port. We use this to determine when we should start billing.
	var started_at_unix: int
	## When the process started being provisioned.
	var starting_at_unix: int
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	var exposed_port: ExposedPort
	var port: float
	var host: String
	var region: String
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String
	## System generated id for a deployment. Increments by 1.
	var deployment_id: int
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> Process:
		var result: Process
		
		assert(data.has("egressedBytes"), "Missing parameter \"egressedBytes\"")
		result.egressed_bytes = int(data["egressedBytes"])
		
		assert(data.has("idleSince"), "Missing parameter \"idleSince\"")
		result.idle_since_unix = Time.get_unix_time_from_datetime_string(data["idleSince"])
		
		assert(data.has("activeConnectionsUpdatedAt"), "Missing parameter \"activeConnectionsUpdatedAt\"")
		result.active_connections_updated_at_unix = Time.get_unix_time_from_datetime_string(data["activeConnectionsUpdatedAt"])
		
		assert(data.has("activeConnections"), "Missing parameter \"activeConnections\"")
		result.active_connections = int(data["activeConnections"])
		
		assert(data.has("roomsAllocatedUpdatedAt"), "Missing parameter \"roomsAllocatedUpdatedAt\"")
		result.rooms_allocated_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomsAllocatedUpdatedAt"])
		
		assert(data.has("roomsAllocated"), "Missing parameter \"roomsAllocated\"")
		result.rooms_allocated = int(data["roomsAllocated"])
		
		assert(data.has("roomSlotsAvailableUpdatedAt"), "Missing parameter \"roomSlotsAvailableUpdatedAt\"")
		result.room_slots_available_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomSlotsAvailableUpdatedAt"])
		
		assert(data.has("roomSlotsAvailable"), "Missing parameter \"roomSlotsAvailable\"")
		result.room_slots_available = float(data["roomSlotsAvailable"])
		
		assert(data.has("draining"), "Missing parameter \"draining\"")
		result.draining = data["draining"]
		
		assert(data.has("terminatedAt"), "Missing parameter \"terminatedAt\"")
		result.terminated_at_unix = Time.get_unix_time_from_datetime_string(data["terminatedAt"])
		
		assert(data.has("stoppingAt"), "Missing parameter \"stoppingAt\"")
		result.stopping_at_unix = Time.get_unix_time_from_datetime_string(data["stoppingAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		result.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("startingAt"), "Missing parameter \"startingAt\"")
		result.starting_at_unix = Time.get_unix_time_from_datetime_string(data["startingAt"])
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		result.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			result.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		result.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("port"), "Missing parameter \"port\"")
		result.port = float(data["port"])
		
		assert(data.has("host"), "Missing parameter \"host\"")
		result.host = data["host"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		result.region = data["region"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		result.process_id = data["processId"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		result.deployment_id = int(data["deploymentId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


## Metadata on an allocated instance of a room.
class RoomAllocation:
	var unscheduled_at_unix: int
	var scheduled_at_unix: int
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String
	## System generated unique identifier to an allocated instance of a room.
	var room_allocation_id: String

	static func deserialize(data: Dictionary) -> RoomAllocation:
		var result: RoomAllocation
		
		assert(data.has("unscheduledAt"), "Missing parameter \"unscheduledAt\"")
		result.unscheduled_at_unix = Time.get_unix_time_from_datetime_string(data["unscheduledAt"])
		
		assert(data.has("scheduledAt"), "Missing parameter \"scheduledAt\"")
		result.scheduled_at_unix = Time.get_unix_time_from_datetime_string(data["scheduledAt"])
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		result.process_id = data["processId"]
		
		assert(data.has("roomAllocationId"), "Missing parameter \"roomAllocationId\"")
		result.room_allocation_id = data["roomAllocationId"]
		
		return result


## From T, pick a set of properties whose keys are in the union K
class RoomWithoutAllocations:
	## System generated unique identifier for an application.
	var app_id: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## The allocation status of a room.
	## `scheduling`: a process is not allocated yet and the room is waiting to be scheduled
	## `active`: ready to accept connections
	## `suspended`: room is unallocated from the process but can be rescheduled later with the same `roomId`
	## `destroyed`: all associated metadata is deleted
	var status: String
	## Metadata on an allocated instance of a room.
	var current_allocation: RoomAllocation

	static func deserialize(data: Dictionary) -> RoomWithoutAllocations:
		var result: RoomWithoutAllocations
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		result.room_config = data["roomConfig"]
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("currentAllocation"), "Missing parameter \"currentAllocation\"")
		result.current_allocation = RoomAllocation.deserialize(data["currentAllocation"])
		
		return result


## A process object represents a runtime instance of your game server and its metadata.
class ProcessWithRooms:
	## Measures network traffic leaving the process in bytes.
	var egressed_bytes: int
	var idle_since_unix: int
	var active_connections_updated_at_unix: int
	## Tracks the number of active connections to a process.
	var active_connections: int
	var rooms_allocated_updated_at_unix: int
	## Tracks the number of rooms that have been allocated to the process.
	var rooms_allocated: int
	var room_slots_available_updated_at_unix: int
	var room_slots_available: float
	## Process in drain will not accept any new rooms.
	var draining: bool
	## When the process has been terminated.
	var terminated_at_unix: int
	## When the process is issued to stop. We use this to determine when we should stop billing.
	var stopping_at_unix: int
	## When the process bound to the specified port. We use this to determine when we should start billing.
	var started_at_unix: int
	## When the process started being provisioned.
	var starting_at_unix: int
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	var exposed_port: ExposedPort
	var port: float
	var host: String
	var region: String
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String
	## System generated id for a deployment. Increments by 1.
	var deployment_id: int
	## System generated unique identifier for an application.
	var app_id: String
	var rooms: Array[RoomWithoutAllocations]
	var total_rooms: int

	static func deserialize(data: Dictionary) -> ProcessWithRooms:
		var result: ProcessWithRooms
		
		assert(data.has("egressedBytes"), "Missing parameter \"egressedBytes\"")
		result.egressed_bytes = int(data["egressedBytes"])
		
		assert(data.has("idleSince"), "Missing parameter \"idleSince\"")
		result.idle_since_unix = Time.get_unix_time_from_datetime_string(data["idleSince"])
		
		assert(data.has("activeConnectionsUpdatedAt"), "Missing parameter \"activeConnectionsUpdatedAt\"")
		result.active_connections_updated_at_unix = Time.get_unix_time_from_datetime_string(data["activeConnectionsUpdatedAt"])
		
		assert(data.has("activeConnections"), "Missing parameter \"activeConnections\"")
		result.active_connections = int(data["activeConnections"])
		
		assert(data.has("roomsAllocatedUpdatedAt"), "Missing parameter \"roomsAllocatedUpdatedAt\"")
		result.rooms_allocated_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomsAllocatedUpdatedAt"])
		
		assert(data.has("roomsAllocated"), "Missing parameter \"roomsAllocated\"")
		result.rooms_allocated = int(data["roomsAllocated"])
		
		assert(data.has("roomSlotsAvailableUpdatedAt"), "Missing parameter \"roomSlotsAvailableUpdatedAt\"")
		result.room_slots_available_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomSlotsAvailableUpdatedAt"])
		
		assert(data.has("roomSlotsAvailable"), "Missing parameter \"roomSlotsAvailable\"")
		result.room_slots_available = float(data["roomSlotsAvailable"])
		
		assert(data.has("draining"), "Missing parameter \"draining\"")
		result.draining = data["draining"]
		
		assert(data.has("terminatedAt"), "Missing parameter \"terminatedAt\"")
		result.terminated_at_unix = Time.get_unix_time_from_datetime_string(data["terminatedAt"])
		
		assert(data.has("stoppingAt"), "Missing parameter \"stoppingAt\"")
		result.stopping_at_unix = Time.get_unix_time_from_datetime_string(data["stoppingAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		result.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("startingAt"), "Missing parameter \"startingAt\"")
		result.starting_at_unix = Time.get_unix_time_from_datetime_string(data["startingAt"])
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		result.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			result.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		result.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("port"), "Missing parameter \"port\"")
		result.port = float(data["port"])
		
		assert(data.has("host"), "Missing parameter \"host\"")
		result.host = data["host"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		result.region = data["region"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		result.process_id = data["processId"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		result.deployment_id = int(data["deploymentId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		assert(data.has("rooms"), "Missing parameter \"rooms\"")
		for item: Dictionary in data["rooms"]:
			result.rooms.push_back(RoomWithoutAllocations.deserialize(item))
		
		assert(data.has("totalRooms"), "Missing parameter \"totalRooms\"")
		result.total_rooms = int(data["totalRooms"])
		
		return result


class ProcessV2:
	var status: String
	## Tracks the number of rooms that have been allocated to the process.
	var rooms_allocated: int
	## When the process has been terminated.
	var terminated_at_unix: int
	## When the process is issued to stop. We use this to determine when we should stop billing.
	var stopping_at_unix: int
	## When the process bound to the specified port. We use this to determine when we should start billing.
	var started_at_unix: int
	## When the process started being provisioned.
	var created_at_unix: int
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	var exposed_port: ExposedPort
	var region: String
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String
	## System generated id for a deployment. Increments by 1.
	var deployment_id: int
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> ProcessV2:
		var result: ProcessV2
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("roomsAllocated"), "Missing parameter \"roomsAllocated\"")
		result.rooms_allocated = int(data["roomsAllocated"])
		
		assert(data.has("terminatedAt"), "Missing parameter \"terminatedAt\"")
		result.terminated_at_unix = Time.get_unix_time_from_datetime_string(data["terminatedAt"])
		
		assert(data.has("stoppingAt"), "Missing parameter \"stoppingAt\"")
		result.stopping_at_unix = Time.get_unix_time_from_datetime_string(data["stoppingAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		result.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		result.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			result.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		result.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("region"), "Missing parameter \"region\"")
		result.region = data["region"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		result.process_id = data["processId"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		result.deployment_id = int(data["deploymentId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


## A room object represents a game session or match.
class Room:
	## Metadata on an allocated instance of a room.
	var current_allocation: RoomAllocation
	## The allocation status of a room.
	## `scheduling`: a process is not allocated yet and the room is waiting to be scheduled
	## `active`: ready to accept connections
	## `suspended`: room is unallocated from the process but can be rescheduled later with the same `roomId`
	## `destroyed`: all associated metadata is deleted
	var status: String
	var allocations: Array[RoomAllocation]
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	static func deserialize(data: Dictionary) -> Room:
		var result: Room
		
		assert(data.has("currentAllocation"), "Missing parameter \"currentAllocation\"")
		result.current_allocation = RoomAllocation.deserialize(data["currentAllocation"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("allocations"), "Missing parameter \"allocations\"")
		for item: Dictionary in data["allocations"]:
			result.allocations.push_back(RoomAllocation.deserialize(item))
		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		result.room_config = data["roomConfig"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		result.app_id = data["appId"]
		
		return result


class StartingConnectionInfo:
	var status: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String

	static func deserialize(data: Dictionary) -> StartingConnectionInfo:
		var result: StartingConnectionInfo
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		return result


class ActiveConnectionInfo:
	var status: String
	## Transport type specifies the underlying communication protocol to the exposed port.
	var transport_type: String
	var port: float
	var host: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String

	static func deserialize(data: Dictionary) -> ActiveConnectionInfo:
		var result: ActiveConnectionInfo
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		result.transport_type = data["transportType"]
		
		assert(data.has("port"), "Missing parameter \"port\"")
		result.port = float(data["port"])
		
		assert(data.has("host"), "Missing parameter \"host\"")
		result.host = data["host"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		return result


class ConnectionInfo:
	var status: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String

	static func deserialize(data: Dictionary) -> ConnectionInfo:
		var result: ConnectionInfo
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		return result


## Connection information for the default and additional ports.
class ConnectionInfoV2:
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	## (optional)
	var exposed_port: ExposedPort = null
	## `exposedPort` will only be available when the `status` of a room is "active".
	var status: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String

	static func deserialize(data: Dictionary) -> ConnectionInfoV2:
		var result: ConnectionInfoV2
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			result.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		if data.has("exposedPort"):
			result.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		result.room_id = data["roomId"]
		
		return result


class OrgToken:
	var created_at_unix: int
	var created_by: String
	var last_four_chars_of_key: String
	var status: String
	## Readable name for a token. Must be unique within an organization.
	var name: String
	var org_id: String
	## System generated unique identifier for an organization token.
	var org_token_id: String

	static func deserialize(data: Dictionary) -> OrgToken:
		var result: OrgToken
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		result.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		result.created_by = data["createdBy"]
		
		assert(data.has("lastFourCharsOfKey"), "Missing parameter \"lastFourCharsOfKey\"")
		result.last_four_chars_of_key = data["lastFourCharsOfKey"]
		
		assert(data.has("status"), "Missing parameter \"status\"")
		result.status = data["status"]
		
		assert(data.has("name"), "Missing parameter \"name\"")
		result.name = data["name"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		result.org_id = data["orgId"]
		
		assert(data.has("orgTokenId"), "Missing parameter \"orgTokenId\"")
		result.org_token_id = data["orgTokenId"]
		
		return result


class ListOrgTokens:
	var tokens: Array[OrgToken]

	static func deserialize(data: Dictionary) -> ListOrgTokens:
		var result: ListOrgTokens
		
		assert(data.has("tokens"), "Missing parameter \"tokens\"")
		for item: Dictionary in data["tokens"]:
			result.tokens.push_back(OrgToken.deserialize(item))
		
		return result


class CreatedOrgToken:
	var plain_text_token: String
	var org_token: OrgToken

	static func deserialize(data: Dictionary) -> CreatedOrgToken:
		var result: CreatedOrgToken
		
		assert(data.has("plainTextToken"), "Missing parameter \"plainTextToken\"")
		result.plain_text_token = data["plainTextToken"]
		
		assert(data.has("orgToken"), "Missing parameter \"orgToken\"")
		result.org_token = OrgToken.deserialize(data["orgToken"])
		
		return result


class CreateOrgToken:
	## Readable name for a token. Must be unique within an organization.
	var name: String

	static func deserialize(data: Dictionary) -> CreateOrgToken:
		var result: CreateOrgToken
		
		assert(data.has("name"), "Missing parameter \"name\"")
		result.name = data["name"]
		
		return result



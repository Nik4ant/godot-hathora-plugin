# Deployment v1
const ContainerPort = preload("res://addons/hathora_api/api/common_types.gd").ContainerPort
const Deployment = preload("res://addons/hathora_api/api/common_types.gd").Deployment
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_deployments
class GetDeploymentsResponse:
	var result: Array[Deployment]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(Deployment.deserialize(item))


static func get_deployments_async() -> GetDeploymentsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetDeploymentsResponse = GetDeploymentsResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/list".format({
			"appId": Hathora.APP_ID,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_deployments_v1.emit(result)
	return result


static func get_deployments() -> Signal:
	get_deployments_async()
	return HathoraEventBus.on_get_deployments_v1
#endregion


#region get_latest_deployment
## Deployment is a versioned configuration for a build that describes runtime behavior.
class GetLatestDeploymentResponse:
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

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		if data.has("idleTimeoutEnabled"):
			self.idle_timeout_enabled = data["idleTimeoutEnabled"]
		
		assert(data.has("env"), "Missing parameter \"env\"")
		for item: Dictionary in data["env"]:
			self.env.push_back(item)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		self.plan_name = data["planName"]
		
		assert(data.has("additionalContainerPorts"), "Missing parameter \"additionalContainerPorts\"")
		for item: Dictionary in data["additionalContainerPorts"]:
			self.additional_container_ports.push_back(ContainerPort.deserialize(item))
		
		assert(data.has("defaultContainerPort"), "Missing parameter \"defaultContainerPort\"")
		self.default_container_port = ContainerPort.deserialize(data["defaultContainerPort"])
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		self.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		self.container_port = float(data["containerPort"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("requestedMemoryMb"), "Missing parameter \"requestedMemoryMb\"")
		self.requested_memory_mb = int(data["requestedMemoryMb"])
		
		assert(data.has("requestedCpu"), "Missing parameter \"requestedCpu\"")
		self.requested_cpu = float(data["requestedCpu"])
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = int(data["deploymentId"])
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		self.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_latest_deployment_async() -> GetLatestDeploymentResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetLatestDeploymentResponse = GetLatestDeploymentResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/latest".format({
			"appId": Hathora.APP_ID,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_latest_deployment_v1.emit(result)
	return result


static func get_latest_deployment() -> Signal:
	get_latest_deployment_async()
	return HathoraEventBus.on_get_latest_deployment_v1
#endregion


#region get_deployment_info
## Deployment is a versioned configuration for a build that describes runtime behavior.
class GetDeploymentInfoResponse:
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

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		if data.has("idleTimeoutEnabled"):
			self.idle_timeout_enabled = data["idleTimeoutEnabled"]
		
		assert(data.has("env"), "Missing parameter \"env\"")
		for item: Dictionary in data["env"]:
			self.env.push_back(item)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		self.plan_name = data["planName"]
		
		assert(data.has("additionalContainerPorts"), "Missing parameter \"additionalContainerPorts\"")
		for item: Dictionary in data["additionalContainerPorts"]:
			self.additional_container_ports.push_back(ContainerPort.deserialize(item))
		
		assert(data.has("defaultContainerPort"), "Missing parameter \"defaultContainerPort\"")
		self.default_container_port = ContainerPort.deserialize(data["defaultContainerPort"])
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		self.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		self.container_port = float(data["containerPort"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("requestedMemoryMb"), "Missing parameter \"requestedMemoryMb\"")
		self.requested_memory_mb = int(data["requestedMemoryMb"])
		
		assert(data.has("requestedCpu"), "Missing parameter \"requestedCpu\"")
		self.requested_cpu = float(data["requestedCpu"])
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = int(data["deploymentId"])
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		self.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_deployment_info_async(deployment_id: int) -> GetDeploymentInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetDeploymentInfoResponse = GetDeploymentInfoResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/info/{deploymentId}".format({
			"appId": Hathora.APP_ID,
			"deploymentId": deployment_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_deployment_info_v1.emit(result)
	return result


static func get_deployment_info(deployment_id: int) -> Signal:
	get_deployment_info_async(deployment_id)
	return HathoraEventBus.on_get_deployment_info_v1
#endregion


#region create_deployment
## Deployment is a versioned configuration for a build that describes runtime behavior.
class CreateDeploymentResponse:
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

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		if data.has("idleTimeoutEnabled"):
			self.idle_timeout_enabled = data["idleTimeoutEnabled"]
		
		assert(data.has("env"), "Missing parameter \"env\"")
		for item: Dictionary in data["env"]:
			self.env.push_back(item)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		self.plan_name = data["planName"]
		
		assert(data.has("additionalContainerPorts"), "Missing parameter \"additionalContainerPorts\"")
		for item: Dictionary in data["additionalContainerPorts"]:
			self.additional_container_ports.push_back(ContainerPort.deserialize(item))
		
		assert(data.has("defaultContainerPort"), "Missing parameter \"defaultContainerPort\"")
		self.default_container_port = ContainerPort.deserialize(data["defaultContainerPort"])
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		self.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		self.container_port = float(data["containerPort"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("requestedMemoryMb"), "Missing parameter \"requestedMemoryMb\"")
		self.requested_memory_mb = int(data["requestedMemoryMb"])
		
		assert(data.has("requestedCpu"), "Missing parameter \"requestedCpu\"")
		self.requested_cpu = float(data["requestedCpu"])
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = int(data["deploymentId"])
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		self.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func create_deployment_async(env: Array[Dictionary], rooms_per_process: int, plan_name: String, transport_type: String, container_port: int, build_id: int, idle_timeout_enabled: bool = false, additional_container_ports: Array[Dictionary] = []) -> CreateDeploymentResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateDeploymentResponse = CreateDeploymentResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/create/{buildId}".format({
			"appId": Hathora.APP_ID,
			"buildId": build_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"idleTimeoutEnabled": idle_timeout_enabled,
			"env": env,
			"roomsPerProcess": rooms_per_process,
			"planName": plan_name,
			"additionalContainerPorts": additional_container_ports,
			"transportType": transport_type,
			"containerPort": container_port,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [400, 401, 404, 422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_deployment_v1.emit(result)
	return result


static func create_deployment(env: Array[Dictionary], rooms_per_process: int, plan_name: String, transport_type: String, container_port: int, build_id: int, idle_timeout_enabled: bool = false, additional_container_ports: Array[Dictionary] = []) -> Signal:
	create_deployment_async(env, rooms_per_process, plan_name, transport_type, container_port, build_id, idle_timeout_enabled, additional_container_ports)
	return HathoraEventBus.on_create_deployment_v1
#endregion



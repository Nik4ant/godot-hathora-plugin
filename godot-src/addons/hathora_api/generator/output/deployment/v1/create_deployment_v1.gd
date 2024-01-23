# DeploymentV1
const ContainerPort = preload("res://addons/hathora_api/api/common_types.gd").ContainerPort
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- create_deployment
class CreateDeploymentResponse:
	var error
	var error_message: String
	
	var env: Array[Dictionary]
	var rooms_per_process: int
	var plan_name: String
	var additional_container_ports: Array[ContainerPort]
	var default_container_port: ContainerPort
	var transport_type: String
	var container_port: float
	var created_at_unix: int
	var created_by: String
	var requested_memory_mb: int
	var requested_cpu: float
	var deployment_id: int
	var build_id: int
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("env"), "Missing parameter \"env\"")
		for part in data["env"]:
			self.env.push_back(part)
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = data["roomsPerProcess"]
		
		assert(data.has("planName"), "Missing parameter \"planName\"")
		self.plan_name = data["planName"]
		
		assert(data.has("additionalContainerPorts"), "Missing parameter \"additionalContainerPorts\"")
		for part in data["additionalContainerPorts"]:
			self.additional_container_ports.push_back(ContainerPort.deserialize(part))
		
		assert(data.has("defaultContainerPort"), "Missing parameter \"defaultContainerPort\"")
		self.default_container_port = ContainerPort.deserialize(data["defaultContainerPort"])
		
		assert(data.has("transportType"), "Missing parameter \"transportType\"")
		self.transport_type = data["transportType"]
		
		assert(data.has("containerPort"), "Missing parameter \"containerPort\"")
		self.container_port = data["containerPort"]
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("requestedMemoryMB"), "Missing parameter \"requestedMemoryMB\"")
		self.requested_memory_mb = data["requestedMemoryMB"]
		
		assert(data.has("requestedCPU"), "Missing parameter \"requestedCPU\"")
		self.requested_cpu = data["requestedCPU"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = data["deploymentId"]
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		self.build_id = data["buildId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func create_deployment_async(env: Array[Dictionary], rooms_per_process: int, plan_name: String, transport_type: String, container_port: int, build_id: int, additional_container_ports: Array[ContainerPort] = []) -> CreateDeploymentResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateDeploymentResponse = CreateDeploymentResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/create/{buildId}".format(
		{
			"appId": Hathora.APP_ID,
			"buildId": build_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"env": env,
			"roomsPerProcess": rooms_per_process,
			"planName": plan_name,
			"additionalContainerPorts": additional_container_ports,
			"transportType": transport_type,
			"containerPort": container_port
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [400, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_deployment.emit(result)
	return result


static func create_deployment(env: Array[Dictionary], rooms_per_process: int, plan_name: String, transport_type: String, container_port: int, build_id: int, additional_container_ports: Array[ContainerPort] = []) -> Signal:
	create_deployment_async(env, rooms_per_process, plan_name, transport_type, container_port, build_id, additional_container_ports)
	return HathoraEventBus.on_create_deployment
#endregion    -- create_deployment

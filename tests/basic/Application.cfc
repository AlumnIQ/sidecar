component skip="true" {
	this.name = "cf-sidecar-tests-" & "basic-" & hash(getCurrentTemplatePath());

	this.mappings["/lib"] = expandPath("../../lib");
	this.mappings["/com"] = expandPath("../../com");

	variables.system = createObject("java", "java.lang.System");

	this.javasettings = {
		loadPaths = ["../../lib"],
		loadColdFusionClassPath = true,
		reloadOnChange = false,
		watchInterval = 60,
		watchExtensions = "jar,class"
	};

	this.sessionmanagement = false;
	this.setclientcookies = false;
	//this.setDomainCookies = false;

	private function getRedisClient () {
		local.redisHost = "localhost";  // redis server hostname or ip address
		local.redisPort = 6379;

		local.env = variables.system.getenv();

		if (!isNull(local.env.REDIS_PORT)) {
			local.redisHost = listFirst(listLast(local.env.REDIS_PORT, "//"), ":");
			local.redisPort = listLast(local.env.REDIS_PORT, ":");
		}

		// Configure connection pool
		local.jedisPoolConfig = CreateObject("java", "redis.clients.jedis.JedisPoolConfig");

		//writedump(local.jedisPoolConfig.getFields());
		//writedump(getMetaData(local));abort;

		local.jedisPoolConfig.init();
		local.jedisPoolConfig.testOnBorrow = false;
		local.jedisPoolConfig.testOnReturn = false;
		local.jedisPoolConfig.testWhileIdle = true;
		//local.jedisPoolConfig.maxActive = 100;
		local.jedisPoolConfig.maxIdle = 5;
		local.jedisPoolConfig.numTestsPerEvictionRun = 10;
		local.jedisPoolConfig.timeBetweenEvictionRunsMillis = 10000;
		local.jedisPoolConfig.maxWaitMillis = 30000;

		local.jedisPool = CreateObject("java", "redis.clients.jedis.JedisPool");
		local.jedisPool.init(local.jedisPoolConfig, local.redisHost, local.redisPort);

		// The "cfc.cfredis" component name will change depending on where you put cfredis
		local.redis = CreateObject("component", "lib.cfredis").init();
		local.redis.connectionPool = local.jedisPool;

		return local.redis;
	}

	function appInit () {

		var redis = getRedisClient();


		var store = new com.redis_session_store(redis);
		var sidecar = new com.sidecar();
			sidecar.setSessionStorage(store);
			sidecar.setSecrets("3", "4");
			sidecar.onSessionStart(function() {
				request.sessionStarted = true;
			});
			sidecar.setDefaultSessionTimeout(5); // 5 seconds
			sidecar.enableDebugMode();


		lock scope="application" type="exclusive" timeout="1" throwOnTimeout=true {
			application.sidecar = sidecar;
		}

	}

	boolean function onApplicationStart () {
		//you do not have to lock the application scope
		//you CANNOT access the variables scope
		//uncaught exceptions or returning false will keep the application from starting
			//and CF will not process any pages, onApplicationStart() will be called on next request

		appInit();

		return true;
	}

/*
	void function onError (any exception, string eventName) {
		//You CAN display a message to the user if an error occurs during an
			//onApplicationStart, onSessionStart, onRequestStart, onRequest,
			//or onRequestEnd event method, or while processing a request.
		//You CANNOT display output to the user if the error occurs during an
			//onApplicationEnd or onSessionEnd event method, because there is
			//no available page context; however, it can log an error message.

		writedump(arguments);
		abort;
	}
*/

	boolean function onRequestStart (targetPage) {
		//you cannot access the variables scope
		//you CAN access the request scope

		//include "globalFunctions.cfm";

		if (!isNull(url.reinit) && url.reinit == true) {
			appInit();
		}

		//copy cookie struct into request for tests to examine
		request.originalCookieStruct = duplicate(cookie);

		application.sidecar.requestStartHandler();

		//returning false would stop processing the request
		return true;
	}

	void function onRequestEnd (targetPage) {
		//you can access page context
		//you can generate output
		//you cannot access the variables scope
		//you CAN access the request scope

		application.sidecar.requestEndHandler();
	}




}
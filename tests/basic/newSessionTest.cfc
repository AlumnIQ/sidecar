component extends="testbox.system.BaseSpec" {


	private numeric function unixtime () {
		return createObject("java", "java.lang.System").currentTimeMillis();
	}


	function beforeAll () {
	}

	function afterAll () {

	}

	function run () {

		describe("baseline environment", function () {

			it("should have started a new session", function() {
				expect(request).toHaveKey("sessionStarted");
				expect(request.sessionStarted).toBeTrue();
			});

			it("should have request.sess_sid", function() {
				expect(request).toHaveKey("sess_sid");
				expect(request.sess_sid).notToBeEmpty();
			});

			it("should give a default value for a non-existant key", function() {
				var foo = application.sess.get("foo", "default");
				expect(foo).toBe("default");
			});

			it("should return the right value for a key thats been set", function() {
				application.sess.set("foo", "bar");
				var foo = application.sess.get("foo", "default");
				expect(foo).toBe("bar");
			});

			it("should return the right sessionID", function() {
				expect(application.sess.getSessionID()).toBe(request.sess_sid);
			});

			it("should have the same sessionID as in the cookie", function() {
				expect(application.sess.getSessionID()).toBe(listFirst(cookie.sess_sid, "."));
			});

			it("should allow you to store a collection at once", function() {

				//you have to use quotes for the collection or the keys will be stored in redis as UPPERCASE
				var coll = {
					"one": 1,
					"two": [1,2],
					"three": now(),
					four: 4
				};

				application.sess.setCollection(coll);

				expect(application.sess.get("one")).toBe(1);

				var two = application.sess.get("two");
				expect(two).toBeArray().toBe([1,2]);

				expect(application.sess.get("three")).toBeDate();

				expect(application.sess.get("FOUR")).toBe(4);

				expect(application.sess.get("five")).toBe(-1);
				expect(application.sess.get("FIVE")).toBe(-1);

			});

			it("should store and retrieve a struct properly", function() {
				var structTest = {
					one: 1,
					two: 2,
					three: [1,2,3]
				};

				application.sess.set("structTest", structTest);

				var output = application.sess.get("structTest", "default");

				expect(output).toBeStruct();
				expect(output).toBe(structTest);
			});


		});


	}


}
define([ "jquery", "lib/core/newsletter_form" ], function($, NewsletterForm) {

  "use strict";

  describe("NewsletterForm", function() {
    var instance;

    beforeEach(function() {
      loadFixtures("newsletter_form.html");
    });

    describe("Initialization", function() {

      beforeEach(function() {
        instance = new NewsletterForm();
      });

      it("is defined", function() {
        expect(instance).toBeDefined();
      });

      it("finds newsletter form element", function() {
        expect(instance.$el).toExist();
      });
    });

    describe("Functionality", function() {
      var request;

      beforeEach(function() {
        jasmine.Ajax.install();
        instance = new NewsletterForm();
        instance.$el.submit();
        request = jasmine.Ajax.requests.mostRecent();
      });

      afterEach(function() {
        jasmine.Ajax.uninstall();
      });

      describe("First time sing up", function() {
        beforeEach(function() {
          request.respondWith({
	    status: 200,
	    responseText: "{}"
	  });
        });

        it("shows success notification", function() {
	  expect($('.alert--success')[0]).toBeInDOM();
        });
      });

      describe("Already singed up", function() {
        beforeEach(function() {
          request.respondWith({
	    status: 409,
	    responseText: "{}"
	  });
        });

        it("shows notification", function() {
	  expect($('.alert--announcement')[0]).toBeInDOM();
        });
      });

      describe("Sign up error", function() {
        beforeEach(function() {
          request.respondWith({
	    status: 500,
	    responseText: "{}"
	  });
        });

        it("shows error notification", function() {
	  expect($('.alert--error')[0]).toBeInDOM();
        });
      });
    });

  });
});

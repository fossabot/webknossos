import _ from "lodash";
import AirbrakeClient from "airbrake-js";

const ErrorHandling = {

  initialize( options ) {

    if (options == null) { options = { throwAssertions: false, sendLocalErrors: false }; }
    ({ throwAssertions: this.throwAssertions, sendLocalErrors: this.sendLocalErrors } = options);

    return this.initializeAirbrake();
  },


  initializeAirbrake() {

    // read Airbrake config from DOM
    // config is inject from backend
    const $scriptTag = $("[data-airbrake-project-id]");
    const projectId = $scriptTag.data("airbrake-project-id");
    const projectKey = $scriptTag.data("airbrake-project-key");
    const envName = $scriptTag.data("airbrake-environment-name");

    window.Airbrake = new AirbrakeClient({
      projectId,
      projectKey
    });

    Airbrake.addFilter(function(notice) {
      notice.context.environment = envName;
      return notice;
    });

    if (!this.sendLocalErrors) {

      Airbrake.addFilter( notice => location.hostname !== "127.0.0.1" && location.hostname !== "localhost");
    }

    return window.onerror = function(message, file, line, colno, error) {

      if (error == null) {
        // older browsers don't deliver the error parameter
        error = new Error(message, file, line);
      }

      console.error(error);
      return Airbrake.notify(error);
    };
  },



  assertExtendContext(additionalContext) {

    // since the context isn't displayed on Airbrake.io, we use the params-attribute
    return Airbrake.addFilter(additionalContext);
  },


  assert : (bool, message, assertionContext) => {

    if (bool) {
      return;
    }

    const error = new Error(`Assertion violated - ${message}`);

    error.params = assertionContext;
    error.stack = this.trimCallstack(error.stack);

    Toast.error(`Assertion violated - ${message}`);

    if (this.throwAssertions) {
      // error will be automatically pushed to airbrake due to global handler
      throw error;
    } else {
      console.error(error);
      return Airbrake.notify(error);
    }
  },


  assertExists(variable, message, assertionContext) {

    if (variable != null) {
      return;
    }

    return this.assert(false, message + ` (variable is ${variable})`, assertionContext);
  },


  assertEquals(actual, wanted, message, assertionContext) {

    if (actual === wanted) {
      return;
    }

    return this.assert(false, message + ` (${actual} != ${wanted})`, assertionContext);
  },


  setCurrentUser(user) {

    return Airbrake.addFilter(function(notice) {
      notice.context.user = _.pick(user, [
        "id",
        "email",
        "firstName",
        "lastName",
        "isActive"
      ]);
      return notice;
    });
  },


  trimCallstack(callstack) {

    // cut function calls caused by ErrorHandling so that Airbrake won't cluster all assertions into one group

    const trimmedCallstack = [];

    for (let line of callstack.split("\n")) {

      if (line.indexOf("errorHandling.js") === -1) {

        trimmedCallstack.push(line);
      }
    }

    return trimmedCallstack.join("\n");
  }
};


export default ErrorHandling;

require('./main.css');

var Elm = require('./Main.elm');

var elmEntry = document.getElementById('elm-entry');

// Embed Elm app and pass in static data

var elmApp = Elm.Main.embed(elmEntry, {
    staticAssetsPath: require('../config/paths').staticAssets
});

// Gitignored config information



elmApp.ports.getEndpoints.subscribe(function () {
    var endpoints = require('../config/endpoints')

    console.log(endpoints);
    elmApp.ports.receiveEndpoints.send(endpoints);
});

// State storage ports

var localStorageLoggedInUser = 'loggedInUser'

elmApp.ports.storeLoggedInUser.subscribe(function (loggedInUser) {
    var encodedLoggedInUser = JSON.stringify(loggedInUser);
    localStorage.setItem(localStorageLoggedInUser, encodedLoggedInUser);
});

elmApp.ports.getLoggedInUser.subscribe(function () {
    var encodedLoggedInUser = localStorage.getItem(localStorageLoggedInUser);
    var maybeLoggedInUser = encodedLoggedInUser
        ? JSON.parse(encodedLoggedInUser)
        : null;
    elmApp.ports.receiveMaybeLoggedInUser.send(maybeLoggedInUser);
});

elmApp.ports.removeLoggedInUser.subscribe(function () {
    localStorage.removeItem(localStorageLoggedInUser);
});

// Auth0 ports

var options = {
    allowedConnections: [
        'Username-Password-Authentication',
        'facebook',
        'google',
        'github'],
    autoclose: true,
    closable: true,
    auth: {
        redirect: false,
        sso: true
    },
    popupOptions: { width: 300, height: 500, left: 200, top: 100 },
    theme: { logo: 'https://secure.gravatar.com/avatar/617e3e335ccfa0beaf98fdca0a4cebf4?d=404&s=160'}

};

// Set up Auth0 authentication
var lock = new Auth0Lock('SVTFujME3uKXUexoolrRTRqjYL5xl6nM', 'rwoodnz.auth0.com', options);

// Show Auth0 lock subscription
elmApp.ports.auth0showLock.subscribe(function (options) {
    lock.show(options);
});

// Set Auth0 Listening for the authenticated event
lock.on("authenticated", function (authResult) {

    lock.getProfile(authResult.idToken, function (error, profile) {
        var result = { err: null, ok: null };
        var token = authResult.idToken;

        if (error) {
            result.err = err.details;
            result.err.name = result.err.name ? result.err.name : null;
            result.err.code = result.err.code ? result.err.code : null;
            result.err.statusCode = result.err.statusCode ?result.err.statusCode : null;
        }
        else {
            result.ok = { profile: profile, token: token };
        }
        elmApp.ports.auth0authResult.send(result);
    });
});


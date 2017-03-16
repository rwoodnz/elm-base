require('./main.css');

var Elm = require('./Main.elm');

var elmEntry = document.getElementById('elm-entry');

Elm.Main.embed(elmEntry, {
    staticAssetsPath: require('../config/paths').staticAssets
});

// ports go here:

require('./main.css');

var Elm = require('./Main.elm');

var elmEntry = document.getElementById('elm-entry');

Elm.Main.embed(elmEntry);

// ports go here:

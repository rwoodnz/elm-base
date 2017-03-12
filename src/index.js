require('./main.css');
var logoPath = require('./Richard.jpeg');
var Elm = require('./Main.elm');

var elmEntry = document.getElementById('elm-entry');

Elm.Main.embed(elmEntry, logoPath);

// ports go here:

module Main exposing (..)

import Navigation exposing (Location)

import App

main : Program Never App.Model App.Msg
main =
    Navigation.program App.UrlChange
        { view = App.view
        , init = App.init
        , update = App.update
        , subscriptions = App.subscriptions
        }

module Main exposing (..)

import Navigation exposing (Location)

import App

main : Program App.Flags App.Model App.Msg
main =
    Navigation.programWithFlags App.UrlChange
        { view = App.view
        , init = App.init
        , update = App.update
        , subscriptions = App.subscriptions
        }

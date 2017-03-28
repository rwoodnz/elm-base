module Main exposing (..)

import Navigation exposing (Location)
import App exposing (view, init, update, subscriptions)


main : Program App.Flags App.Model App.Msg
main =
    Navigation.programWithFlags App.UrlChange
        { view = App.view
        , init = App.init
        , update = App.update
        , subscriptions = App.subscriptions
        }

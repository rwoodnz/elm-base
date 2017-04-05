module Main exposing (..)

import Common exposing (..)
import App exposing (..)
import Navigation exposing (Location)
import View exposing (..)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { view = View.view
        , init = App.init
        , update = App.update
        , subscriptions = App.subscriptions
        }

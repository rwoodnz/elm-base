module Main exposing (..)

import App
import Html


main : Program String App.Model App.Msg
main =
    Html.programWithFlags
        { view = App.view
        , init = App.init
        , update = App.update
        , subscriptions = App.subscriptions
        }

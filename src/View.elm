module View exposing (..)

import Common exposing (..)
import App exposing (..)
import Auth.App as Auth

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Html.Events exposing (onClick)
import Date
import Date.Extra.Format exposing (..)
import Date.Extra.Config.Config_en_au exposing (..)


view : Model -> Html Msg
view model =
    Grid.container []
        [ menu model
        , if
            model.authenticationRequired
                && not (Auth.isLoggedIn model.authenticationModel)
          then
            login model
          else
            content model
        ]


menu : Model -> Html Msg
menu model =
    div []
        [ Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.container
            |> Navbar.brand [ href "#" ]
                [ img
                    [ src (model.flags.staticAssetsPath ++ "/Richard.jpeg")
                    , class "d-inline-block align-top"
                    , width 30
                    , style
                        [ ( "padding", "5px" )
                        , ( "margin-right", "5px" )
                        ]
                    ]
                    []
                , text "Elm-base"
                ]
            |> Navbar.items
                [ Navbar.itemLink [ href "#about" ] [ text "About" ]
                , Navbar.itemLink [ hidden (not (Auth.isLoggedIn model.authenticationModel)), onClick LogOut ] [ text "Log out" ]
                , Navbar.itemLink [ hidden (Auth.isLoggedIn model.authenticationModel), onClick LogIn ] [ text "Log in or sign up" ]
                ]
            |> Navbar.view model.navbarState
        ]


content : Model -> Html Msg
content model =
    div []
        [ div [ class "mt-2", hidden (model.globalAlert == emptyAlert) ]
            [ Alert.info
                [ Button.button [ Button.attrs [ class "close", onClick CloseGLobalAlert ] ]
                    [ span [] [ text "x" ] ]
                , text model.globalAlert.message
                ]
            ]
        , case model.page of
            Home ->
                pageHome model

            About ->
                pageAbout

            NotFound ->
                pageNotFound
        ]


login : Model -> Html Msg
login model =
    div [] []


pageHome : Model -> Html Msg
pageHome model =
    div []
        [ h3 [ class "mt-2" ] [ text "Home" ]
        , div []
            [ Button.button
                [ Button.primary
                , Button.attrs [ class "mr-2", onClick CallPublicApi ]
                ]
                [ text "Public Api" ]
            , Button.button
                [ Button.primary
                , Button.attrs [ onClick CallPrivateApi ]
                ]
                [ text "Private Api" ]
            ]
        , div [] [ text ("Time: " ++ utcIsoString (Date.fromTime model.theTime)) ]
        , div [] [ text ("TokenExpiryTime: " ++ utcIsoString (Date.fromTime (Auth.tokenExpiryTime model.authenticationModel))) ]
        , div [ class "wrapper", width 400 ]
            [ img [ src (model.flags.staticAssetsPath ++ "/Richard.jpeg"), width 300, class "rounded" ] [] ]
        ]


pageAbout : Html Msg
pageAbout =
    div []
        [ h3 [ class "mt-2" ] [ text "About" ]
        ]


pageNotFound : Html Msg
pageNotFound =
    div []
        [ h3 [] [ text "Not found" ]
        , text "Please check your URL"
        ]



-- CONSTANTS


emptyAlert : Alert
emptyAlert =
    Alert "" 0 0

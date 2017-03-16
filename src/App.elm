module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)


type alias Model =
    { page : Page
    , navBarState : Navbar.State
    , staticAssetsPath : String
    }


type alias Flags =
    { staticAssetsPath : String
    }


type Page
    = Home
    | About
    | NotFound


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    let
        initModel =
            { navBarState = navBarState
            , page = Home
            , staticAssetsPath = flags.staticAssetsPath
            }

        ( navBarState, navBarCmd ) =
            Navbar.initialState NavbarMsg

        ( model, urlCmd ) =
            urlUpdate location initModel
    in
        ( model
        , Cmd.batch [ urlCmd, navBarCmd ]
        )


type Msg
    = UrlChange Location
    | NavbarMsg Navbar.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            urlUpdate location model

        NavbarMsg state ->
            ( { model | navBarState = state }
            , Cmd.none
            )


urlUpdate : Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    case decode location of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decode : Location -> Maybe Page
decode location =
    UrlParser.parseHash routeParser location


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Home UrlParser.top
        , UrlParser.map About (UrlParser.s "about")
        ]


view : Model -> Html Msg
view model =
    div []
        [ menu model
        , content model
        ]


menu : Model -> Html Msg
menu model =
    Grid.container []
        [ Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.container
            |> Navbar.brand [ href "#" ]
                [ img
                    [ src (model.staticAssetsPath ++ "Richard.jpeg")
                    , class "d-inline-block align-top"
                    , style
                        [ ( "width", "30px" )
                        , ( "padding", "5px" )
                        , ( "margin-right", "5px" )
                        ]
                    ]
                    []
                , text "Home"
                ]
            |> Navbar.items
                [ Navbar.itemLink [ href "#about" ] [ text "About" ]
                ]
            |> Navbar.view model.navBarState
        ]


content : Model -> Html Msg
content model =
    Grid.container [] <|
        case model.page of
            Home ->
                pageHome model

            About ->
                pageAbout model

            NotFound ->
                pageNotFound


pageHome : Model -> List (Html Msg)
pageHome model =
    [ h1 [] [ text "Home" ]
    , img [ src (model.staticAssetsPath ++ "Richard.jpeg") ] []
    ]


pageAbout : Model -> List (Html Msg)
pageAbout model =
    [ h2 [] [ text "About" ]
    ]


pageNotFound : List (Html Msg)
pageNotFound =
    [ h1 [] [ text "Not found" ]
    , text "Please check your URL"
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Navbar.subscriptions model.navBarState NavbarMsg

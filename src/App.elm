module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)


type alias Model =
    { page : Page
    , navbarState : Navbar.State
    , flags : Flags
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
            { navbarState = navbarState
            , page = Home
            , flags =
                { staticAssetsPath = flags.staticAssetsPath
                }
            }

        ( navbarState, navBarCmd ) =
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
            ( { model | navbarState = state }
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
                    [ src (model.flags.staticAssetsPath ++ "/Richard.jpeg")
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
            |> Navbar.view model.navbarState
        ]


content : Model -> Html Msg
content model =
    Grid.container [] [ 
        case model.page of
            Home ->
                pageHome model

            About ->
                pageAbout

            NotFound ->
                pageNotFound
    ]

pageHome : Model -> Html Msg
pageHome model =
    div [] 
    [ h1 [] [ text "Home" ]
    , img [ src (model.flags.staticAssetsPath ++ "/Richard.jpeg") ] []
    ]


pageAbout : Html Msg
pageAbout =
    div []
    [ h2 [] [ text "About" ]
    ]


pageNotFound : Html Msg
pageNotFound =
    div []
    [ h1 [] [ text "Not found" ]
    , text "Please check your URL"
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Navbar.subscriptions model.navbarState NavbarMsg

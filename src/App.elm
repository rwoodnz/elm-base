module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)
import Bootstrap.Dropdown as Dropdown
import Html.Events exposing (onInput, onWithOptions, onClick)
import Auth


-- MODELS


type alias Model =
    { page : Page
    , navbarState : Navbar.State
    , flags : Flags
    , dropdownState : Dropdown.State
    , authenticationRequired : Bool
    , role : Role
    , authenticationModel : Auth.AuthenticationModel
    }


type Role
    = Admin
    | CustomerService
    | User


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
            , dropdownState = Dropdown.initialState
            , authenticationRequired = True
            , role = User
            , authenticationModel = Auth.NotLoggedIn
            }

        ( navbarState, navBarCmd ) =
            Navbar.initialState NavbarMsg

        ( model, urlCmd ) =
            urlUpdate location initModel
    in
        ( model
        , Cmd.batch
            [ urlCmd
            , navBarCmd
            , Auth.getLoggedInUser ()
            ]
        )



-- MESSAGES


type Msg
    = UrlChange Location
    | NavbarMsg Navbar.State
    | DropdownMsg Dropdown.State
    | LogOut
    | HandleReceivedMaybeLoggedInUser (Maybe Auth.LoggedInUser)
    | HandleAuthenticationResult Auth.AuthenticationResult



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            urlUpdate location model

        NavbarMsg state ->
            ( { model | navbarState = state }
            , Cmd.none
            )

        DropdownMsg state ->
            ( { model | dropdownState = state }, Cmd.none )

        LogOut ->
            ( { model
                | authenticationModel = Auth.NotLoggedIn
              }
            , Cmd.batch
                [ Auth.removeLoggedInUser ()
                , if model.authenticationRequired then
                    Auth.showLock
                  else
                    Cmd.none
                ]
            )

        HandleAuthenticationResult result ->
            let
                newAuthenticationModel =
                    Auth.handleAuthenticationRawResult result
            in
                ( { model | authenticationModel = newAuthenticationModel }
                , case newAuthenticationModel of
                    Auth.LoggedIn user ->
                        Auth.storeLoggedInUser user

                    Auth.NotLoggedIn ->
                        Cmd.none
                )

        HandleReceivedMaybeLoggedInUser maybeLoggedInUser ->
            let
                newAuthenticationModel =
                    case maybeLoggedInUser of
                        Just loggedInUser ->
                            Auth.LoggedIn loggedInUser

                        Nothing ->
                            Auth.NotLoggedIn
            in
                ( { model | authenticationModel = newAuthenticationModel }
                , if
                    model.authenticationRequired
                        && not (Auth.isLoggedIn model.authenticationModel)
                  then
                    Auth.showLock
                  else
                    Cmd.none
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navbar.subscriptions model.navbarState NavbarMsg
        , Dropdown.subscriptions model.dropdownState DropdownMsg
        , Auth.receiveMaybeLoggedInUser HandleReceivedMaybeLoggedInUser
        , Auth.getAuthResult HandleAuthenticationResult
        ]



-- VIEW


view : Model -> Html Msg
view model =
    Grid.container []
        [ menu model
        , content model
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
                , Navbar.itemLink [ hidden (not (Auth.isLoggedIn model.authenticationModel)), onClick LogOut ] [ text "Logout" ]
                ]
            |> Navbar.view model.navbarState
        ]


content : Model -> Html Msg
content model =
    div []
        [ case model.page of
            Home ->
                pageHome model

            About ->
                pageAbout

            NotFound ->
                pageNotFound
        ]


pageHome : { a | flags : Flags } -> Html Msg
pageHome { flags } =
    div []
        [ h1 [] [ text "Home" ]
        , img [ src (flags.staticAssetsPath ++ "/Richard.jpeg") ] []
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

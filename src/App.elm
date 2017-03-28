port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)
import Bootstrap.Dropdown as Dropdown
import Html.Events exposing (onClick)
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



-- There are two modes of authenticaiton:
-- Log in mannually or
-- AuthenticationRequired
-- The latter requires closable has to be set to true in Auth0 options in index.js so that autoclose also works.


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    let
        initModel =
            { flags =
                { staticAssetsPath = flags.staticAssetsPath
                }
            , authenticationRequired = True
            , role = User
            , authenticationModel = Auth.NotLoggedIn
            , navbarState = navbarState
            , page = Home
            , dropdownState = Dropdown.initialState
            }

        ( navbarState, navBarCmd ) =
            Navbar.initialState NavbarMsg

        ( model, urlCmd ) =
            urlUpdate location initModel
    in
        ( model
        , Cmd.batch
            [ getLoggedInUser ()
            , urlCmd
            , navBarCmd
            ]
        )



-- MESSAGES


type Msg
    = UrlChange Location
    | NavbarMsg Navbar.State
    | DropdownMsg Dropdown.State
    | LogOut
    | LogIn
    | ReceiveMaybeLoggedInUser (Maybe Auth.LoggedInUser)
    | ReceiveAuthentication Auth.AuthenticationResult



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            urlUpdate location model

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )

        DropdownMsg state ->
            ( { model | dropdownState = state }, Cmd.none )

        LogOut ->
            ( { model | authenticationModel = Auth.NotLoggedIn }
            , Cmd.batch
                [ removeLoggedInUser ()
                , if model.authenticationRequired then
                    Auth.showLock
                  else
                    Cmd.none
                ]
            )

        LogIn ->
            ( model, Auth.showLock )

        ReceiveAuthentication result ->
            let
                ( newAuthenticationModel, error ) =
                    Auth.handleReceiveAuthentication result
            in
                ( { model
                    | authenticationModel = newAuthenticationModel
                  }
                , case newAuthenticationModel of
                    Auth.LoggedIn user ->
                        storeLoggedInUser user

                    Auth.NotLoggedIn ->
                        Cmd.none
                )

        ReceiveMaybeLoggedInUser maybeLoggedInUser ->
            let
                newAuthenticationModel =
                    case maybeLoggedInUser of
                        Just loggedInUser ->
                            Auth.LoggedIn loggedInUser

                        Nothing ->
                            Auth.NotLoggedIn
            in
                ( { model
                    | authenticationModel = newAuthenticationModel
                  }
                , if
                    model.authenticationRequired
                        && not (Auth.isLoggedIn newAuthenticationModel)
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
        , receiveMaybeLoggedInUser ReceiveMaybeLoggedInUser
        , Auth.getAuthResult ReceiveAuthentication
        ]



-- VIEW


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
                    , style
                        [ ( "width", "30px" )
                        , ( "padding", "5px" )
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
        [ case model.page of
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


pageHome : { a | flags : Flags } -> Html Msg
pageHome { flags } =
    div []
        [ h3 [] [ text "Home" ]
        , img [ src (flags.staticAssetsPath ++ "/Richard.jpeg") ] []
        ]


pageAbout : Html Msg
pageAbout =
    div []
        [ h3 [] [ text "About" ]
        ]


pageNotFound : Html Msg
pageNotFound =
    div []
        [ h3 [] [ text "Not found" ]
        , text "Please check your URL"
        ]



-- LOCAL BROWSER STORAGE PORTS


port storeLoggedInUser : Auth.LoggedInUser -> Cmd msg


port removeLoggedInUser : () -> Cmd msg


port getLoggedInUser : () -> Cmd msg


port receiveMaybeLoggedInUser : (Maybe Auth.LoggedInUser -> msg) -> Sub msg

module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)
import Bootstrap.Dropdown as Dropdown
import Html.Events exposing (onInput, onWithOptions, onClick)
import Html.Events.Extra exposing (onEnter)
import Json.Decode as Decode


type alias Model =
    { page : Page
    , navbarState : Navbar.State
    , signup : Signup
    , flags : Flags
    , dropdownState : Dropdown.State
    , authenticationRequired : Bool
    , authenticated : Bool
    , role : Role
    }


type alias Signup =
    { email : ValidatableString
    , password : ValidatableString
    }


type alias ValidatableString =
    { text : String
    , errors : String
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
            , signup =
                { email = { text = "", errors = "" }
                , password = { text = "", errors = "" }
                }
            , flags =
                { staticAssetsPath = flags.staticAssetsPath
                }
            , dropdownState = Dropdown.initialState
            , authenticated = False
            , authenticationRequired = True
            , role = User
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
    | DropdownMsg Dropdown.State
    | AttemptLogin
    | EmailEntry String
    | PasswordEntry String
    | Logout


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

        EmailEntry entry ->
            let
                emailUpdate =
                    ValidatableString entry model.signup.email.errors

                signupUpdate =
                    Signup emailUpdate model.signup.password
            in
                ( { model | signup = signupUpdate }, Cmd.none )

        PasswordEntry entry ->
            let
                passwordUpdate =
                    ValidatableString entry model.signup.password.errors

                signupUpdate =
                    Signup model.signup.email passwordUpdate
            in
                ( { model | signup = signupUpdate }, Cmd.none )

        AttemptLogin ->
            let
                emailErrors =
                    validateText model.signup.email.text "" "Please enter a username"

                passwordErrors =
                    validateText model.signup.password.text "" "Please enter a password"
            in
                ( { model
                    | signup =
                        Signup (ValidatableString model.signup.email.text emailErrors) (ValidatableString model.signup.password.text passwordErrors)
                    , authenticated = emailErrors == "" && passwordErrors == ""
                  }
                , Cmd.none
                )

        Logout ->
            ( { model
                | authenticated = False
                , signup =
                    Signup (ValidatableString model.signup.email.text "")
                        (ValidatableString "" "")
              }
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
    Grid.container []
        [ menu model
        , if model.authenticationRequired && not model.authenticated then
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
                , text "Home"
                ]
            |> Navbar.items
                [ Navbar.itemLink [ href "#about" ] [ text "About" ]
                , Navbar.itemLink [ hidden (not model.authenticated), onClick Logout ] [ text "Logout" ]
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
    div [ class "headspace" ]
        [ div [ class "mx-auto form" ]
            [ h4 [ class "form-heading" ]
                [ text "Please login" ]
            , input
                [ onInput (\char -> EmailEntry char)
                , onEnter AttemptLogin
                , attribute "autofocus" ""
                , class "form-control"
                , name "username"
                , placeholder "Email Address"
                , attribute "required" ""
                , type_ "text"
                , value model.signup.email.text
                ]
                []
            , div [ class "validation-error" ] [ text model.signup.email.errors ]
            , input
                [ onInput (\str -> PasswordEntry str)
                , onEnter AttemptLogin
                , class "form-control form-input"
                , name "password"
                , placeholder "Password"
                , attribute "required" ""
                , type_ "password"
                , value model.signup.password.text
                ]
                []
            , div [ class "validation-error" ] [ text model.signup.password.errors ]
            , label [ class "form-checkbox" ]
                [ input
                    [ id "rememberMe"
                    , name "rememberMe"
                    , type_ "checkbox"
                    , value "remember-me"
                    , class "form-checkbox-box"
                    ]
                    []
                , span [] [ text "  Remember me" ]
                ]
            , button
                [ class "btn btn-lg btn-primary btn-block"
                , onWithOptions "click" { stopPropagation = True, preventDefault = True } (Decode.succeed AttemptLogin)
                ]
                [ text "Login" ]
            ]
        ]


validateText : String -> String -> String -> String
validateText stringToValidate comparison sentence =
    if stringToValidate == comparison then
        sentence
    else
        ""


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navbar.subscriptions model.navbarState NavbarMsg
        , Dropdown.subscriptions model.dropdownState DropdownMsg
        ]

port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import UrlParser exposing ((</>))
import Navigation exposing (Location)
import Bootstrap.Dropdown as Dropdown
import Html.Events exposing (onClick)
import Auth
import Http
import Json.Decode exposing (string, field, decodeString, Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Time exposing (Time, every, second, minute)
import Jwt exposing (isExpired)


-- MODELS


type alias Model =
    { page : Page
    , navbarState : Navbar.State
    , flags : Flags
    , dropdownState : Dropdown.State
    , authenticationRequired : Bool
    , role : Role
    , authenticationModel : Auth.AuthenticationModel
    , globalAlert : Maybe Alert
    , existingLoginHasBeenChecked : Bool
    , theTime : Time
    , endpoints : Endpoints
    }


type alias Alert =
    { message : String, start : Time, duration : Time }


type Role
    = Admin
    | CustomerService
    | User


type alias Flags =
    { staticAssetsPath : String
    , startTime : Time
    }


type Page
    = Home
    | About
    | NotFound



-- INITIALISATION
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
                , startTime = flags.startTime
                }
            , authenticationRequired = True
            , role = User
            , authenticationModel = Auth.NotLoggedIn
            , navbarState = navbarState
            , page = Home
            , dropdownState = Dropdown.initialState
            , globalAlert = Nothing
            , existingLoginHasBeenChecked = False
            , theTime = flags.startTime
            , endpoints = { publicExample = "", privateExample = "" }
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
            , getEndpoints ()
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
    | CallPrivateApi
    | CallPublicApi
    | PublicApiMessage (Result Http.Error ApiResponse)
    | PrivateApiMessage (Result Http.Error ApiResponse)
    | ReceiveTime Time
    | ReceiveEndpoints Endpoints
    | CloseGLobalAlert



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveTime time ->
            ( { model
                | theTime = time
                , globalAlert =
                    if alertExpired model then
                        Nothing
                    else
                        model.globalAlert
              }
            , if model.authenticationRequired && (tokenExpired model) then
                Auth.showLock
              else
                Cmd.none
            )

        ReceiveMaybeLoggedInUser maybeLoggedInUser ->
            case maybeLoggedInUser of
                Just user ->
                    ( { model
                        | authenticationModel = Auth.LoggedIn user
                        , existingLoginHasBeenChecked = True
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model
                        | authenticationModel = Auth.NotLoggedIn
                        , existingLoginHasBeenChecked = True
                      }
                    , if model.authenticationRequired then
                        Auth.showLock
                      else
                        Cmd.none
                    )

        UrlChange location ->
            urlUpdate location model

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )

        DropdownMsg state ->
            ( { model | dropdownState = state }, Cmd.none )

        LogOut ->
            ( { model | authenticationModel = Auth.NotLoggedIn }
            , removeLoggedInUser ()
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

        CallPrivateApi ->
            case model.authenticationModel of
                Auth.NotLoggedIn ->
                    ( { model | globalAlert = setGlobalAlert model "Not logged in" (5 * minute) }
                    , Cmd.none
                    )

                Auth.LoggedIn user ->
                    ( model, (getPrivateApi model.endpoints user.token) )

        CallPublicApi ->
            ( model, (getPublicApi model.endpoints) )

        PublicApiMessage response ->
            case response of
                Ok apiMessage ->
                    ( { model | globalAlert = setGlobalAlert model apiMessage.message (1 * minute) }, Cmd.none )

                Err errorMessage ->
                    ( { model | globalAlert = setGlobalAlert model "Data could not be retrieved from the public API" (1 * minute) }, Cmd.none )

        PrivateApiMessage result ->
            case result of
                Ok apiMessage ->
                    ( { model | globalAlert = setGlobalAlert model apiMessage.message (1 * minute) }, Cmd.none )

                Err errorMessage ->
                    ( { model | globalAlert = setGlobalAlert model "Data could not be retrieved from the private API" (1 * minute) }
                    , Cmd.none
                    )

        ReceiveEndpoints endpoints ->
            ( { model | endpoints = endpoints }, Cmd.none )

        CloseGLobalAlert ->
            ( {model | globalAlert = Nothing } , Cmd.none )


alertExpired : Model -> Bool
alertExpired model =
    case model.globalAlert of
        Just alert ->
            model.theTime - (alert.start + alert.duration) > 0

        Nothing ->
            False


tokenExpired : Model -> Bool
tokenExpired model =
    let
        expiryResult =
            case model.authenticationModel of
                Auth.LoggedIn user ->
                    isExpired model.theTime user.token

                _ ->
                    Ok False
    in
        Result.withDefault True expiryResult


setGlobalAlert : Model -> String -> Time -> Maybe Alert
setGlobalAlert model message duration =
    Just { message = message, start = model.theTime, duration = duration }


urlUpdate : Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    case decodeLocation location of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decodeLocation : Location -> Maybe Page
decodeLocation location =
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
        , every (5 * second) ReceiveTime
        , receiveEndpoints ReceiveEndpoints
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
        [ div [ class "mt-2", hidden (model.globalAlert == Nothing) ]
            [ Alert.info
                [  button [class "close", onClick CloseGLobalAlert ]
                  [span [] [text "x" ]]
                    
                    , text (Maybe.withDefault "" (Maybe.map .message model.globalAlert)) ]
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
        [ h3 [class "mt-2"] [ text "Home" ]
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
        , text ("Time: " ++ toString model.theTime)
        , div [ class "wrapper", width 400 ]
            [ img [ src (model.flags.staticAssetsPath ++ "/Richard.jpeg"), width 300 ] [] ]
        ]


pageAbout : Html Msg
pageAbout =
    div []
        [ h3 [class "mt-2"] [ text "About" ]
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



-- HTTP


type alias Endpoints =
    { publicExample : String, privateExample : String }


port getEndpoints : () -> Cmd msg


port receiveEndpoints : (Endpoints -> msg) -> Sub msg


type alias ApiResponse =
    { message : String }


getPublicApi : Endpoints -> Cmd Msg
getPublicApi endpoints =
    let
        apiMessageRequest =
            Http.get endpoints.publicExample decodeMsg
    in
        Http.send PublicApiMessage apiMessageRequest


privateApiRequest : Endpoints -> String -> Http.Request ApiResponse
privateApiRequest endpoints token =
    { method = "GET"
    , headers =
        [ Http.header "Authorization" ("Bearer " ++ token) ]
    , url = endpoints.privateExample
    , body = Http.emptyBody
    , expect = Http.expectJson decodeMsg
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request


getPrivateApi : Endpoints -> String -> Cmd Msg
getPrivateApi endpoints token =
    Http.send PrivateApiMessage (privateApiRequest endpoints token)


decodeMsg : Decoder ApiResponse
decodeMsg =
    Json.Decode.Pipeline.decode ApiResponse
        |> Json.Decode.Pipeline.optional "message" string "No message"

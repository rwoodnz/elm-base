port module App exposing (..)

import Common exposing (..)
import External exposing (..)
import Auth.App
import Auth.External
import Auth.Common
import Bootstrap.Navbar as Navbar
import UrlParser exposing ((</>))
import Navigation exposing (Location)
import Bootstrap.Dropdown as Dropdown
import Time exposing (Time, every, second, minute)
import Task
import Process


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
                }
            , authenticationRequired = True
            , authenticationModel = Auth.Common.NotLoggedIn
            , navbarState = navbarState
            , page = Home
            , dropdownState = Dropdown.initialState
            , globalAlerts = []
            , existingLoginHasBeenChecked = False
            , theTime = 0
            , endpoints = { publicExample = "", privateExample = "" }
            }

        ( navbarState, navBarCmd ) =
            Navbar.initialState NavbarMsg

        ( model, urlCmd ) =
            urlUpdate location initModel
    in
        ( model
        , Cmd.batch
            [ Auth.External.getLoggedInUser ()
            , urlCmd
            , navBarCmd
            , getEndpoints ()
            , setTokenCheck model
            , updateTime
            ]
        )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveTime time ->
            ( { model | theTime = time }, Cmd.none )

        ReceiveMaybeLoggedInUser maybeLoggedInUser ->
            case maybeLoggedInUser of
                Just user ->
                    ( { model
                        | authenticationModel = Auth.Common.LoggedIn user
                        , existingLoginHasBeenChecked = True
                      }
                    , setTokenCheck model
                    )

                Nothing ->
                    ( { model
                        | authenticationModel = Auth.Common.NotLoggedIn
                        , existingLoginHasBeenChecked = True
                      }
                    , if model.authenticationRequired then
                        Auth.External.showLock
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
            ( { model | authenticationModel = Auth.Common.NotLoggedIn }
            , Cmd.batch
                [ Auth.External.removeLoggedInUser ()
                , Auth.External.showLock
                ]
            )

        LogIn ->
            ( model, Auth.External.showLock )

        ReceiveAuthentication result ->
            let
                ( newAuthenticationModel, error ) =
                    Auth.App.handleReceiveAuthentication result
            in
                ( { model
                    | authenticationModel = newAuthenticationModel
                  }
                , case newAuthenticationModel of
                    Auth.Common.LoggedIn user ->
                        Cmd.batch
                            [ Auth.External.storeLoggedInUser user
                            , setTokenCheck model
                            ]

                    Auth.Common.NotLoggedIn ->
                        Cmd.none
                )

        CallPrivateApi ->
            case model.authenticationModel of
                Auth.Common.NotLoggedIn ->
                    setAlert model "Not logged in" (5 * minute)

                Auth.Common.LoggedIn user ->
                    ( model, (getPrivateApi model.endpoints user.token) )

        CallPublicApi ->
            ( model, (getPublicApi model.endpoints) )

        PublicApiMessage response ->
            case response of
                Ok apiMessage ->
                    setAlert model apiMessage.message (1 * minute)

                Err errorMessage ->
                    setAlert model "Data could not be retrieved from the public API" (1 * minute)

        PrivateApiMessage result ->
            case result of
                Ok apiMessage ->
                    setAlert model apiMessage.message (1 * minute)

                Err errorMessage ->
                    setAlert model "Data could not be retrieved from the private API" (1 * minute)

        ReceiveEndpoints endpoints ->
            ( { model | endpoints = endpoints }, Cmd.none )

        CheckToken ->
            if
                model.authenticationRequired
                    && Auth.App.tokenExpiryTime model.authenticationModel
                    <= (model.theTime)
            then
                ( model, Auth.External.showLock )
            else
                ( model, setTokenCheck model )

        DismissAlert alert ->
            ( { model
                | globalAlerts =
                    List.filter (\item -> item /= alert) model.globalAlerts
              }
            , Cmd.none
            )



-- TIME CONTROL

-- Time is only updated on a set cycle, so sometimes need to update it additionally
updateTime : Cmd Msg
updateTime =
    Task.perform ReceiveTime Time.now


setAlert : Model -> String -> Time -> ( Model, Cmd Msg )
setAlert model alertMsg duration =
    let
        alert =
            { message = alertMsg, expiry = model.theTime + duration }
    in
        ( { model
            | globalAlerts = alert :: model.globalAlerts
          }
        , Cmd.batch
            [ setTimeCheck
                duration
                (DismissAlert alert)
            , updateTime
            ]
        )


setTokenCheck : Model -> Cmd Msg
setTokenCheck model =
    let
        duration =
            Auth.App.tokenExpiryTime model.authenticationModel - model.theTime
    in
        setTimeCheck
            duration
            CheckToken


setTimeCheck : Time -> Msg -> Cmd Msg
setTimeCheck duration msg =
    Task.perform (\_ -> msg) (Process.sleep duration)



-- ROUTING


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
        , Auth.External.receiveMaybeLoggedInUser ReceiveMaybeLoggedInUser
        , Auth.External.getAuthResult ReceiveAuthentication
        , every (5 * second) ReceiveTime
        , receiveEndpoints ReceiveEndpoints
        ]

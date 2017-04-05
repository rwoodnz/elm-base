module Common exposing (..)

import Auth.Common
import Time exposing (Time)
import Bootstrap.Navbar as Navbar
import Bootstrap.Dropdown as Dropdown
import Http
import Navigation exposing (Location)


type Msg
    = UrlChange Location
    | NavbarMsg Navbar.State
    | DropdownMsg Dropdown.State
    | LogOut
    | LogIn
    | ReceiveMaybeLoggedInUser (Maybe Auth.Common.LoggedInUser)
    | ReceiveAuthentication Auth.Common.AuthenticationResult
    | CallPrivateApi
    | CallPublicApi
    | PublicApiMessage (Result Http.Error ApiResponse)
    | PrivateApiMessage (Result Http.Error ApiResponse)
    | ReceiveTime Time
    | ReceiveEndpoints Endpoints
    | CloseGLobalAlert
    | TokenCheck


type Page
    = Home
    | About
    | NotFound


type alias Alert =
    { message : String
    , start : Time
    , duration : Time
    }


type alias Endpoints =
    { publicExample : String, privateExample : String }


type alias ApiResponse =
    { message : String }


-- CONSTANTS

emptyAlert : Alert
emptyAlert =
    Alert "" 0 0
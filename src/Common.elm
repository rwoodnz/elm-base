module Common exposing (..)

import Auth.Common
import Time exposing (Time)
import Bootstrap.Navbar as Navbar
import Bootstrap.Dropdown as Dropdown
import Http
import Navigation exposing (Location)


type alias Model =
    { page : Page
    , navbarState : Navbar.State
    , flags : Flags
    , dropdownState : Dropdown.State
    , authenticationRequired : Bool
    , authenticationModel : Auth.Common.AuthenticationModel
    , globalAlert : Alert
    , existingLoginHasBeenChecked : Bool
    , theTime : Time
    , endpoints : Endpoints
    }


type alias Flags =
    { staticAssetsPath : String
    , startTime : Time
    }


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

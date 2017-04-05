port module Auth.External exposing (..)

import Auth.Common exposing (..)



-- STORAGE PORTS

port storeLoggedInUser : LoggedInUser -> Cmd msg


port removeLoggedInUser : () -> Cmd msg


port getLoggedInUser : () -> Cmd msg


port receiveMaybeLoggedInUser : (Maybe LoggedInUser -> msg) -> Sub msg


-- AUTHENTICATION PORTS


type alias Options =
    {}


port auth0showLock : Options -> Cmd msg


showLock : Cmd msg
showLock =
    auth0showLock {}


port auth0authResult : (AuthenticationResult -> msg) -> Sub msg


getAuthResult : (AuthenticationResult -> msg) -> Sub msg
getAuthResult =
    auth0authResult
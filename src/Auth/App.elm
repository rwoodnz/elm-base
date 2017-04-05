port module Auth.App exposing (..)

-- Uses Auth0

import Auth.Common exposing (..)
import Jwt exposing (decodeToken)
import Json.Decode exposing (field, float)
import Time


-- Authentication process


handleReceiveAuthentication :
    AuthenticationResult
    -> ( AuthenticationModel, Maybe AuthenticationError )
handleReceiveAuthentication result =
    case ( result.err, result.ok ) of
        ( Just err, _ ) ->
            ( NotLoggedIn, Just err )

        ( Nothing, Nothing ) ->
            ( NotLoggedIn
            , Just
                { name = Nothing
                , code = Nothing
                , statusCode = Nothing
                , description = "No information received from authentication provider"
                }
            )

        ( Nothing, Just user ) ->
            ( LoggedIn user, Nothing )


isLoggedIn : AuthenticationModel -> Bool
isLoggedIn authenticationModel =
    case authenticationModel of
        LoggedIn _ ->
            True

        NotLoggedIn ->
            False


tokenExpiryTime : AuthenticationModel -> Time.Time
tokenExpiryTime authenticationModel =
    let
        value =
            case authenticationModel of
                LoggedIn user ->
                    tokenExpiry user.token

                _ ->
                    Ok 0
    in
        Result.withDefault 0 value * 1000


tokenExpiry : String -> Result Jwt.JwtError Time.Time
tokenExpiry token =
    Jwt.decodeToken (field "exp" float) token

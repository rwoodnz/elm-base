-- Uses Auth0
port module Auth
    exposing
        ( AuthenticationModel(..)
        , AuthenticationResult
        , LoggedInUser
        , showLock
        , getAuthResult
        , isLoggedIn
        , handleReceiveAuthentication
        , tokenExpiryTime
        )

import Jwt exposing (decodeToken)
import Json.Decode exposing (field, float) 
import Time

-- MODELS


type AuthenticationModel
    = NotLoggedIn
    | LoggedIn LoggedInUser


type alias LoggedInUser =
    { profile : UserProfile
    , token : Token
    }


type alias UserProfile =
    { email : String
    , email_verified : Bool
    , name : String
    , nickname : String
    , picture : String
    , user_id : String
    }


type alias Token =
    String

-- Authentication process


type alias AuthenticationError =
    { name : Maybe String
    , code : Maybe String
    , description : String
    , statusCode : Maybe Int
    }


type alias AuthenticationResult =
    { err : Maybe AuthenticationError
    , ok : Maybe LoggedInUser
    }


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

tokenExpiry: String -> Result Jwt.JwtError Float
tokenExpiry token = 
    Jwt.decodeToken (field "exp" float) token


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

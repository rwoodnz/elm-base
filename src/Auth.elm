-- Uses Auth0

port module Auth
    exposing
        ( AuthenticationModel(..)
        , AuthenticationResult
        , LoggedInUser
        , showLock
        , getAuthResult
        , isLoggedIn
        , handleAuthenticationRawResult
        , storeLoggedInUser
        , removeLoggedInUser
        , getLoggedInUser
        , receiveMaybeLoggedInUser
        )

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


handleAuthenticationRawResult : AuthenticationResult -> AuthenticationModel
handleAuthenticationRawResult result =
    let
        ( newAuthenticationModel, error ) =
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
    in
        newAuthenticationModel


isLoggedIn : AuthenticationModel -> Bool
isLoggedIn authenticationModel =
    case authenticationModel of
        LoggedIn _ ->
            True

        NotLoggedIn ->
            False



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



-- LOCAL BROWSER STORAGE PORTS


port storeLoggedInUser : LoggedInUser -> Cmd msg


port removeLoggedInUser : () -> Cmd msg


port getLoggedInUser : () -> Cmd msg


port receiveMaybeLoggedInUser : (Maybe LoggedInUser -> msg) -> Sub msg

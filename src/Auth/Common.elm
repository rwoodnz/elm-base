module Auth.Common exposing (..)


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


type alias AuthenticationResult =
    { err : Maybe AuthenticationError
    , ok : Maybe LoggedInUser
    }


type alias AuthenticationError =
    { name : Maybe String
    , code : Maybe String
    , description : String
    , statusCode : Maybe Int
    }

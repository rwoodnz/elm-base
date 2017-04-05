port module External exposing (..)

import Common exposing (..)

import Http
import Json.Decode exposing (string, field, decodeString, Decoder, float)
import Json.Decode.Pipeline exposing (decode, required)


-- HTTP


port getEndpoints : () -> Cmd msg


port receiveEndpoints : (Endpoints -> msg) -> Sub msg


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



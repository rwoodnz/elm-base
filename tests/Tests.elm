module Tests exposing (..)

import Test exposing (..)
import Expect
import App
import Test.Html.Query as Query
import Test.Html.Selector exposing (text, tag)


all : Test
all =
    describe "Test Suite"
        [ describe "type alias"
            [ test "Flags contain static assets path" <|
                \() ->
                    Expect.equal "/path/" (App.Flags "/path/").staticAssetsPath
            ]
        , describe "Initial setup"
            [
            test "App.model.page should be set to home" <|
                \()->
                    let 
                        flags = App.Flags "/path/"

                        location = { href = ""
                            , host = ""
                            , hostname = ""
                            , protocol = ""
                            , origin = ""
                            , port_ = ""
                            , pathname = ""
                            , search = ""
                            , hash = ""
                            , username = ""
                            , password = "" 
                            }

                        model = Tuple.first (App.init flags  location)
                    in
                    Expect.equal model.page App.Home
              ]
        , describe "about page"
            [ test "About page contains about title" <|
                \() -> 
                    App.pageAbout
                    |> Query.fromHtml
                    |> Query.find [ tag "h3" ]
                    |> Query.has [ text "About" ]
            ]
        -- , describe "home page"
        --     [ test "Home page contains Home title" <|
        --         \() -> 
        --             App.pageHome { flags = (App.Flags "/path/" )}
        --             |> Query.fromHtml
        --             |> Query.find [ tag "h3" ]
        --             |> Query.has [ text "Home" ]
        --     ]
        ]
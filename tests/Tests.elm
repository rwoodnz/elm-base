module Tests exposing (..)

import Test exposing (..)
import Expect
import App
import Test.Html.Query as Query
import Test.Html.Selector exposing (text, tag)
import Time exposing (millisecond)


all : Test
all =
    describe "Test Suite"
        [ describe "Initial setup"
            [
            test "App.model.page should be set to home" <|
                \()->
                    let 
                        flags = App.Flags "/path/" (1491214218028 * millisecond)

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

                        model = Tuple.first (App.init flags location)
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
        --             App.pageHome _
        --             |> Query.fromHtml
        --             |> Query.find [ tag "h3" ]
        --             |> Query.has [ text "Home" ]
        --     ]
        ]
module Tests exposing (..)

import Test exposing (..)
import Expect
import App
import Html exposing (..)
import Bootstrap.Navbar as Navbar


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
            [ test "About page contains about" <|
                \() ->
                    let
                        ( navbarState, navCmd ) =
                            Navbar.initialState App.NavbarMsg

                        model =
                            { page = App.About
                            , navbarState = navbarState
                            , flags = { staticAssetsPath = "/path/"
                            }}
                    in
                        App.pageAbout model
                            |> Expect.equal ([ h2 [] [ text "About" ] ])
            ]
        ]
    
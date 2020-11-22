module Pages.Counter exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , title
    , update
    , view
    )

import Browser.Events
import Color
import Color.Accessibility
import Color.Convert
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Markdown
import R10.Button
import R10.Color
import R10.Color.AttrsBackground
import R10.Color.AttrsBorder
import R10.Color.AttrsFont
import R10.Color.Svg
import R10.Color.Utils
import R10.Counter
import R10.FontSize
import R10.Form
import R10.FormComponents
import R10.I18n
import R10.Language
import R10.LanguageSelector
import R10.Libu
import R10.Mode
import R10.Okaimonopanda
import R10.Paragraph
import R10.Svg.Icons
import R10.Svg.Lists
import R10.Theme
import R10.Translations
import Time


title : R10.Language.Translations
title =
    { key = "title"
    , en_us = "Counter"
    , ja_jp = "カウンター"
    , zh_tw = "Counter"
    , es_es = "Counter"
    , fr_fr = "Counter"
    , de_de = "Counter"
    , it_it = "Counter"
    , nl_nl = "Counter"
    , pt_pt = "Counter"
    , nb_no = "Counter"
    , fi_fl = "Counter"
    , da_dk = "Counter"
    , sv_se = "Counter"
    }


type alias Model =
    { counter : R10.Counter.Counter }


init : Model
init =
    { counter =
        R10.Counter.init
            |> R10.Counter.start
    }


type Msg
    = OnAnimationFrame Time.Posix
    | GoTo Int
    | Add Int


update : Msg -> Model -> Model
update msg model =
    case msg of
        OnAnimationFrame _ ->
            { model | counter = R10.Counter.update model.counter }

        GoTo value ->
            { model | counter = R10.Counter.moveTo value model.counter }

        Add value ->
            { model | counter = R10.Counter.add value model.counter }


view : Model -> R10.Theme.Theme -> List (Element Msg)
view model theme =
    [ el [ Font.family [ Font.monospace ] ] <| R10.Counter.view model.counter 100
    , row [ spacing 20 ]
        [ R10.Button.secondary [ width shrink ]
            { label = text "Jump To 10"
            , libu = R10.Libu.Bu <| Just <| GoTo 10
            , theme = theme
            }
        , R10.Button.secondary [ width shrink ]
            { label = text "Jump To 0"
            , libu = R10.Libu.Bu <| Just <| GoTo 0
            , theme = theme
            }
        , R10.Button.secondary [ width shrink ]
            { label = text "Add 10"
            , libu = R10.Libu.Bu <| Just <| Add 10
            , theme = theme
            }
        , R10.Button.secondary [ width shrink ]
            { label = text "Add 94,851"
            , libu = R10.Libu.Bu <| Just <| Add 94857
            , theme = theme
            }
        , R10.Button.secondary [ width shrink ]
            { label = text "Subtract 10"
            , libu = R10.Libu.Bu <| Just <| Add -10
            , theme = theme
            }
        ]
    ]



-- COUNTER


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        if R10.Counter.areMoving [ model.counter ] then
            [ Browser.Events.onAnimationFrame OnAnimationFrame ]

        else
            []

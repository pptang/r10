port module Main exposing (conf, main)

import Browser
import Browser.Events
import Color
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Html
import Html.Attributes
import Json.Decode
import Pages.Counter
import Pages.Form_Boilerplate
import Pages.Form_Entities
import Pages.Form_Example_CreditCard
import Pages.Form_Example_PhoneSelector
import Pages.Form_Example_Table
import Pages.Form_FieldType_Binary
import Pages.Form_FieldType_Multi
import Pages.Form_FieldType_Single
import Pages.Form_FieldType_Text
import Pages.Form_Introduction
import Pages.Form_States
import Pages.Overview
import Pages.Shared.Utils
import Pages.TableExample
import Pages.Top
import Pages.UIComponents
import R10.Card
import R10.Color
import R10.Color.AttrsBackground
import R10.Color.AttrsFont
import R10.Color.Internal.Primary
import R10.Color.Svg
import R10.Color.Utils
import R10.Footer
import R10.Form
import R10.Header
import R10.I18n
import R10.Language
import R10.Libu
import R10.Mode
import R10.Okaimonopanda
import R10.Svg.IconsExtra
import R10.Svg.LogosExtra
import R10.Theme
import Starter.ConfMain
import Starter.Flags
import Url
import Url.Parser exposing ((</>))


heroColor : R10.Theme.Theme -> Color
heroColor theme =
    -- R10.Color.Utils.colorToElementColor <|
    --     R10.Color.Internal.Primary.toColor { mode = R10.Mode.Light } R10.Color.Primary.Blue
    -- rgb255 18 147 216
    -- rgb255 17 123 180
    R10.Color.Utils.colorToElementColor <| R10.Color.Svg.primary theme


heroBackgroundColor : R10.Theme.Theme -> Attr decorative msg
heroBackgroundColor theme =
    Background.color <| heroColor theme


type alias Flags =
    { starter : Starter.Flags.Flags
    , width : Int
    , height : Int
    , languages : List String
    , locationHref : String
    , isInternetExplorer : Bool
    , sessionCookieExists : Bool
    }


positionDecoder : Json.Decode.Decoder Position
positionDecoder =
    Json.Decode.map2 Position
        (Json.Decode.field "pageX" Json.Decode.int)
        (Json.Decode.field "pageY" Json.Decode.int)


type alias Position =
    { x : Int, y : Int }


type alias Model =
    { route : Route
    , flags : Flags
    , windowSize : Position
    , mouse : Position
    , isTop : Bool
    , theme : R10.Theme.Theme
    , header : R10.Header.Header

    -- PAGES
    --
    , pageOverview : Pages.Overview.Model
    , pageForm_Entities : Pages.Form_Entities.Model
    , pageForm_Example_CreditCard : Pages.Form_Example_CreditCard.Model
    , pageForm_Boilerplate : Pages.Form_Boilerplate.Model
    , pageForm_Example_Table : Pages.Form_Example_Table.Model
    , pageForm_Example_PhoneSelector : Pages.Form_Example_PhoneSelector.Model
    , pageForm_States : Pages.Form_States.Model

    --
    , pageForm_FieldType_Text : Pages.Form_FieldType_Text.Model
    , pageForm_FieldType_Single : Pages.Form_FieldType_Single.Model
    , pageForm_FieldType_Multi : Pages.Form_FieldType_Multi.Model
    , pageForm_FieldType_Binary : Pages.Form_FieldType_Binary.Model

    --
    , pageForm_Introduction : Pages.Form_Introduction.Model
    , pageUIComponents : Pages.UIComponents.Model
    , pageCounter : Pages.Counter.Model
    , pageTableExample : Pages.TableExample.Model
    }


conf : Starter.ConfMain.Conf
conf =
    { urls = listForSSR
    , assetsToCache = []
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        debuggingMode =
            -- flags.locationHref
            --     |> Url.fromString
            --     |> Maybe.map (\url -> url.host == "localhost")
            --     |> Maybe.withDefault False
            False

        route =
            fromLocationHref flags.locationHref

        header =
            R10.Header.init
    in
    ( { route = route
      , flags = flags
      , windowSize = { x = flags.width, y = flags.height }
      , mouse = { x = flags.width // 2, y = flags.height // 2 }
      , isTop = True
      , theme = initTheme
      , header =
            { header
                | debuggingMode = debuggingMode
                , userMenuOpen = False
                , backgroundColor = Just <| heroColor initTheme
                , session = R10.Header.SessionNotRequired
                , supportedLanguageList = languageSupportedList
            }
      , pageOverview = Pages.Overview.init
      , pageForm_Entities = Pages.Form_Entities.init
      , pageForm_Example_CreditCard = Pages.Form_Example_CreditCard.init
      , pageForm_Boilerplate = Pages.Form_Boilerplate.init
      , pageForm_Example_Table = Pages.Form_Example_Table.init
      , pageForm_Example_PhoneSelector = Pages.Form_Example_PhoneSelector.init
      , pageForm_States = Pages.Form_States.init

      --
      , pageForm_FieldType_Text = Pages.Form_FieldType_Text.init
      , pageForm_FieldType_Single = Pages.Form_FieldType_Single.init
      , pageForm_FieldType_Multi = Pages.Form_FieldType_Multi.init
      , pageForm_FieldType_Binary = Pages.Form_FieldType_Binary.init

      --
      -- TODO - Add local storage
      , pageForm_Introduction = Pages.Form_Introduction.init { localStorage = Dict.empty }
      , pageUIComponents = Pages.UIComponents.init
      , pageCounter = Pages.Counter.init
      , pageTableExample = Pages.TableExample.init
      }
    , updateHtmlMeta flags.starter route
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ onUrlChange (fromLocationHref >> UrlChanged)
         , Browser.Events.onResize WindowResize
         , onChangeIsTop OnChangeIsTop
         ]
            ++ R10.Header.subscriptions model.header Header
            ++ (-- Pages with Okaimonopanda need to have the mouse muvement
                -- detected to make the panda to move.
                case model.route of
                    NotFound _ ->
                        [ Browser.Events.onMouseMove (Json.Decode.map MouseMove positionDecoder) ]

                    Route_Overview _ ->
                        [ Browser.Events.onMouseMove (Json.Decode.map MouseMove positionDecoder) ]

                    Route_Counter _ ->
                        [ Sub.map Msg_Counter <| Pages.Counter.subscriptions model.pageCounter ]

                    _ ->
                        []
               )
        )



-- MESSAGES


type Msg
    = OnClick String
    | UrlChanged Route
    | WindowResize Int Int
    | OnChangeIsTop Bool
    | ChangePrimaryColor R10.Color.Primary
    | MouseMove Position
    | ToggleMode
    | Header R10.Header.Msg
      --
    | Msg_Overview Pages.Overview.Msg
    | Msg_Form_Entities Pages.Form_Entities.Msg
    | Msg_Form_Example_CreditCard Pages.Form_Example_CreditCard.Msg
    | Msg_Form_Boilerplate Pages.Form_Boilerplate.Msg
    | Msg_Form_Example_Table Pages.Form_Example_Table.Msg
    | Msg_Form_Example_PhoneSelector Pages.Form_Example_PhoneSelector.Msg
    | Msg_Form_States Pages.Form_States.Msg
      --
    | Msg_Form_FieldType_Text Pages.Form_FieldType_Text.Msg
    | Msg_Form_FieldType_Single Pages.Form_FieldType_Single.Msg
    | Msg_Form_FieldType_Multi Pages.Form_FieldType_Multi.Msg
    | Msg_Form_FieldType_Binary Pages.Form_FieldType_Binary.Msg
      --
    | Msg_Form_Introduction Pages.Form_Introduction.Msg
    | Msg_UIComponents Pages.UIComponents.Msg
    | Msg_Counter Pages.Counter.Msg
    | Msg_PagesTable Pages.TableExample.Msg



-- UPDATE


updateHtmlMeta : Starter.Flags.Flags -> Route -> Cmd msg
updateHtmlMeta flagsStarter route =
    Cmd.batch
        [ changeMeta ( "title", "innerHTML", flagsStarter.nameLong )
        , changeMeta ( "meta[property='og:image']", "content", flagsStarter.homepage ++ routeToPathWithoutLanguage route ++ "/snapshot.jpg" )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangePrimaryColor primaryColor ->
            let
                theme =
                    model.theme

                newTheme =
                    { theme | primaryColor = primaryColor }
            in
            ( { model | theme = newTheme }, Cmd.none )

        ToggleMode ->
            let
                theme =
                    model.theme

                newTheme =
                    { theme | mode = R10.Mode.toggle theme.mode }
            in
            ( { model | theme = newTheme }, Cmd.none )

        Msg_Overview pageMsg ->
            ( { model | pageOverview = Pages.Overview.update pageMsg model.pageOverview }, Cmd.none )

        Msg_Form_Entities pageMsg ->
            ( { model | pageForm_Entities = Pages.Form_Entities.update pageMsg model.pageForm_Entities }, Cmd.none )

        Msg_Form_Example_CreditCard pageMsg ->
            ( { model | pageForm_Example_CreditCard = Pages.Form_Example_CreditCard.update pageMsg model.pageForm_Example_CreditCard }, Cmd.none )

        Msg_Form_Boilerplate pageMsg ->
            ( { model | pageForm_Boilerplate = Pages.Form_Boilerplate.update pageMsg model.pageForm_Boilerplate }, Cmd.none )

        Msg_Form_Example_Table pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_Example_Table.update pageMsg model.pageForm_Example_Table
            in
            ( { model | pageForm_Example_Table = modelPageExample }, Cmd.map Msg_Form_Example_Table cmdPageExample )

        Msg_Form_Example_PhoneSelector pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_Example_PhoneSelector.update pageMsg model.pageForm_Example_PhoneSelector
            in
            ( { model | pageForm_Example_PhoneSelector = modelPageExample }, Cmd.map Msg_Form_Example_PhoneSelector cmdPageExample )

        Msg_Form_FieldType_Single pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_FieldType_Single.update pageMsg model.pageForm_FieldType_Single
            in
            ( { model | pageForm_FieldType_Single = modelPageExample }, Cmd.map Msg_Form_FieldType_Single cmdPageExample )

        Msg_Form_States pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_States.update pageMsg model.pageForm_States
            in
            ( { model | pageForm_States = modelPageExample }, Cmd.map Msg_Form_States cmdPageExample )

        Msg_Form_FieldType_Text pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_FieldType_Text.update pageMsg model.pageForm_FieldType_Text
            in
            ( { model | pageForm_FieldType_Text = modelPageExample }, Cmd.map Msg_Form_FieldType_Text cmdPageExample )

        Msg_Form_FieldType_Multi pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_FieldType_Multi.update pageMsg model.pageForm_FieldType_Multi
            in
            ( { model | pageForm_FieldType_Multi = modelPageExample }, Cmd.map Msg_Form_FieldType_Multi cmdPageExample )

        Msg_Form_FieldType_Binary pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_FieldType_Binary.update pageMsg model.pageForm_FieldType_Binary
            in
            ( { model | pageForm_FieldType_Binary = modelPageExample }, Cmd.map Msg_Form_FieldType_Binary cmdPageExample )

        Msg_Form_Introduction pageMsg ->
            let
                ( modelPageExample, cmdPageExample ) =
                    Pages.Form_Introduction.update pageMsg model.pageForm_Introduction
            in
            ( { model | pageForm_Introduction = modelPageExample }, Cmd.map Msg_Form_Introduction cmdPageExample )

        Msg_UIComponents pageMsg ->
            let
                modelPageExample =
                    Pages.UIComponents.update pageMsg model.pageUIComponents
            in
            ( { model | pageUIComponents = modelPageExample }, Cmd.none )

        Msg_Counter pageMsg ->
            let
                modelPageExample =
                    Pages.Counter.update pageMsg model.pageCounter
            in
            ( { model | pageCounter = modelPageExample }, Cmd.none )

        Msg_PagesTable pageMsg ->
            let
                modelPageExample =
                    Pages.TableExample.update pageMsg model.pageTableExample
            in
            ( { model | pageTableExample = modelPageExample }, Cmd.none )

        MouseMove mouse ->
            ( { model | mouse = mouse }, Cmd.none )

        Header headerMsg ->
            ( { model | header = R10.Header.update headerMsg model.header }, Cmd.none )

        OnChangeIsTop isTop ->
            ( { model | isTop = isTop }, Cmd.none )

        WindowResize width height ->
            ( { model | windowSize = { x = width, y = height } }, Cmd.none )

        OnClick path ->
            ( model, pushUrl path )

        UrlChanged route ->
            ( { model
                | route = route
                , header = R10.Header.closeMenu model.header
              }
            , updateHtmlMeta model.flags.starter route
            )



-- PORTS


port onUrlChange : (String -> msg) -> Sub msg


port pushUrl : String -> Cmd msg


port changeMeta : ( String, String, String ) -> Cmd msg


port onChangeIsTop : (Bool -> msg) -> Sub msg



-- VIEW HELPERS


view : Model -> Html.Html Msg
view model =
    let
        language =
            routeToLanguage model.route
    in
    Html.div
        [ Html.Attributes.id "elm" ]
        [ Html.node "style" [] [ Html.text (css model.theme) ]
        , Html.a [ Html.Attributes.class "skip-link", Html.Attributes.href "#main" ]
            [ Html.text "Skip to main" ]
        , layoutWith
            { options =
                [ focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ Font.family []
            , Font.size 18
            , R10.Color.AttrsFont.normal model.theme
            , R10.Color.AttrsBackground.background model.theme
            , htmlAttribute <| Html.Attributes.style "transition" "background-color 1.2s"
            , inFront <| viewHeader model
            ]
          <|
            case model.route of
                RouteTop _ ->
                    column [ width fill ]
                        [ Pages.Top.view
                            model.theme
                            (routeToLanguage model.route)
                            (heroBackgroundColor model.theme)
                            (links model.route language)
                            OnClick
                        , viewFooter model
                        ]

                Route_Overview lang ->
                    let
                        mouse =
                            model.mouse

                        mouseCorrected =
                            -- This correction depend on the vertical position
                            -- of the panda in the page
                            { mouse | y = mouse.y - 7000 }
                    in
                    mainLayout model Pages.Overview.title (List.map (map Msg_Overview) (Pages.Overview.view model.pageOverview model.theme mouseCorrected model.windowSize))

                Route_Form_Entities lang ->
                    mainLayout model Pages.Form_Entities.title (List.map (map Msg_Form_Entities) (Pages.Form_Entities.view model.pageForm_Entities model.theme))

                Route_Form_Example_CreditCard lang ->
                    mainLayout model Pages.Form_Example_CreditCard.title (List.map (map Msg_Form_Example_CreditCard) (Pages.Form_Example_CreditCard.view model.pageForm_Example_CreditCard model.theme))

                Route_Form_Boilerplate lang ->
                    mainLayout model Pages.Form_Boilerplate.title (List.map (map Msg_Form_Boilerplate) (Pages.Form_Boilerplate.view model.pageForm_Boilerplate model.theme))

                Route_Form_Example_Table lang ->
                    mainLayout model Pages.Form_Example_Table.title (List.map (map Msg_Form_Example_Table) (Pages.Form_Example_Table.view model.pageForm_Example_Table model.theme))

                Route_Form_Example_PhoneSelector lang ->
                    mainLayout model Pages.Form_Example_PhoneSelector.title (List.map (map Msg_Form_Example_PhoneSelector) (Pages.Form_Example_PhoneSelector.view model.pageForm_Example_PhoneSelector model.theme))

                Route_Form_FieldType_Single lang ->
                    mainLayout model Pages.Form_FieldType_Single.title (List.map (map Msg_Form_FieldType_Single) (Pages.Form_FieldType_Single.view model.pageForm_FieldType_Single model.theme))

                Route_Form_States lang ->
                    mainLayout model Pages.Form_States.title (List.map (map Msg_Form_States) (Pages.Form_States.view model.pageForm_States model.theme))

                Route_Form_FieldType_Text lang ->
                    mainLayout model Pages.Form_FieldType_Text.title (List.map (map Msg_Form_FieldType_Text) (Pages.Form_FieldType_Text.view model.pageForm_FieldType_Text model.theme))

                Route_Form_FieldType_Multi lang ->
                    mainLayout model Pages.Form_FieldType_Multi.title (List.map (map Msg_Form_FieldType_Multi) (Pages.Form_FieldType_Multi.view model.pageForm_FieldType_Multi model.theme))

                Route_Form_FieldType_Binary lang ->
                    mainLayout model Pages.Form_FieldType_Binary.title (List.map (map Msg_Form_FieldType_Binary) (Pages.Form_FieldType_Binary.view model.pageForm_FieldType_Binary model.theme))

                Route_Form_Introduction lang ->
                    mainLayout model Pages.Form_Introduction.title (List.map (map Msg_Form_Introduction) (Pages.Form_Introduction.view model.pageForm_Introduction model.theme))

                Route_UIComponents lang ->
                    mainLayout model Pages.UIComponents.title (List.map (map Msg_UIComponents) (Pages.UIComponents.view model.pageUIComponents model.theme))

                Route_Counter lang ->
                    mainLayout model Pages.Counter.title (List.map (map Msg_Counter) (Pages.Counter.view model.pageCounter model.theme))

                Route_TableExample lang ->
                    mainLayout model Pages.TableExample.title (List.map (map Msg_PagesTable) (Pages.TableExample.view model.pageTableExample model.theme))

                NotFound lang ->
                    mainLayout model translationsError <|
                        [ row [ centerX, spacing 50 ]
                            [ el [] <|
                                html <|
                                    Html.div [] <|
                                        R10.Okaimonopanda.view
                                            { mouse = model.mouse
                                            , screen = model.windowSize
                                            }
                            , column [ alignTop ]
                                [ el
                                    [ Font.bold
                                    , Font.color <| rgb 0.8 0 0
                                    , Font.size 90
                                    ]
                                  <|
                                    text "404"
                                , paragraph [] [ text "Page not found" ]
                                ]
                            ]
                        ]
        ]


headerPlaceholder : Element msg
headerPlaceholder =
    -- TODO - Make the height variable the same as the header
    el [ height <| px 80, width fill ] none


transitionOpacity : Attribute msg
transitionOpacity =
    htmlAttribute <| Html.Attributes.style "transition" "opacity 0.3s"


viewHeader : Model -> Element Msg
viewHeader model =
    let
        language =
            routeToLanguage model.route
    in
    R10.Header.view model.header (headerFooterArgs model)


logoOnDark : Element msg
logoOnDark =
    R10.Svg.LogosExtra.r10 [ moveUp 4 ] (Color.rgb 1 1 1) 24


logoOnLight : Element msg
logoOnLight =
    R10.Svg.LogosExtra.r10 [ moveUp 4 ] (Color.rgb 0 0 0) 24


colorsMenu : R10.Theme.Theme -> Element Msg
colorsMenu theme =
    row [ spacing 1, centerX ] <|
        List.map
            (\{ color, name, type_ } ->
                R10.Libu.view
                    [ width shrink
                    , padding 0
                    , htmlAttribute <| Html.Attributes.style "transition" "0.4s"
                    , Font.color <| R10.Color.Utils.colorToElementColor <| R10.Color.Svg.primary { theme | primaryColor = type_ }
                    , centerY
                    , moveUp <|
                        if theme.primaryColor == type_ then
                            2

                        else
                            0
                    , Font.size <|
                        if theme.primaryColor == type_ then
                            30

                        else
                            16
                    ]
                <|
                    { label = text "⬤"
                    , type_ = R10.Libu.Bu <| Just <| ChangePrimaryColor type_
                    }
            )
            (R10.Color.listPrimary theme)


headerFooterArgs : Model -> R10.Header.ViewArgs Msg Route
headerFooterArgs model =
    { extraContent = links model.route (routeToLanguage model.route)
    , extraContentRightSide =
        [ row [ spacing 20 ]
            [ colorsMenu model.theme
            , R10.Libu.view
                [ alpha 0.8
                , transitionOpacity
                , mouseOver [ alpha 1 ]
                , htmlAttribute <| Html.Attributes.style "transition" "1s"
                , rotate
                    (if R10.Mode.isLight model.theme.mode then
                        pi

                     else
                        0
                    )
                ]
                { label = R10.Svg.IconsExtra.darkLight [] (Color.rgb 1 1 1) 28
                , type_ = R10.Libu.Bu <| Just ToggleMode
                }
            , R10.Libu.view [ alpha 0.8, transitionOpacity, mouseOver [ alpha 1 ] ]
                { label = R10.Svg.LogosExtra.github [] (Color.rgb 1 1 1) 24
                , type_ = R10.Libu.LiNewTab "https://github.com/rakutentech/r10/"
                }
            , R10.Libu.view [ alpha 0.8, transitionOpacity, mouseOver [ alpha 1 ] ]
                { label = R10.Svg.LogosExtra.elm_monocrome [] (Color.rgb 1 1 1) 24
                , type_ = R10.Libu.LiNewTab "https://package.elm-lang.org/packages/rakutentech/r10/latest/"
                }
            ]
        ]
    , msgMapper = Header
    , isTop = model.isTop
    , from = routeToPathWithoutLanguage model.route
    , isMobile = False
    , onClick = OnClick
    , urlTop = "/"
    , languageSystem =
        R10.Header.LanguageInRoute
            { routeToPath = routeToPath
            , route = model.route
            , routeToLanguage = routeToLanguage
            }
    , logoOnDark = logoOnDark
    , logoOnLight = logoOnLight
    , darkHeader = True
    , theme = model.theme
    }


initTheme : R10.Theme.Theme
initTheme =
    { mode = R10.Mode.Light
    , primaryColor = R10.Color.Internal.Primary.BlueSky
    }


viewFooter : Model -> Element Msg
viewFooter model =
    R10.Footer.view model.header (headerFooterArgs model)


mainLayout :
    Model
    -> R10.Language.Translations
    -> List (Element Msg)
    -> Element Msg
mainLayout model title content =
    column [ width fill ]
        [ headerPlaceholder
        , el
            [ paddingEach { top = 40, right = 20, bottom = 40, left = 20 }
            , centerX
            , width fill
            ]
          <|
            column
                (R10.Card.normal model.theme
                    ++ [ centerX
                       , paddingXY 40 40
                       , Pages.Shared.Utils.maxWidth
                       , spacing 40
                       ]
                )
                ([ paragraph [ Font.size 40 ] [ text <| R10.I18n.t (routeToLanguage model.route) title ] ]
                    ++ content
                )
        , viewFooter model
        ]


links : Route -> R10.Language.Language -> List (Element Msg)
links currentRoute currentLanguage =
    List.map
        (\route ->
            let
                url =
                    routeToPathWithoutLanguage (route currentLanguage)

                label =
                    text <| R10.I18n.t currentLanguage (.title (routeDetails (route currentLanguage)))
            in
            if route currentLanguage == currentRoute then
                el
                    (R10.Header.attrsLink
                        ++ [ Font.bold
                           , htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                           ]
                    )
                    label

            else
                R10.Libu.view R10.Header.attrsLink
                    { label = label
                    , type_ = R10.Libu.LiInternal (routeToPathWithoutLanguage (route currentLanguage)) OnClick
                    }
        )
        routesList



-- CSS


css : R10.Theme.Theme -> String
css theme =
    String.join "\n"
        [ cssSkipLink
        , cssCommon
        , cssMarkdown theme
        , R10.Form.extraCss (Just <| R10.Form.themeToPalette theme)
        ]


cssSkipLink : String
cssSkipLink =
    """.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000000;
  color: white;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
"""


cssMarkdown : R10.Theme.Theme -> String
cssMarkdown theme =
    let
        codeBorder =
            case theme.mode of
                R10.Mode.Dark ->
                    "#444"

                R10.Mode.Light ->
                    "#ddd"
    in
    """.markdown {
    white-space: normal;
    line-height: 1.7em;}
.markdown p {margin: 20px 0 !important}

.markdown a {
    color: rgb(17, 123, 180);
}

.markdown pre  {
    background-color: """ ++ R10.Color.Utils.toHex (R10.Color.Svg.surface2dp theme) ++ """; 
    margin: 0;
    line-height: 20px;
    overflow: scroll;
    white-space: pre-wrap;       /* css-3 */
    white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
    white-space: -pre-wrap;      /* Opera 4-6 */
    white-space: -o-pre-wrap;    /* Opera 7 */
    word-wrap: break-word;       /* Internet Explorer 5.5+ */    
    font-size: 14px;
    border-radius: 10px;
    padding: 20px;
    box-sizing: border-box;
    width: 100%;
    border: 1px solid """ ++ codeBorder ++ """;
}

.markdown p code {
    background-color: """ ++ R10.Color.Utils.toHex (R10.Color.Svg.surface2dp theme) ++ """; 
    border: 1px solid """ ++ codeBorder ++ """;
    display: inline-block;
    padding: 0 8px;
    margin: 0 5px;
    border-radius: 8px;
}

.markdown img {
    width: 100%;
}

.markdown.whiteLinks a {
    color: white;
} """


cssCommon : String
cssCommon =
    String.join "\n"
        [ -- This is to fix an issue with IE11
          "#elm * {-ms-overflow-style: -ms-autohiding-scrollbar;}"

        --
        -- "flext is a shorthand for the following CSS properties:
        --
        --     flex-grow     This property specifies how much of the remaining space in the flex container should be assigned to the item (the flex grow factor).
        --                   Default to 0
        --
        --                   flex-grow: inherit;
        --                   flex-grow: initial;
        --                   flex-grow: unset;
        --
        --     flex-shrink
        --     flex-basis
        --
        , """
        @media screen and (-ms-high-contrast: active), (-ms-high-contrast: none) {

            .s {
                flex-basis: auto !important; 
            }

            .s.r > .s {
                flex-basis: 0% !important; 
                /* border: 1px solid red !important; */
            }

            /* Here we add a div so that we became more specific and we */
            /* can overwrite settings from elm-ui                       */

            #ie-flex-fix {
                flex-basis: 0% !important; 
                /* border: 1px solid green !important; */
            }
        }
        """

        -- This is to remove up and down button in an input field
        -- of type "number"
        -- To remove the “clear field” X button when Browser Mode
        , "#elm input::-ms-clear { display: none; }"

        -- Remove selecting icon inside the DropDown in IE
        , "#elm select::-ms-expand { display:none; }"
        ]



-- TRANSLATIONS


translationsError : R10.Language.Translations
translationsError =
    { key = "error"
    , en_us = "Error"
    , ja_jp = "Error"
    , zh_tw = "Error"
    , es_es = "Error"
    , fr_fr = "Error"
    , de_de = "Error"
    , it_it = "Error"
    , nl_nl = "Error"
    , pt_pt = "Error"
    , nb_no = "Error"
    , fi_fl = "Error"
    , da_dk = "Error"
    , sv_se = "Error"
    }


translationR10 : R10.Language.Translations
translationR10 =
    { key = "r10"
    , en_us = "R10"
    , ja_jp = "R10"
    , zh_tw = "R10"
    , es_es = "R10"
    , fr_fr = "R10"
    , de_de = "R10"
    , it_it = "R10"
    , nl_nl = "R10"
    , pt_pt = "R10"
    , nb_no = "R10"
    , fi_fl = "R10"
    , da_dk = "R10"
    , sv_se = "R10"
    }



-- LANGUAGE


languageDefault : R10.Language.Language
languageDefault =
    R10.Language.EN_US


languageSupportedList : List R10.Language.Language
languageSupportedList =
    [ R10.Language.EN_US
    , R10.Language.JA_JP
    ]



-- ROUTE


type Route
    = RouteTop R10.Language.Language
    | Route_Overview R10.Language.Language
    | Route_Form_Entities R10.Language.Language
    | Route_Form_Boilerplate R10.Language.Language
    | Route_Form_Example_Table R10.Language.Language
    | Route_Form_Example_CreditCard R10.Language.Language
    | Route_Form_Example_PhoneSelector R10.Language.Language
    | Route_Form_States R10.Language.Language
    | Route_Form_FieldType_Text R10.Language.Language
    | Route_Form_FieldType_Single R10.Language.Language
    | Route_Form_FieldType_Multi R10.Language.Language
    | Route_Form_FieldType_Binary R10.Language.Language
    | Route_Form_Introduction R10.Language.Language
    | Route_UIComponents R10.Language.Language
    | Route_Counter R10.Language.Language
    | Route_TableExample R10.Language.Language
    | NotFound R10.Language.Language


listForSSR : List String
listForSSR =
    let
        routes =
            RouteTop R10.Language.EN_US :: List.map (\route -> route R10.Language.EN_US) routesList
    in
    List.map routeToPathWithoutLanguage routes


routesList : List (R10.Language.Language -> Route)
routesList =
    [ Route_Overview
    , Route_UIComponents
    , Route_Form_Introduction
    , Route_Form_Entities
    , Route_Form_Boilerplate
    , Route_Form_Example_Table
    , Route_Form_Example_CreditCard
    , Route_Form_Example_PhoneSelector
    , Route_Form_FieldType_Text
    , Route_Form_FieldType_Single
    , Route_Form_FieldType_Multi
    , Route_Form_FieldType_Binary
    , Route_Form_States
    , Route_Counter
    , Route_TableExample
    ]


routeDetails :
    Route
    ->
        { title : R10.Language.Translations
        , language : R10.Language.Language
        , routeLabel : String
        }
routeDetails route =
    case route of
        RouteTop language ->
            { title = translationR10
            , routeLabel = ""
            , language = language
            }

        Route_Overview language ->
            { title = Pages.Overview.title
            , routeLabel = "overview"
            , language = language
            }

        Route_Form_Entities language ->
            { title = Pages.Form_Entities.title
            , routeLabel = "form_entities"
            , language = language
            }

        Route_Form_Example_CreditCard language ->
            { title = Pages.Form_Example_CreditCard.title
            , routeLabel = "form_example_credit_card"
            , language = language
            }

        Route_Form_Example_Table language ->
            { title = Pages.Form_Example_Table.title
            , routeLabel = "form_example_table"
            , language = language
            }

        Route_Form_Example_PhoneSelector language ->
            { title = Pages.Form_Example_PhoneSelector.title
            , routeLabel = "form_example_phone_selector"
            , language = language
            }

        Route_Form_Boilerplate language ->
            { title = Pages.Form_Boilerplate.title
            , routeLabel = "form_boilerplate"
            , language = language
            }

        Route_Form_FieldType_Text language ->
            { title = Pages.Form_FieldType_Text.title
            , routeLabel = "form_field_type_text"
            , language = language
            }

        Route_Form_FieldType_Single language ->
            { title = Pages.Form_FieldType_Single.title
            , routeLabel = "form_field_type_single"
            , language = language
            }

        Route_Form_FieldType_Multi language ->
            { title = Pages.Form_FieldType_Multi.title
            , routeLabel = "form_field_type_multi"
            , language = language
            }

        Route_Form_FieldType_Binary language ->
            { title = Pages.Form_FieldType_Binary.title
            , routeLabel = "form_field_type_binary"
            , language = language
            }

        Route_Form_States language ->
            { title = Pages.Form_States.title
            , routeLabel = "form_states"
            , language = language
            }

        Route_Form_Introduction language ->
            { title = Pages.Form_Introduction.title
            , routeLabel = "form"
            , language = language
            }

        Route_UIComponents language ->
            { title = Pages.UIComponents.title
            , routeLabel = "ui_components"
            , language = language
            }

        Route_Counter language ->
            { title = Pages.Counter.title
            , routeLabel = "counter"
            , language = language
            }

        Route_TableExample language ->
            { title = Pages.TableExample.title
            , routeLabel = "sortable_table"
            , language = language
            }

        NotFound language ->
            { title = translationsError
            , routeLabel = "not_found"
            , language = language
            }


routeToPathWithoutLanguage : Route -> String
routeToPathWithoutLanguage route =
    routeToPath (routeToLanguage route) route


routeToPath : R10.Language.Language -> Route -> String
routeToPath language route =
    let
        lang =
            if language == languageDefault then
                []

            else
                [ R10.Language.toStringShort language ]

        path =
            String.join "/" <|
                case route of
                    RouteTop _ ->
                        lang

                    _ ->
                        lang ++ [ .routeLabel (routeDetails route) ]
    in
    if String.isEmpty path then
        "/"

    else
        "/" ++ path ++ "/"


routeToLanguage : Route -> R10.Language.Language
routeToLanguage route =
    .language (routeDetails route)


urlToRoute : Url.Url -> Route
urlToRoute url =
    Maybe.withDefault (NotFound languageDefault) <| Url.Parser.parse routeParser url


fromLocationHref : String -> Route
fromLocationHref locationHref =
    locationHref
        |> Url.fromString
        |> Maybe.map urlToRoute
        |> Maybe.withDefault (NotFound languageDefault)


routeWithLanguage : (R10.Language.Language -> Route) -> Url.Parser.Parser (Route -> c) c
routeWithLanguage route =
    Url.Parser.map route (R10.Language.urlParser </> Url.Parser.s (.routeLabel (routeDetails (route languageDefault))))


routeWithDefaultLanguage : (R10.Language.Language -> Route) -> Url.Parser.Parser (Route -> c) c
routeWithDefaultLanguage route =
    Url.Parser.map (route languageDefault) (Url.Parser.s (.routeLabel (routeDetails (route languageDefault))))


routeParser : Url.Parser.Parser (Route -> b) b
routeParser =
    Url.Parser.oneOf
        -- The RouteTop is special because doesn't have any label
        ([ Url.Parser.map RouteTop R10.Language.urlParser
         , Url.Parser.map (RouteTop languageDefault) Url.Parser.top
         ]
            -- Routes with language
            ++ List.map routeWithLanguage routesList
            -- Routes with default language
            ++ List.map routeWithDefaultLanguage routesList
        )

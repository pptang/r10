module R10.Form.Internal.MakerForView exposing
    ( MakerArgs
    , Outcome
    , extraCss
    , maker
    )

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import R10.Form.Internal.Conf
import R10.Form.Internal.Converter exposing (fromFormValidationIconToComponentValidationIcon)
import R10.Form.Internal.Dict
import R10.Form.Internal.FieldConf exposing (ValidationIcon(..))
import R10.Form.Internal.FieldState exposing (ValidationOutcome(..))
import R10.Form.Internal.Helpers
import R10.Form.Internal.Key
import R10.Form.Internal.State
import R10.Form.Internal.Update
import R10.Form.Msg
import R10.FormComponents.Binary
import R10.FormComponents.ExtraCss
import R10.FormComponents.Single
import R10.FormComponents.Style
import R10.FormComponents.Text
import R10.FormComponents.UI
import R10.FormComponents.UI.Color
import R10.FormComponents.UI.Palette
import R10.FormComponents.Validations



--  ██████  ██    ██ ████████  ██████  ██████  ███    ███ ███████
-- ██    ██ ██    ██    ██    ██      ██    ██ ████  ████ ██
-- ██    ██ ██    ██    ██    ██      ██    ██ ██ ████ ██ █████
-- ██    ██ ██    ██    ██    ██      ██    ██ ██  ██  ██ ██
--  ██████   ██████     ██     ██████  ██████  ██      ██ ███████


type alias Outcome =
    Element R10.Form.Msg.Msg



-- ██   ██ ███████ ██      ██████  ███████ ██████  ███████
-- ██   ██ ██      ██      ██   ██ ██      ██   ██ ██
-- ███████ █████   ██      ██████  █████   ██████  ███████
-- ██   ██ ██      ██      ██      ██      ██   ██      ██
-- ██   ██ ███████ ███████ ██      ███████ ██   ██ ███████


type alias ArgsForFields =
    { fieldConf : R10.Form.Internal.FieldConf.FieldConf
    , fieldState : R10.Form.Internal.FieldState.FieldState
    , focused : Bool
    , active : Bool
    , key : R10.Form.Internal.Key.Key
    , translator : R10.Form.Internal.FieldConf.ValidationCode -> String
    , style : R10.FormComponents.Style.Style
    , palette : R10.FormComponents.UI.Palette.Palette
    }


paddingGeneric : Attribute msg
paddingGeneric =
    paddingXY 20 25


spacingGeneric : Attribute msg
spacingGeneric =
    spacingXY 15 25


extraCss : Maybe R10.FormComponents.UI.Palette.Palette -> String
extraCss maybePalette =
    let
        palette : R10.FormComponents.UI.Palette.Palette
        palette =
            Maybe.withDefault R10.FormComponents.UI.Palette.light maybePalette
    in
    R10.FormComponents.ExtraCss.extraCss palette


isFocused : R10.Form.Internal.Key.Key -> Maybe String -> Bool
isFocused key focused =
    case focused of
        Just focused_x ->
            focused_x == R10.Form.Internal.Key.toString key

        Nothing ->
            False


isActive : R10.Form.Internal.Key.Key -> Maybe String -> Bool
isActive key active =
    case active of
        Just active_x ->
            active_x == R10.Form.Internal.Key.toString key

        Nothing ->
            False


getEntityKey : MakerArgs -> R10.Form.Internal.Conf.Entity -> R10.Form.Internal.Key.Key
getEntityKey args entity =
    let
        id : String
        id =
            case entity of
                R10.Form.Internal.Conf.EntityWrappable entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntityWithBorder entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntityNormal entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntityWithTabs entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntityMulti entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntityField fieldConf ->
                    fieldConf.id

                R10.Form.Internal.Conf.EntityTitle entityId _ ->
                    entityId

                R10.Form.Internal.Conf.EntitySubTitle entityId _ ->
                    entityId
    in
    R10.Form.Internal.Key.composeKey args.key id


getFieldConfig : R10.Form.Internal.Conf.Entity -> R10.Form.Internal.FieldConf.FieldConf
getFieldConfig entity =
    case entity of
        R10.Form.Internal.Conf.EntityField fieldConf ->
            fieldConf

        _ ->
            R10.Form.Internal.FieldConf.init



-- ██ ███    ██ ██████  ██    ██ ████████     ████████ ███████ ██   ██ ████████
-- ██ ████   ██ ██   ██ ██    ██    ██           ██    ██       ██ ██     ██
-- ██ ██ ██  ██ ██████  ██    ██    ██           ██    █████     ███      ██
-- ██ ██  ██ ██ ██      ██    ██    ██           ██    ██       ██ ██     ██
-- ██ ██   ████ ██       ██████     ██           ██    ███████ ██   ██    ██


viewText :
    ArgsForFields
    -> R10.Form.Internal.FieldConf.TypeText
    -> R10.Form.Internal.Conf.Conf
    -> Element R10.Form.Msg.Msg
viewText args textType formConf =
    R10.FormComponents.Text.view
        [ width
            (fill
                |> minimum 300
                |> maximum 900
            )
        ]
        []
        -- Stuff that change
        { value = args.fieldState.value
        , focused = args.focused
        , validation =
            R10.Form.Internal.Converter.fromFieldStateValidationToComponentValidation
                args.fieldConf.validationSpecs
                args.fieldState.validation
                args.translator
        , showPassword = args.fieldState.showPassword
        , leadingIcon = Nothing
        , trailingIcon = Nothing

        -- Messages
        , msgOnChange = R10.Form.Msg.ChangeValue args.key args.fieldConf formConf
        , msgOnFocus = R10.Form.Msg.GetFocus args.key
        , msgOnLoseFocus = Just <| R10.Form.Msg.LoseFocus args.key args.fieldConf
        , msgOnTogglePasswordShow = Just <| R10.Form.Msg.TogglePasswordShow args.key
        , msgOnEnter = Just <| R10.Form.Msg.Submit formConf

        -- Stuff that doesn't change
        , label = args.fieldConf.label
        , helperText = args.fieldConf.helperText
        , disabled = args.fieldState.disabled
        , idDom = args.fieldConf.idDom
        , style = args.style
        , requiredLabel = args.fieldConf.requiredLabel
        , palette = args.palette

        -- Specific
        , textType = R10.Form.Internal.Converter.textTypeFromFieldConfToComponent textType
        }



--  ██████ ██   ██ ███████  ██████ ██   ██ ██████   ██████  ██   ██
-- ██      ██   ██ ██      ██      ██  ██  ██   ██ ██    ██  ██ ██
-- ██      ███████ █████   ██      █████   ██████  ██    ██   ███
-- ██      ██   ██ ██      ██      ██  ██  ██   ██ ██    ██  ██ ██
--  ██████ ██   ██ ███████  ██████ ██   ██ ██████   ██████  ██   ██


viewBinary :
    ArgsForFields
    -> R10.Form.Internal.FieldConf.TypeBinary
    -> R10.Form.Internal.Conf.Conf
    -> Element R10.Form.Msg.Msg
viewBinary args typeBinary formConf =
    let
        value : Bool
        value =
            R10.Form.Internal.Helpers.stringToBool args.fieldState.value

        msgOnClick : R10.Form.Msg.Msg
        msgOnClick =
            R10.Form.Msg.ChangeValue args.key args.fieldConf formConf (R10.Form.Internal.Helpers.boolToString <| not value)
    in
    R10.FormComponents.Binary.view
        [ width
            (fill
                |> minimum 300
                |> maximum 900
            )
        ]
        -- Stuff that change
        { value = value
        , focused = args.focused
        , validation =
            R10.Form.Internal.Converter.fromFieldStateValidationToComponentValidation
                args.fieldConf.validationSpecs
                args.fieldState.validation
                args.translator

        -- Messages
        , msgOnChange = \_ -> msgOnClick
        , msgOnFocus = R10.Form.Msg.GetFocus args.key
        , msgOnLoseFocus = R10.Form.Msg.LoseFocus args.key args.fieldConf
        , msgOnClick = msgOnClick

        -- Stuff that doesn't change
        , label = args.fieldConf.label
        , disabled = args.fieldState.disabled
        , helperText = args.fieldConf.helperText
        , palette = args.palette

        -- Specific stuff
        , typeBinary = R10.Form.Internal.Converter.binaryTypeFromFieldConfToComponent typeBinary
        }



-- ██████   █████  ██████  ██  ██████
-- ██   ██ ██   ██ ██   ██ ██ ██    ██
-- ██████  ███████ ██   ██ ██ ██    ██
-- ██   ██ ██   ██ ██   ██ ██ ██    ██
-- ██   ██ ██   ██ ██████  ██  ██████


viewSingleSelection :
    ArgsForFields
    -> R10.Form.Internal.FieldConf.TypeSingle
    -> List R10.Form.Internal.FieldConf.FieldOption
    -> R10.Form.Internal.Conf.Conf
    -> Element.Element R10.Form.Msg.Msg
viewSingleSelection args singleType fieldOptions formConf =
    R10.FormComponents.Single.view
        [ width
            (fill
                |> minimum 300
                |> maximum 900
            )
        ]
        -- Stuff that change
        { value = args.fieldState.value
        , search = args.fieldState.search
        , select = args.fieldState.select
        , scroll = args.fieldState.scroll
        , focused = args.focused
        , opened = args.active
        }
        { validation =
            R10.Form.Internal.Converter.fromFieldStateValidationToComponentValidation
                args.fieldConf.validationSpecs
                args.fieldState.validation
                args.translator

        -- Message mapper
        , toMsg = R10.Form.Msg.OnSingleMsg args.key args.fieldConf formConf

        -- Stuff that doesn't change
        , label = args.fieldConf.label
        , helperText = args.fieldConf.helperText
        , disabled = args.fieldState.disabled
        , requiredLabel = args.fieldConf.requiredLabel
        , style = args.style
        , key = R10.Form.Internal.Key.toString args.key
        , palette = args.palette

        -- Specific
        , singleType = R10.Form.Internal.Converter.singleTypeFromFieldConfToComponent singleType
        , fieldOptions = fieldOptions
        }



-- ██    ██ ██ ███████ ██     ██     ███████ ███    ██ ████████ ██ ████████ ██ ███████ ███████
-- ██    ██ ██ ██      ██     ██     ██      ████   ██    ██    ██    ██    ██ ██      ██
-- ██    ██ ██ █████   ██  █  ██     █████   ██ ██  ██    ██    ██    ██    ██ █████   ███████
--  ██  ██  ██ ██      ██ ███ ██     ██      ██  ██ ██    ██    ██    ██    ██ ██           ██
--   ████   ██ ███████  ███ ███      ███████ ██   ████    ██    ██    ██    ██ ███████ ███████


viewEntityNormal :
    MakerArgs
    -> List R10.Form.Internal.Conf.Entity
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityNormal args entities formConf =
    [ el
        [ alignTop
        , width fill
        , height fill
        , spacingGeneric
        ]
      <|
        column
            -- This padding need to be nested, otherwise the fill doesn't
            -- get 50% of the space
            [ spacingGeneric
            , width fill
            ]
        <|
            maker_ args entities formConf
    ]


viewEntityWrappable :
    MakerArgs
    -> List R10.Form.Internal.Conf.Entity
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityWrappable args entities formConf =
    [ wrappedRow
        [ alignTop
        , width fill
        , height fill
        , spacingGeneric
        ]
      <|
        maker_ args entities formConf
    ]


viewEntityWithBorder :
    MakerArgs
    -> List R10.Form.Internal.Conf.Entity
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityWithBorder args entities formConf =
    [ el
        ([ alignTop
         , width fill
         , height fill
         ]
            ++ R10.FormComponents.UI.borderEntityWithBorder args.palette
        )
      <|
        column
            -- This padding need to be nested, otherwise the fill doesn't
            -- get 50% of the space
            [ paddingGeneric
            , spacingGeneric
            , width fill
            ]
        <|
            maker_ args entities formConf
    ]


viewTab :
    MakerArgs
    -> R10.Form.Internal.FieldState.FieldState
    ->
        { index : Int
        , selected : Bool
        , label : String
        , entity : R10.Form.Internal.Conf.Entity
        }
    -> Element R10.Form.Msg.Msg
viewTab args fieldState { index, selected, entity, label } =
    let
        valid : Bool
        valid =
            R10.Form.Internal.Update.isExistingFormFieldsValid [ entity ] args.formState

        { opacity, clickOverlay } =
            if fieldState.disabled then
                { opacity = 0.5
                , clickOverlay = none
                }

            else
                { opacity = 1
                , clickOverlay =
                    el
                        [ Events.onClick <| R10.Form.Msg.ChangeTab args.key (R10.Form.Internal.Conf.getId entity)
                        , pointer
                        , width fill
                        , height fill
                        , htmlAttribute <| Html.Attributes.class <| "ripple"
                        , mouseOver [ Background.color <| R10.FormComponents.UI.Color.mouseOverSurface args.palette ]
                        ]
                        none
                }

        { circleBackground, circleBorder, circleText, labelText } =
            if selected then
                { circleBackground = R10.FormComponents.UI.Color.surfaceA opacity args.palette
                , circleBorder = R10.FormComponents.UI.Color.primaryA opacity args.palette
                , circleText = R10.FormComponents.UI.Color.primaryA opacity args.palette
                , labelText = R10.FormComponents.UI.Color.primaryA opacity args.palette
                }

            else
                { circleBackground = R10.FormComponents.UI.Color.surfaceA opacity args.palette
                , circleBorder = R10.FormComponents.UI.Color.labelA opacity args.palette
                , circleText = R10.FormComponents.UI.Color.labelA opacity args.palette
                , labelText = R10.FormComponents.UI.Color.labelA opacity args.palette
                }
    in
    el
        [ paddingXY 8 0
        , inFront <| clickOverlay
        ]
    <|
        row
            [ Background.color <| R10.FormComponents.UI.Color.surface args.palette
            , paddingXY 8 24
            , spacing 8
            , Font.color <| labelText
            ]
        <|
            [ el
                [ inFront <|
                    el
                        [ height fill
                        , Background.color <| R10.FormComponents.UI.Color.surface args.palette
                        ]
                    <|
                        R10.FormComponents.UI.showValidationIcon_
                            { maybeValid = Just valid
                            , displayValidation = True
                            , palette = args.palette
                            }
                , height <| px 24
                , width <| px 24
                , Border.rounded 24
                , Background.color circleBackground
                , Font.color circleText
                , Border.innerShadow
                    { offset = ( 0, 0 )
                    , size = 1
                    , blur = 0
                    , color = circleBorder
                    }
                ]
              <|
                el
                    [ centerY
                    , centerX
                    ]
                <|
                    text <|
                        String.fromInt (index + 1)
            , column [ width shrink ] <|
                [ text label
                , el
                    ([ Font.size 11
                     , clip
                     , Font.color <| R10.FormComponents.UI.Color.error args.palette
                     , htmlAttribute <| Html.Attributes.style "transition" "all 0.15s ease-out"
                     ]
                        ++ (if valid then
                                [ width <| px 0
                                , height <| px 0
                                ]

                            else
                                [ width <| px 80
                                , height <| px 11
                                ]
                           )
                    )
                  <|
                    text "Validation error"
                ]
            ]


viewEntityWithTabs :
    MakerArgs
    -> List ( String, R10.Form.Internal.Conf.Entity )
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityWithTabs args titleEntityList formConf =
    let
        paddingPx : number
        paddingPx =
            8

        firstEntity : Maybe ( String, R10.Form.Internal.Conf.Entity )
        firstEntity =
            List.head titleEntityList

        maybeSelectedEntity : Maybe ( String, R10.Form.Internal.Conf.Entity )
        maybeSelectedEntity =
            case R10.Form.Internal.Dict.get args.key args.formState.activeTabs of
                Just key_ ->
                    case List.head <| List.filter (\( _, entity ) -> R10.Form.Internal.Conf.getId entity == key_) titleEntityList of
                        Just entity_ ->
                            Just entity_

                        Nothing ->
                            firstEntity

                Nothing ->
                    firstEntity

        tabSpacer : Element msg
        tabSpacer =
            el [ width (fill |> maximum 40), height fill ] none

        emptyTab : Element msg
        emptyTab =
            el [ width fill, height fill, moveLeft paddingPx, Background.color <| rgb 1 1 1 ] none
    in
    case maybeSelectedEntity of
        Just ( _, selectedEntity ) ->
            [ el
                [ width fill
                , behindContent <|
                    el [ width fill, centerY, paddingXY paddingPx 0 ] <|
                        el
                            [ width fill
                            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                            , Border.color <| R10.FormComponents.UI.Color.container args.palette
                            ]
                            none
                ]
              <|
                row
                    [ scrollbars
                    , width fill
                    ]
                <|
                    (\items -> items ++ [ emptyTab ]) <|
                        (List.concat <|
                            List.indexedMap
                                (\index ( label, entity ) ->
                                    let
                                        newKey : R10.Form.Internal.Key.Key
                                        newKey =
                                            R10.Form.Internal.Key.composeKey args.key (R10.Form.Internal.Conf.getId entity)

                                        fieldState : R10.Form.Internal.FieldState.FieldState
                                        fieldState =
                                            Maybe.withDefault R10.Form.Internal.FieldState.init <|
                                                R10.Form.Internal.Dict.get newKey args.formState.fieldsState
                                    in
                                    [ viewTab args
                                        fieldState
                                        { index = index
                                        , selected = R10.Form.Internal.Conf.getId selectedEntity == R10.Form.Internal.Conf.getId entity
                                        , label = label
                                        , entity = entity
                                        }
                                    ]
                                        ++ (if index + 1 /= List.length titleEntityList then
                                                [ tabSpacer ]

                                            else
                                                []
                                           )
                                )
                                titleEntityList
                        )
            ]
                ++ maker_ args [ selectedEntity ] formConf

        Nothing ->
            []


viewEntityMultiHelper :
    MakerArgs
    -> Int
    -> Int
    -> R10.Form.Internal.Key.Key
    -> List R10.Form.Internal.Conf.Entity
    -> R10.Form.Internal.Conf.Conf
    -> List (Element R10.Form.Msg.Msg)
viewEntityMultiHelper args quantity index newKey entities formConf =
    let
        iconSize : Int
        iconSize =
            18

        shadow : Float -> Float -> Attr decorative msg
        shadow size_ a =
            Border.shadow
                { offset = ( 0, 0 )
                , size = size_
                , blur = 0
                , color = R10.FormComponents.UI.Color.labelA a args.palette
                }

        buttonAttrs : List (Attr () msg)
        buttonAttrs =
            [ Border.width 1
            , Border.rounded 5
            , htmlAttribute <| Html.Attributes.class <| "ripple"
            , htmlAttribute <| Html.Attributes.style "transition" "all 0.11s ease-out"
            , padding 8
            , width <| px 28
            , height fill
            , shadow 10 0
            , Border.color <| R10.FormComponents.UI.Color.containerA 0.5 args.palette
            , mouseOver <| [ Border.color <| R10.FormComponents.UI.Color.containerA 1 args.palette ]
            , focused <| [ alpha 1, shadow 1 1, Border.color <| R10.FormComponents.UI.Color.containerA 1 args.palette ]
            ]

        plusColor : Color
        plusColor =
            R10.FormComponents.UI.Color.label args.palette

        removeColor : Color
        removeColor =
            R10.FormComponents.UI.Color.label args.palette

        iconCommonAttrs : Int -> Int -> Color -> Float -> List (Attribute msg)
        iconCommonAttrs widthPx heightPx color rotateDeg =
            [ htmlAttribute <| Html.Attributes.style "transition" "all 0.2s "
            , Border.rounded 2
            , centerX
            , centerY
            , width <| px widthPx
            , height <| px heightPx
            , Background.color color
            , rotate <| degrees rotateDeg
            ]

        buttonToAddEntity : Element R10.Form.Msg.Msg
        buttonToAddEntity =
            Input.button buttonAttrs
                { label =
                    el
                        [ width <| px iconSize
                        , height <| px iconSize
                        , inFront <| el (iconCommonAttrs iconSize 2 plusColor 0) none
                        , inFront <| el (iconCommonAttrs 2 iconSize plusColor 0) none
                        ]
                    <|
                        none
                , onPress = Just <| R10.Form.Msg.AddEntity args.key
                }

        buttonToRemoveEntity : R10.Form.Internal.Key.Key -> Element R10.Form.Msg.Msg
        buttonToRemoveEntity key_ =
            Input.button buttonAttrs
                { label =
                    el
                        [ width <| px iconSize
                        , height <| px iconSize
                        , htmlAttribute <| Html.Attributes.style "transition" "all 0.2s "
                        , inFront <| el (iconCommonAttrs iconSize 2 removeColor 45) none
                        , inFront <| el (iconCommonAttrs 2 iconSize removeColor -135) none
                        ]
                    <|
                        none
                , onPress = Just <| R10.Form.Msg.RemoveEntity key_
                }
    in
    [ row [ spacing 10, width fill ]
        [ if quantity - 1 == index then
            buttonToAddEntity

          else
            buttonToRemoveEntity newKey
        , column [ width fill, spacingGeneric ] <| maker_ { args | key = newKey } entities formConf
        ]
    ]


viewEntityMulti :
    MakerArgs
    -> List R10.Form.Internal.Conf.Entity
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityMulti args entities formConf =
    let
        activeKeys : List R10.Form.Internal.Key.Key
        activeKeys =
            R10.Form.Internal.Helpers.getMultiActiveKeys args.key args.formState

        quantity : Int
        quantity =
            List.length activeKeys
    in
    activeKeys
        |> List.indexedMap
            (\index newKey ->
                viewEntityMultiHelper args quantity index newKey entities formConf
            )
        |> List.concat
        |> column [ spacing 10, width fill ]
        |> List.singleton


viewEntityField :
    MakerArgs
    -> R10.Form.Internal.FieldConf.FieldConf
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
viewEntityField args fieldConf formConf =
    let
        newKey : R10.Form.Internal.Key.Key
        newKey =
            R10.Form.Internal.Key.composeKey args.key fieldConf.id

        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            Maybe.withDefault R10.Form.Internal.FieldState.init <|
                R10.Form.Internal.Dict.get newKey args.formState.fieldsState

        focused : Bool
        focused =
            isFocused newKey args.formState.focused

        active : Bool
        active =
            isActive newKey args.formState.active
    in
    --
    -- This is the function that render the "leaf" of the tree, some of
    -- the possible input field (text, password, checkboxes, etc...)
    --
    -- key       = the composed key that describe the position in the tree.
    --             The last section of the key contains the FieldId to lookup
    --             in the configurations.
    -- formState = the state of the entire form
    -- fieldType = type of field, for example: text, email, password, etc.
    --
    let
        args2 : ArgsForFields
        args2 =
            { key = newKey
            , focused = focused
            , active = active
            , fieldState = fieldState
            , fieldConf = fieldConf
            , translator = args.translator
            , style = args.style
            , palette = args.palette
            }

        field : Element R10.Form.Msg.Msg
        field =
            case fieldConf.type_ of
                R10.Form.Internal.FieldConf.TypeText typeText ->
                    viewText args2 typeText formConf

                R10.Form.Internal.FieldConf.TypeBinary typeBinary ->
                    viewBinary args2 typeBinary formConf

                R10.Form.Internal.FieldConf.TypeSingle typeSingle options ->
                    viewSingleSelection args2 typeSingle options formConf

                R10.Form.Internal.FieldConf.TypeMulti _ _ ->
                    text "TODO"
    in
    [ field ]


viewEntityTitle :
    R10.FormComponents.UI.Palette.Palette
    -> R10.Form.Internal.Conf.TextConf
    -> List Outcome
viewEntityTitle palette titleConf =
    [ column
        [ spacing 12
        , paddingEach { top = 40, right = 0, bottom = 0, left = 0 }
        , width fill
        ]
        [ paragraph [ R10.FormComponents.UI.fontSizeTitle ] [ text titleConf.title ]
        , R10.FormComponents.UI.viewHelperText palette [] titleConf.helperText
        ]
    ]


viewEntitySubTitle :
    R10.FormComponents.UI.Palette.Palette
    -> R10.Form.Internal.Conf.TextConf
    -> List Outcome
viewEntitySubTitle palette titleConf =
    [ column
        [ spacing R10.FormComponents.UI.genericSpacing
        , width fill
        ]
        [ paragraph [ R10.FormComponents.UI.fontSizeSubTitle ] [ text titleConf.title ]
        , R10.FormComponents.UI.viewHelperText palette [ alpha 0.5, Font.size 14, paddingEach { top = R10.FormComponents.UI.genericSpacing, right = 0, bottom = 0, left = 0 } ] titleConf.helperText
        ]
    ]


viewWithValidationMessage : MakerArgs -> R10.Form.Internal.Conf.Entity -> List (Element msg) -> List (Element msg)
viewWithValidationMessage args entity listEl =
    let
        validationIcon : R10.FormComponents.Validations.ValidationIcon
        validationIcon =
            getFieldConfig entity
                |> .validationSpecs
                |> Maybe.map .validationIcon
                |> Maybe.withDefault NoIcon
                |> fromFormValidationIconToComponentValidationIcon
    in
    [ column [ width fill, height fill ] <|
        listEl
            ++ [ R10.FormComponents.Validations.viewValidation args.palette validationIcon <|
                    R10.Form.Internal.Converter.fromFieldStateValidationToComponentValidation
                        (getFieldConfig entity |> .validationSpecs)
                        (R10.Form.Internal.Dict.get (getEntityKey args entity) args.formState.fieldsState
                            |> Maybe.withDefault R10.Form.Internal.FieldState.init
                        ).validation
                        args.translator
               ]
    ]



-- ███    ███  █████  ██   ██ ███████ ██████
-- ████  ████ ██   ██ ██  ██  ██      ██   ██
-- ██ ████ ██ ███████ █████   █████   ██████
-- ██  ██  ██ ██   ██ ██  ██  ██      ██   ██
-- ██      ██ ██   ██ ██   ██ ███████ ██   ██


type alias MakerArgs =
    { key : R10.Form.Internal.Key.Key
    , formState : R10.Form.Internal.State.State
    , translator : R10.Form.Internal.FieldConf.ValidationCode -> String
    , style : R10.FormComponents.Style.Style
    , palette : R10.FormComponents.UI.Palette.Palette
    }


maker :
    MakerArgs
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
maker args formConf =
    maker_ args formConf formConf


maker_ :
    MakerArgs
    -> R10.Form.Internal.Conf.Conf
    -> R10.Form.Internal.Conf.Conf
    -> List Outcome
maker_ args branchConfig rootFormConf =
    --
    --     This is recursive
    --
    --   ┌─────> maker >─────┐
    --   │                   │
    --   └───────────────────┘
    --
    List.map
        (\entity ->
            (case entity of
                R10.Form.Internal.Conf.EntityWrappable entityId entities ->
                    viewEntityWrappable { args | key = R10.Form.Internal.Key.composeKey args.key entityId } entities rootFormConf

                R10.Form.Internal.Conf.EntityWithBorder entityId entities ->
                    viewEntityWithBorder { args | key = R10.Form.Internal.Key.composeKey args.key entityId } entities rootFormConf

                R10.Form.Internal.Conf.EntityNormal entityId entities ->
                    viewEntityNormal { args | key = R10.Form.Internal.Key.composeKey args.key entityId } entities rootFormConf

                R10.Form.Internal.Conf.EntityWithTabs entityId titleEntityList ->
                    viewEntityWithTabs { args | key = R10.Form.Internal.Key.composeKey args.key entityId } titleEntityList rootFormConf

                R10.Form.Internal.Conf.EntityMulti entityId entities ->
                    viewEntityMulti { args | key = R10.Form.Internal.Key.composeKey args.key entityId } entities rootFormConf

                R10.Form.Internal.Conf.EntityField fieldConf ->
                    viewEntityField args fieldConf rootFormConf

                R10.Form.Internal.Conf.EntityTitle _ titleConf ->
                    viewEntityTitle args.palette titleConf

                R10.Form.Internal.Conf.EntitySubTitle _ titleConf ->
                    viewEntitySubTitle args.palette titleConf
            )
                |> viewWithValidationMessage args entity
        )
        branchConfig
        |> List.concat

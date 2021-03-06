module R10.Form exposing
    ( view, viewWithTheme, viewWithPalette, viewWithOptions
    , Form, Conf, Entity, entity
    , MsgMapper
    , Options
    , Maker, MakerArgs, maker
    , defaultTranslator, validationCodes, ValidationCode
    , style
    , Palette
    , State, initState, stateToString, stringToState
    , extraCss
    , EntityId, TextConf, stringToConf, confToString, initConf
    , FieldConf, TypeSingle, single, fieldType, text, validationIcon, validation, binary, initFieldConf
    , update, shouldShowTheValidationOverview, allValidationKeysMaker, entitiesWithErrors, runOnlyExistingValidations, submittable, isFormSubmittableAndSubmitted
    , Msg, msg
    , keyToString
    , getFieldValueAsBool
    , commonValidation
    , FieldState, Validation, ValidationSpecs, boolToString, getField, isChangingValues, setFieldValue, stringToBool, validate
    , label, onClickWithStopPropagation, viewIconButton, viewSingleCustom, defaultSearchFn, SingleModel, SingleMsg, initSingle, typeSingle, normalizeString, insertBold, defaultToOptionEl, defaultTrailingIcon, SingleType, SingleFieldOption, singleMsg, Style
    , FieldOption, FieldType, Key, KeyAsString, PhoneModel, PhoneMsg, TextType, Validation2, ValidationMessage, binary2, binaryView, button, clearFieldValidation, colorToCssString, componentTextType, componentValidation, composeKey, elementMarkdown, emptyKey, entitiesToString, extraCssComponents, getActiveTab, getFieldValue, getMultiActiveKeys, headId, initFieldState, initValidationSpecs, isExistingFormFieldsValid, listToKey, onFocusOut, phoneInit, phoneUpdate, phoneView, setActiveTab, setFieldDisabled, setFieldValidationError, setMultiplicableQuantities, stringToKey, updateSingle, validateDirtyFormFields, validateEntireForm, validationMessage, validationToString, viewButton, viewText, themeToPalette
    )

{-| Useful things to build a form .


# Views

There are three functions to rennder the form, each with a different degree of customization. They are order from the simplest (less customizable) to the most complex (more customizable).

@docs view, viewWithTheme, viewWithPalette, viewWithOptions


# Form, Conf, State, Entity

@docs Form, Conf, Entity, entity


# MsgMapper

This function is to convert specific form messages (`Msg`) into generic messages (`msg`). Tipically you would define this function like this in your application:

    type Msg
        = MsgForm R10.Form.Msg

`MsgForm` can now be used as `MsgMapper` that convert `R10.Form.Msg` into `Msg`.

For a code example have a look at this [simple form](https://github.com/rakutentech/r10/blob/master/examples/simpleForm/src/Main.elm).

@docs MsgMapper


# Views' Options

These are the options that you can use with `viewWithOptions`.

@docs Options


# Maker

@docs Maker, MakerArgs, maker


# Translator

If you want to personalise the translations or you want to translate them in different languages, you can do so defining a function like

    translator : ValidationCode -> String
    translator validationCode =
        Dict.fromList
            [ ( validationCodes.emailFormatInvalid
              , "Invalid email format"
              )
            , ( validationCodes.emailFormatValid
              , "Valid email format"
              )
            , ( validationCodes.formatInvalid
              , "Invalid format"
              )
            ...
            , ( validationCodes.oneOf
              , "All the validations have failed"
              )
            ]
            |> Dict.get validationCode
            |> Maybe.withDefault validationCode

@docs defaultTranslator, validationCodes, ValidationCode


# Style

@docs style


# Palette

@docs Palette


# State

@docs State, initState, stateToString, stringToState


# Extra CSS

@docs extraCss


# Form related stuff

@docs EntityId, TextConf, stringToConf, confToString, initConf


# Fields related stuff

@docs FieldConf, TypeSingle, single, fieldType, text, validationIcon, validation, binary, initFieldConf

@docs update, shouldShowTheValidationOverview, allValidationKeysMaker, entitiesWithErrors, runOnlyExistingValidations, submittable, isFormSubmittableAndSubmitted

@docs Msg, msg

@docs keyToString

@docs getFieldValueAsBool

@docs commonValidation

@docs FieldState, Validation, ValidationSpecs, boolToString, getField, isChangingValues, setFieldValue, stringToBool, validate

@docs label, onClickWithStopPropagation, viewIconButton, viewSingleCustom, defaultSearchFn, SingleModel, SingleMsg, initSingle, typeSingle, normalizeString, insertBold, defaultToOptionEl, defaultTrailingIcon, SingleType, SingleFieldOption, singleMsg, Style

@docs FieldOption, FieldType, Key, KeyAsString, PhoneModel, PhoneMsg, TextType, Validation2, ValidationMessage, binary2, binaryView, button, clearFieldValidation, colorToCssString, componentTextType, componentValidation, composeKey, elementMarkdown, emptyKey, entitiesToString, extraCssComponents, getActiveTab, getFieldValue, getMultiActiveKeys, headId, initFieldState, initValidationSpecs, isExistingFormFieldsValid, listToKey, onFocusOut, phoneInit, phoneUpdate, phoneView, setActiveTab, setFieldDisabled, setFieldValidationError, setMultiplicableQuantities, stringToKey, updateSingle, validateDirtyFormFields, validateEntireForm, validationMessage, validationToString, viewButton, viewText, themeToPalette

-}

import Dict
import Element exposing (..)
import Json.Decode
import R10.Form.Internal.Conf
import R10.Form.Internal.FieldConf
import R10.Form.Internal.FieldState
import R10.Form.Internal.Helpers
import R10.Form.Internal.Key
import R10.Form.Internal.MakerForValues
import R10.Form.Internal.MakerForView
import R10.Form.Internal.Shared
import R10.Form.Internal.State
import R10.Form.Internal.StateForValues
import R10.Form.Internal.Update
import R10.Form.Internal.Validation
import R10.Form.Internal.ValidationCode
import R10.Form.Msg
import R10.FormComponents.Binary
import R10.FormComponents.Button
import R10.FormComponents.ExtraCss
import R10.FormComponents.IconButton
import R10.FormComponents.Phone
import R10.FormComponents.Phone.Common
import R10.FormComponents.Phone.Country
import R10.FormComponents.Phone.Update
import R10.FormComponents.Single
import R10.FormComponents.Single.Common
import R10.FormComponents.Single.Update
import R10.FormComponents.Style
import R10.FormComponents.Text
import R10.FormComponents.UI
import R10.FormComponents.UI.Color
import R10.FormComponents.UI.Palette
import R10.FormComponents.Utils.FocusOut
import R10.FormComponents.Validations
import R10.SimpleMarkdown
import R10.Theme


{-| -}
type alias MakerArgs =
    { key : Key
    , formState : State
    , translator : ValidationCode -> String
    , style : Style
    , palette : Palette
    }


{-| Just a `String`
-}
type alias ValidationCode =
    R10.Form.Internal.FieldConf.ValidationCode


{-| -}
type alias Maker =
    MakerArgs
    -> List R10.Form.Internal.Conf.Entity
    -> List (Element R10.Form.Msg.Msg)


{-| -}
type alias Options =
    { maker : Maybe Maker
    , translator : Maybe (ValidationCode -> String)
    , style : Style
    , palette : Maybe Palette
    }


{-| -}
type alias MsgMapper msg =
    Msg -> msg


{-| This is the simplest way to render a form, as you can see in this minimalistic example:

    module Main exposing (main)

    import Element exposing (..)
    import Html
    import R10.Form

    formModel : R10.Form.Internal.Form
    formModel =
        { conf =
            [ R10.Form.Internal.entity.field
                { id = "email"
                , idDom = Nothing
                , type_ = R10.Form.Internal.fieldType.text R10.Form.Internal.text.email
                , label = "Email"
                , helperText = Just "My first form"
                , requiredLabel = Nothing
                , validationSpecs = Nothing
                }
            ]
        , state = R10.Form.Internal.initState
        }

    formMsgMapper : R10.Form.MsgMapper ()
    formMsgMapper =
        \_ -> ()

    main : Html.Html ()
    main =
        layout [] <|
            column [ centerX, centerY ] <|
                R10.Form.Internal.view formModel formMsgMapper

Note that the form of this example is not active because it is just rendering the view but it is not wired to The Elm Architecture. In interested, look at the code of an [active form example](https://github.com/rakutentech/r10/blob/master/examples/simpleForm/src/Main.elm).

-}
view : Form -> MsgMapper msg -> List (Element msg)
view form msgMapper =
    viewWithOptions form
        msgMapper
        { maker = Nothing
        , translator = Nothing
        , style = style.outlined
        , palette = Nothing
        }


{-| Use this version if you have a specific palette that you want to use.
-}
viewWithPalette : Form -> MsgMapper msg -> Palette -> List (Element msg)
viewWithPalette form msgMapper palette =
    viewWithOptions form
        msgMapper
        { maker = Nothing
        , translator = Nothing
        , style = style.outlined
        , palette = Just palette
        }


{-| Use this version if you have `R10.Theme.Theme`.
-}
viewWithTheme : Form -> MsgMapper msg -> R10.Theme.Theme -> List (Element msg)
viewWithTheme form msgMapper theme =
    let
        palette =
            R10.FormComponents.UI.Palette.fromTheme theme
    in
    viewWithOptions form
        msgMapper
        { maker = Nothing
        , translator = Nothing
        , style = style.outlined
        , palette = Just palette
        }


{-| Use this version for full control.
-}
viewWithOptions : Form -> MsgMapper msg -> Options -> List (Element msg)
viewWithOptions form msgMapper args =
    List.map
        (map msgMapper)
        (Maybe.withDefault R10.Form.Internal.MakerForView.maker
            args.maker
            { key = R10.Form.Internal.Key.empty
            , formState = form.state
            , translator = Maybe.withDefault defaultTranslator args.translator
            , style = args.style
            , palette = Maybe.withDefault R10.FormComponents.UI.Palette.light args.palette
            }
            form.conf
        )


{-| -}
defaultTranslator : ValidationCode -> String
defaultTranslator =
    R10.Form.Internal.ValidationCode.translator


{-| -}
themeToPalette : R10.Theme.Theme -> Palette
themeToPalette =
    R10.FormComponents.UI.Palette.fromTheme



-- EXPOSING STUFF FROM R10.Form.Internal.MakerForView


{-| -}
extraCss : Maybe Palette -> String
extraCss =
    R10.Form.Internal.MakerForView.extraCss



-- EXPOSING STUFF FROM R10.Form.Internal.Conf


{-| `Conf` is simply defined as a `List Entity`.
-}
type alias Conf =
    R10.Form.Internal.Conf.Conf


{-| A form is made of multiple **entities**. An example of entity is an input field, a title, a subtitle, etc.
-}
type alias Entity =
    R10.Form.Internal.Conf.Entity


{-| -}
type alias EntityId =
    R10.Form.Internal.Conf.EntityId


{-| -}
type alias TextConf =
    R10.Form.Internal.Conf.TextConf


{-| These are the constructors for entities
-}
entity :
    { field : FieldConf -> Entity
    , multi : EntityId -> List Entity -> Entity
    , normal : EntityId -> List Entity -> Entity
    , subTitle : EntityId -> TextConf -> Entity
    , title : EntityId -> TextConf -> Entity
    , withBorder : EntityId -> List Entity -> Entity
    , withTabs : EntityId -> List ( String, Entity ) -> Entity
    , wrappable : EntityId -> List Entity -> Entity
    }
entity =
    { normal = R10.Form.Internal.Conf.EntityNormal
    , wrappable = R10.Form.Internal.Conf.EntityWrappable
    , withBorder = R10.Form.Internal.Conf.EntityWithBorder
    , withTabs = R10.Form.Internal.Conf.EntityWithTabs
    , multi = R10.Form.Internal.Conf.EntityMulti
    , field = R10.Form.Internal.Conf.EntityField
    , title = R10.Form.Internal.Conf.EntityTitle
    , subTitle = R10.Form.Internal.Conf.EntitySubTitle
    }


{-| -}
initConf : List Entity
initConf =
    R10.Form.Internal.Conf.init


{-| -}
stringToConf : String -> Result Json.Decode.Error Conf
stringToConf =
    R10.Form.Internal.Conf.fromString


{-| -}
confToString : Conf -> String
confToString =
    R10.Form.Internal.Conf.toString



-- EXPOSING STUFF FROM R10.Form.Internal.FieldConf


{-| -}
type alias FieldConf =
    R10.Form.Internal.FieldConf.FieldConf


{-| -}
type alias TypeSingle =
    R10.Form.Internal.FieldConf.TypeSingle


{-| -}
type alias FieldType =
    R10.Form.Internal.FieldConf.FieldType


{-| -}
type alias TypeBinary =
    R10.Form.Internal.FieldConf.TypeBinary


{-| -}
type alias TypeMulti =
    R10.Form.Internal.FieldConf.TypeMulti


{-| -}
type alias TypeText =
    R10.Form.Internal.FieldConf.TypeText


{-| -}
type alias FieldOption =
    R10.Form.Internal.FieldConf.FieldOption


{-| -}
type alias ValidationIcon =
    R10.Form.Internal.FieldConf.ValidationIcon


{-| -}
type alias Validation =
    R10.Form.Internal.FieldConf.Validation


{-| -}
type alias ValidationMessage =
    R10.Form.Internal.FieldConf.ValidationMessage


{-| -}
type alias ValidationSpecs =
    R10.Form.Internal.FieldConf.ValidationSpecs


{-| -}
fieldType :
    { text : TypeText -> FieldType
    , single : TypeSingle -> List FieldOption -> FieldType
    , multi : TypeMulti -> List FieldOption -> FieldType
    , binary : TypeBinary -> FieldType
    }
fieldType =
    { text = R10.Form.Internal.FieldConf.TypeText
    , single = R10.Form.Internal.FieldConf.TypeSingle
    , multi = R10.Form.Internal.FieldConf.TypeMulti
    , binary = R10.Form.Internal.FieldConf.TypeBinary
    }


{-| -}
single :
    { combobox : TypeSingle
    , radio : TypeSingle
    }
single =
    { combobox = R10.Form.Internal.FieldConf.SingleCombobox
    , radio = R10.Form.Internal.FieldConf.SingleRadio
    }


{-| -}
text :
    { plain : TypeText
    , email : TypeText
    , username : TypeText
    , passwordNew : TypeText
    , passwordCurrent : TypeText
    , multiline : TypeText
    , withPattern : String -> TypeText
    }
text =
    { plain = R10.Form.Internal.FieldConf.TextPlain
    , email = R10.Form.Internal.FieldConf.TextEmail
    , username = R10.Form.Internal.FieldConf.TextUsername
    , passwordNew = R10.Form.Internal.FieldConf.TextPasswordNew
    , passwordCurrent = R10.Form.Internal.FieldConf.TextPasswordCurrent
    , multiline = R10.Form.Internal.FieldConf.TextMultiline
    , withPattern = R10.Form.Internal.FieldConf.TextWithPattern
    }


{-| -}
validationIcon :
    { clearOrCheck : ValidationIcon
    , errorOrCheck : ValidationIcon
    , noIcon : ValidationIcon
    }
validationIcon =
    { noIcon = R10.Form.Internal.FieldConf.NoIcon
    , clearOrCheck = R10.Form.Internal.FieldConf.ClearOrCheck -- clear aka cross
    , errorOrCheck = R10.Form.Internal.FieldConf.ErrorOrCheck -- "!" in circle, just like Google's
    }


{-| -}
validation :
    { allOf : List Validation -> Validation
    , dependant : KeyAsString -> Validation -> Validation
    , equal : KeyAsString -> Validation
    , maxLength : Int -> Validation
    , minLength : Int -> Validation
    , noValidation : Validation
    , oneOf : List Validation -> Validation
    , regex : String -> Validation
    , required : Validation
    , withMsg : ValidationMessage -> Validation -> Validation
    , empty : Validation
    , not : Validation -> Validation
    }
validation =
    { noValidation = R10.Form.Internal.FieldConf.NoValidation
    , withMsg = R10.Form.Internal.FieldConf.WithMsg
    , dependant = R10.Form.Internal.FieldConf.Dependant
    , oneOf = R10.Form.Internal.FieldConf.OneOf
    , allOf = R10.Form.Internal.FieldConf.AllOf
    , equal = R10.Form.Internal.FieldConf.Equal
    , required = R10.Form.Internal.FieldConf.Required
    , minLength = R10.Form.Internal.FieldConf.MinLength
    , maxLength = R10.Form.Internal.FieldConf.MaxLength
    , regex = R10.Form.Internal.FieldConf.Regex
    , empty = R10.Form.Internal.FieldConf.Empty
    , not = R10.Form.Internal.FieldConf.Not
    }


{-| -}
binary :
    { checkbox : R10.Form.Internal.FieldConf.TypeBinary
    , switch : R10.Form.Internal.FieldConf.TypeBinary
    }
binary =
    { checkbox = R10.Form.Internal.FieldConf.BinaryCheckbox
    , switch = R10.Form.Internal.FieldConf.BinarySwitch
    }


{-| -}
binary2 :
    { checkbox : R10.FormComponents.Binary.TypeBinary
    , switch : R10.FormComponents.Binary.TypeBinary
    }
binary2 =
    { checkbox = R10.FormComponents.Binary.BinaryCheckbox
    , switch = R10.FormComponents.Binary.BinarySwitch
    }


{-| -}
initFieldConf : R10.Form.Internal.FieldConf.FieldConf
initFieldConf =
    R10.Form.Internal.FieldConf.init



-- EXPOSING STUFF FROM R10.Form.Internal.FieldState


{-| -}
type alias FieldState =
    R10.Form.Internal.FieldState.FieldState



-- EXPOSING STUFF FROM R10.Form.Internal.State


{-| The state is defined as

    type alias State =
        { fieldsState : Dict KeyAsString FieldState
        , multiplicableQuantities : Dict KeyAsString Int
        , activeTabs : Dict KeyAsString String
        , focused : Maybe KeyAsString
        , active : Maybe KeyAsString
        , removed : Set KeyAsString
        , qtySubmitAttempted : QtySubmitAttempted
        , changesSinceLastSubmissions : Bool
        }

Where:

  - `fieldState` is a dictionary containing the states of all fields.
  - `multiplicableQuantities` is a dictionary containin the quantity of a _multiplicable_ field. A _multiplicable_ field is a field that the user can clone to add extra information.
  - `activeTabs` describe which tab is active in case tabs are used to group objects of the form.
  - `focused` is the focused element of the form at the present moment.
  - `active`... what is `active`?
  - `removed` contains _multiplicable_ input fields that have been removed by the user.
  - `qtySubmitAttempted` is the number of times that the user tried to submit the form.
  - `changesSinceLastSubmissions` is `True` if the user changed something after the last for submission.

-}
type alias State =
    R10.Form.Internal.State.State


{-| -}
initState : State
initState =
    R10.Form.Internal.State.init


{-| This can be useful to store the state of a form to the Local Storage, for example. Then, using `stringToState` is possible to restore all the values of a form or keep the form sync'ed on different tabs.
-}
stateToString : R10.Form.Internal.State.State -> String
stateToString =
    R10.Form.Internal.State.toString


{-| -}
stringToState : String -> Result Json.Decode.Error R10.Form.Internal.State.State
stringToState =
    R10.Form.Internal.State.fromString



-- EXPOSING STUFF FROM R10.Form.Internal.Update


{-| -}
update : Msg -> State -> ( State, Cmd Msg )
update =
    R10.Form.Internal.Update.update


{-| -}
shouldShowTheValidationOverview : R10.Form.Internal.State.State -> Bool
shouldShowTheValidationOverview =
    R10.Form.Internal.Update.shouldShowTheValidationOverview


{-| -}
allValidationKeysMaker : Conf -> State -> List ( Key, Maybe ValidationSpecs )
allValidationKeysMaker =
    R10.Form.Internal.Update.allValidationKeysMaker


{-| -}
entitiesWithErrors : List ( Key, Maybe ValidationSpecs ) -> Dict.Dict KeyAsString FieldState -> List ( Key, Maybe ValidationSpecs )
entitiesWithErrors =
    R10.Form.Internal.Update.entitiesWithErrors


{-| -}
runOnlyExistingValidations : List ( Key, Maybe ValidationSpecs ) -> State -> Dict.Dict KeyAsString FieldState -> Dict.Dict KeyAsString FieldState
runOnlyExistingValidations =
    R10.Form.Internal.Update.runOnlyExistingValidations


{-| -}
submittable : Conf -> State -> Bool
submittable =
    R10.Form.Internal.Update.submittable


{-| -}
isFormSubmittableAndSubmitted : Conf -> State -> Msg -> Bool
isFormSubmittableAndSubmitted =
    R10.Form.Internal.Update.isFormSubmittableAndSubmitted



-- EXPOSING STUFF FROM R10.Form.Msg


{-| -}
type alias Msg =
    R10.Form.Msg.Msg


{-| -}
msg : { submit : Conf -> Msg }
msg =
    { submit = R10.Form.Msg.Submit }



-- EXPOSING STUFF FROM R10.Form.Internal.Shared


{-| A form is defined by the **configuration** (`R10.Form.Conf`) that contain data about the input fields, radio buttons, etc. and the **state** (`R10.Form.State`), containing instead all the values and other parameters that change during the life of the form.

    type alias Form =
        { conf : R10.Form.Internal.Conf
        , state : R10.Form.Internal.State
        }

-}
type alias Form =
    R10.Form.Internal.Shared.Form



-- EXPOSING STUFF FROM R10.Form.Internal.Key


{-| -}
type alias Key =
    R10.Form.Internal.Key.Key


{-| -}
type alias KeyAsString =
    R10.Form.Internal.Key.KeyAsString


{-| -}
keyToString : Key -> KeyAsString
keyToString =
    R10.Form.Internal.Key.toString



-- EXPOSING STUFF FROM R10.Form.Internal.Helpers


{-| -}
getFieldValueAsBool : KeyAsString -> State -> Maybe Bool
getFieldValueAsBool =
    R10.Form.Internal.Helpers.getFieldValueAsBool


{-| -}
getFieldValue : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe String
getFieldValue =
    R10.Form.Internal.Helpers.getFieldValue


{-| -}
stringToBool : String -> Bool
stringToBool =
    R10.Form.Internal.Helpers.stringToBool


{-| -}
boolToString : Bool -> String
boolToString =
    R10.Form.Internal.Helpers.boolToString



-- EXPOSING STUFF FROM R10.Form.Internal.Validation


{-| -}
commonValidation :
    { alphaNumericDash : Validation
    , alphaNumericDashSpace : Validation
    , email : Validation
    , hexColor : Validation
    , numeric : Validation
    , password : Validation
    , phoneNumber : Validation
    , url : Validation
    }
commonValidation =
    R10.Form.Internal.Validation.commonValidation


{-| -}
setFieldValue : KeyAsString -> String -> State -> State
setFieldValue =
    R10.Form.Internal.Helpers.setFieldValue


{-| -}
getField : KeyAsString -> State -> Maybe FieldState
getField =
    R10.Form.Internal.Helpers.getField


{-| -}
validate : Key -> Maybe ValidationSpecs -> State -> FieldState -> FieldState
validate =
    R10.Form.Internal.Validation.validate


{-| -}
isChangingValues : Msg -> Bool
isChangingValues =
    R10.Form.Msg.isChangingValues



-- IMPORTING STUFF FROM FormComponents


{-|

    type alias Palette =
        { primary : Color
        , primaryVariant : Color
        , success : Color
        , error : Color

        -- Text Colors
        --
        , onSurface : Color
        , onPrimary : Color

        -- Background Colors
        --
        , surface : Color
        , background : Color
        }

Note that these are `Element.Color` from `elm-ui`.

See <https://material.io/design/color/dark-theme.html#properties> for more details.

If you want to use the default palette, just pass `Nothing`

-}
type alias Palette =
    R10.FormComponents.UI.Palette.Palette


{-| -}
type alias Style =
    R10.FormComponents.Style.Style


{-| -}
type alias SingleModel =
    R10.FormComponents.Single.Common.Model


{-| -}
type alias SingleMsg =
    R10.FormComponents.Single.Common.Msg


{-| -}
type alias SingleType =
    R10.FormComponents.Single.Common.TypeSingle


{-| -}
type alias SingleFieldOption =
    R10.FormComponents.Single.Common.FieldOption


{-| -}
type alias Validation2 =
    R10.FormComponents.Validations.Validation


{-| -}
style :
    { filled : Style
    , outlined : Style
    }
style =
    { filled = R10.FormComponents.Style.Filled
    , outlined = R10.FormComponents.Style.Outlined
    }


{-| -}
label : Palette -> Color
label =
    R10.FormComponents.UI.Color.label


{-| -}
onClickWithStopPropagation : msg -> Attribute msg
onClickWithStopPropagation =
    R10.FormComponents.UI.onClickWithStopPropagation


{-| -}
viewIconButton :
    List (Element.Attribute msg)
    ->
        { icon : Element msg
        , msgOnClick : Maybe msg
        , palette : Palette
        , size : Int
        }
    -> Element msg
viewIconButton =
    R10.FormComponents.IconButton.view


{-| -}
viewSingleCustom :
    List (Element.Attribute msg)
    -> SingleModel
    ->
        { disabled : Bool
        , fieldOptions : List SingleFieldOption
        , helperText : Maybe String
        , key : String
        , label : String
        , leadingIcon : Maybe (Element.Element msg)
        , maxDisplayCount : Int
        , palette : Palette
        , requiredLabel : Maybe String
        , searchFn : String -> SingleFieldOption -> Bool
        , selectOptionHeight : Int
        , singleType : SingleType
        , style : Style
        , toMsg : SingleMsg -> msg
        , toOptionEl : SingleFieldOption -> Element msg
        , trailingIcon : Maybe (Element.Element msg)
        , validation : Validation2
        }
    -> Element msg
viewSingleCustom =
    R10.FormComponents.Single.viewCustom


{-| -}
defaultSearchFn : String -> SingleFieldOption -> Bool
defaultSearchFn =
    R10.FormComponents.Single.defaultSearchFn


{-| -}
initSingle : SingleModel
initSingle =
    R10.FormComponents.Single.Common.init


{-| -}
typeSingle :
    { combobox : SingleType
    , radio : SingleType
    }
typeSingle =
    { radio = R10.FormComponents.Single.Common.SingleRadio
    , combobox = R10.FormComponents.Single.Common.SingleCombobox
    }



--
-- updateSingle : SingleMsg -> SingleModel -> ( SingleModel, Cmd SingleMsg )
-- updateSingle =
--     R10.FormComponents.Single.update
--


{-| -}
normalizeString : String -> String
normalizeString =
    R10.FormComponents.Single.normalizeString


{-| -}
insertBold : List Int -> String -> String
insertBold =
    R10.FormComponents.Single.insertBold


{-| -}
defaultToOptionEl :
    { a | msgOnSelect : String -> msg, search : String }
    -> SingleFieldOption
    -> Element msg
defaultToOptionEl =
    R10.FormComponents.Single.defaultToOptionEl


{-| -}
defaultTrailingIcon :
    { a | opened : Bool, palette : Palette }
    -> Element msg
defaultTrailingIcon =
    R10.FormComponents.Single.defaultTrailingIcon


{-| -}
singleMsg : { onOptionSelect : String -> SingleMsg }
singleMsg =
    { onOptionSelect = R10.FormComponents.Single.Common.OnOptionSelect }



-- NEW ADDITIONS AFTER SSP


{-| -}
getMultiActiveKeys : R10.Form.Internal.Key.Key -> R10.Form.Internal.State.State -> List R10.Form.Internal.Key.Key
getMultiActiveKeys =
    R10.Form.Internal.Helpers.getMultiActiveKeys


{-| -}
stringToKey : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.Key.Key
stringToKey =
    R10.Form.Internal.Key.fromString


{-| -}
composeKey : R10.Form.Internal.Key.Key -> String -> R10.Form.Internal.Key.Key
composeKey =
    R10.Form.Internal.Key.composeKey


{-| -}
setFieldValidationError :
    R10.Form.Internal.Key.KeyAsString
    -> String
    -> R10.Form.Internal.State.State
    -> R10.Form.Internal.State.State
setFieldValidationError =
    R10.Form.Internal.Helpers.setFieldValidationError


{-| -}
initFieldState : R10.Form.Internal.FieldState.FieldState
initFieldState =
    R10.Form.Internal.FieldState.init


{-| -}
updateSingle :
    R10.FormComponents.Single.Common.Msg
    -> R10.FormComponents.Single.Common.Model
    ->
        ( R10.FormComponents.Single.Common.Model
        , Cmd R10.FormComponents.Single.Common.Msg
        )
updateSingle =
    R10.FormComponents.Single.Update.update


{-| -}
initValidationSpecs : R10.Form.Internal.FieldConf.ValidationSpecs
initValidationSpecs =
    R10.Form.Internal.FieldConf.initValidationSpecs


{-| -}
listToKey : List String -> R10.Form.Internal.Key.Key
listToKey =
    R10.Form.Internal.Key.fromList


{-| -}
setMultiplicableQuantities : R10.Form.Internal.Key.KeyAsString -> Int -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setMultiplicableQuantities =
    R10.Form.Internal.Helpers.setMultiplicableQuantities


{-| -}
clearFieldValidation : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
clearFieldValidation =
    R10.Form.Internal.Helpers.clearFieldValidation


{-| -}
headId : R10.Form.Internal.Key.Key -> Maybe String
headId =
    R10.Form.Internal.Key.headId


{-| -}
viewButton : List (Attribute msg) -> R10.FormComponents.Button.Args msg -> Element msg
viewButton =
    R10.FormComponents.Button.view


{-| -}
button :
    { contained : R10.FormComponents.Button.Button
    , outlined : R10.FormComponents.Button.Button
    , text : R10.FormComponents.Button.Button
    , icon : R10.FormComponents.Button.Button
    }
button =
    { outlined = R10.FormComponents.Button.Outlined
    , contained = R10.FormComponents.Button.Contained
    , text = R10.FormComponents.Button.Text
    , icon = R10.FormComponents.Button.Icon
    }


{-| -}
setFieldDisabled : R10.Form.Internal.Key.KeyAsString -> Bool -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setFieldDisabled =
    R10.Form.Internal.Helpers.setFieldDisabled


{-| -}
getActiveTab : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe String
getActiveTab =
    R10.Form.Internal.Helpers.getActiveTab


{-| -}
setActiveTab : KeyAsString -> String -> State -> State
setActiveTab =
    R10.Form.Internal.Helpers.setActiveTab


{-| -}
validateEntireForm : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
validateEntireForm =
    R10.Form.Internal.Update.validateEntireForm


{-| -}
validateDirtyFormFields : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
validateDirtyFormFields =
    R10.Form.Internal.Update.validateDirtyFormFields


{-| -}
isExistingFormFieldsValid : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> Bool
isExistingFormFieldsValid =
    R10.Form.Internal.Update.isExistingFormFieldsValid


{-| -}
colorToCssString : Color -> String
colorToCssString =
    R10.FormComponents.UI.Color.toCssString


{-| -}
elementMarkdown : String -> List (Element msg)
elementMarkdown =
    R10.SimpleMarkdown.elementMarkdown


{-| -}
componentValidation :
    { notYetValidated : R10.FormComponents.Validations.Validation
    , validated :
        List R10.FormComponents.Validations.ValidationMessage
        -> R10.FormComponents.Validations.Validation
    }
componentValidation =
    { notYetValidated = R10.FormComponents.Validations.NotYetValidated
    , validated = R10.FormComponents.Validations.Validated
    }


{-| -}
onFocusOut : String -> msg -> Json.Decode.Decoder msg
onFocusOut =
    R10.FormComponents.Utils.FocusOut.onFocusOut


{-| -}
entitiesToString : List R10.Form.Internal.StateForValues.Entity -> String
entitiesToString =
    R10.Form.Internal.StateForValues.toString


{-| -}
maker :
    R10.Form.Internal.Key.Key
    -> R10.Form.Internal.State.State
    -> R10.Form.Internal.Conf.Conf
    -> List R10.Form.Internal.StateForValues.Entity
maker =
    R10.Form.Internal.MakerForValues.maker


{-| -}
emptyKey : R10.Form.Internal.Key.Key
emptyKey =
    R10.Form.Internal.Key.empty


{-| -}
validationCodes :
    { allOf : R10.Form.Internal.FieldConf.ValidationCode
    , emailFormatInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , emailFormatValid : R10.Form.Internal.FieldConf.ValidationCode
    , empty : R10.Form.Internal.FieldConf.ValidationCode
    , equalInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatInvalidCharactersInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatNoNumberInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatNoSpecialCharactersInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatNoUppercaseInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , formatValid : R10.Form.Internal.FieldConf.ValidationCode
    , hexColorFormatInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , jsonFormatInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , lengthTooLargeInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , lengthTooSmallInvalid : R10.Form.Internal.FieldConf.ValidationCode
    , oneOf : R10.Form.Internal.FieldConf.ValidationCode
    , required : R10.Form.Internal.FieldConf.ValidationCode
    , requiredField : R10.Form.Internal.FieldConf.ValidationCode
    , somethingWrong : R10.Form.Internal.FieldConf.ValidationCode
    , valueInvalid : R10.Form.Internal.FieldConf.ValidationCode
    }
validationCodes =
    R10.Form.Internal.ValidationCode.validationCodes


{-| -}
type alias TextType =
    R10.FormComponents.Text.TextType


{-| -}
validationToString : R10.FormComponents.Validations.Validation -> String
validationToString =
    R10.FormComponents.Validations.validationToString


{-| -}
viewText :
    List (Attribute msg)
    -> List (Attribute msg)
    -> R10.FormComponents.Text.Args msg
    -> Element msg
viewText =
    R10.FormComponents.Text.view


{-| -}
extraCssComponents : Palette -> String
extraCssComponents =
    R10.FormComponents.ExtraCss.extraCss


{-| -}
validationMessage :
    { error : String -> R10.FormComponents.Validations.ValidationMessage
    , ok : String -> R10.FormComponents.Validations.ValidationMessage
    }
validationMessage =
    { ok = R10.FormComponents.Validations.MessageOk
    , error = R10.FormComponents.Validations.MessageErr
    }


{-| -}
componentTextType :
    { email : R10.FormComponents.Text.TextType
    , multiline : R10.FormComponents.Text.TextType
    , passwordCurrent : R10.FormComponents.Text.TextType
    , passwordNew : R10.FormComponents.Text.TextType
    , plain : R10.FormComponents.Text.TextType
    , username : R10.FormComponents.Text.TextType
    , withPattern : String -> R10.FormComponents.Text.TextType
    }
componentTextType =
    { plain = R10.FormComponents.Text.TextPlain
    , email = R10.FormComponents.Text.TextEmail
    , username = R10.FormComponents.Text.TextUsername
    , passwordNew = R10.FormComponents.Text.TextPasswordNew
    , passwordCurrent = R10.FormComponents.Text.TextPasswordCurrent
    , multiline = R10.FormComponents.Text.TextMultiline
    , withPattern = R10.FormComponents.Text.TextWithPattern
    }


{-| -}
binaryView : List (Attribute msg) -> R10.FormComponents.Binary.Args msg -> Element msg
binaryView =
    R10.FormComponents.Binary.view


{-| -}
type alias PhoneModel =
    R10.FormComponents.Phone.Common.Model


{-| -}
type alias PhoneMsg =
    R10.FormComponents.Phone.Common.Msg


{-| -}
phoneView :
    List (Attribute msg)
    -> R10.FormComponents.Phone.Common.Model
    ->
        { countryOptions : Maybe (List R10.FormComponents.Phone.Country.Country)
        , disabled : Bool
        , helperText : Maybe String
        , key : String
        , label : String
        , palette : Palette
        , requiredLabel : Maybe String
        , style : R10.FormComponents.Style.Style
        , toMsg : R10.FormComponents.Phone.Common.Msg -> msg
        , validation : R10.FormComponents.Validations.Validation
        }
    -> Element msg
phoneView =
    R10.FormComponents.Phone.view


{-| -}
phoneUpdate :
    R10.FormComponents.Phone.Common.Msg
    -> R10.FormComponents.Phone.Common.Model
    ->
        ( R10.FormComponents.Phone.Common.Model
        , Cmd R10.FormComponents.Phone.Common.Msg
        )
phoneUpdate =
    R10.FormComponents.Phone.Update.update


{-| -}
phoneInit : R10.FormComponents.Phone.Common.Model
phoneInit =
    R10.FormComponents.Phone.Common.init

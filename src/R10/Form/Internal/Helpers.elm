module R10.Form.Internal.Helpers exposing
    ( boolToString
    , clearFieldValidation
    , getActiveTab
    , getField
    , getFieldValue
    , getFieldValueAsBool
    , getMultiActiveKeys
    , setActiveTab
    , setFieldDisabled
    , setFieldValidationError
    , setFieldValue
    , setMultiplicableQuantities
    , stringToBool
    )

import Dict
import R10.Form.Internal.Dict
import R10.Form.Internal.FieldState
import R10.Form.Internal.Key
import R10.Form.Internal.State
import Set


stringToBool : String -> Bool
stringToBool string =
    String.toLower string == "true"


boolToString : Bool -> String
boolToString bool =
    if bool then
        "True"

    else
        "False"


getActiveTab : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe String
getActiveTab onId formState =
    Dict.get onId formState.activeTabs


setActiveTab : R10.Form.Internal.Key.KeyAsString -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setActiveTab onId newTab formState =
    { formState | activeTabs = Dict.insert onId newTab formState.activeTabs }


getField : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe R10.Form.Internal.FieldState.FieldState
getField key formState =
    Dict.get key formState.fieldsState


getFieldValue : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe String
getFieldValue key formState =
    getField key formState
        |> Maybe.map .value


getFieldValueAsBool : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> Maybe Bool
getFieldValueAsBool key formState =
    getFieldValue key formState
        |> Maybe.map stringToBool


setFieldDisabled : R10.Form.Internal.Key.KeyAsString -> Bool -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setFieldDisabled key isDisabled formState =
    let
        newFieldsState : R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            Dict.get key formState.fieldsState
                |> Maybe.withDefault R10.Form.Internal.FieldState.init
    in
    { formState
        | fieldsState =
            Dict.insert key { newFieldsState | disabled = isDisabled } formState.fieldsState
    }


setFieldValue : R10.Form.Internal.Key.KeyAsString -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setFieldValue key value formState =
    let
        newFieldsState : R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            Dict.get key formState.fieldsState
                |> Maybe.withDefault R10.Form.Internal.FieldState.init
    in
    { formState
        | fieldsState =
            Dict.insert key { newFieldsState | value = value } formState.fieldsState
    }


setMultiplicableQuantities : R10.Form.Internal.Key.KeyAsString -> Int -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setMultiplicableQuantities multiId quantity state =
    { state
        | multiplicableQuantities = Dict.insert multiId quantity state.multiplicableQuantities
    }


setFieldValidationError : R10.Form.Internal.Key.KeyAsString -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
setFieldValidationError key value formState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            Dict.get key formState.fieldsState
                |> Maybe.withDefault R10.Form.Internal.FieldState.init

        newError : R10.Form.Internal.FieldState.ValidationOutcome
        newError =
            R10.Form.Internal.FieldState.MessageErr value []

        newValidation : R10.Form.Internal.FieldState.Validation
        newValidation =
            case fieldState.validation of
                R10.Form.Internal.FieldState.NotYetValidated ->
                    R10.Form.Internal.FieldState.Validated [ newError ]

                R10.Form.Internal.FieldState.Validated listValidationOutcome ->
                    R10.Form.Internal.FieldState.Validated <| newError :: listValidationOutcome

        newFieldsState : Dict.Dict String R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            Dict.insert key { fieldState | validation = newValidation } formState.fieldsState
    in
    { formState | fieldsState = newFieldsState }


clearFieldValidation : R10.Form.Internal.Key.KeyAsString -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
clearFieldValidation key formState =
    let
        newFieldsState : R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            Dict.get key formState.fieldsState
                |> Maybe.withDefault R10.Form.Internal.FieldState.init
    in
    { formState
        | fieldsState =
            Dict.insert key
                { newFieldsState
                    | validation =
                        case newFieldsState.validation of
                            R10.Form.Internal.FieldState.NotYetValidated ->
                                R10.Form.Internal.FieldState.NotYetValidated

                            R10.Form.Internal.FieldState.Validated _ ->
                                R10.Form.Internal.FieldState.Validated []
                }
                formState.fieldsState
    }


getMultiActiveKeys : R10.Form.Internal.Key.Key -> R10.Form.Internal.State.State -> List R10.Form.Internal.Key.Key
getMultiActiveKeys key formState =
    let
        quantity : Int
        quantity =
            Maybe.withDefault 1 <| R10.Form.Internal.Dict.get key formState.multiplicableQuantities

        notRemoved : R10.Form.Internal.Key.Key -> Bool
        notRemoved newKey =
            not <| Set.member (R10.Form.Internal.Key.toString newKey) formState.removed
    in
    R10.Form.Internal.Key.composeMultiKeys key quantity
        |> List.filter notRemoved

module R10.Form.Internal.Update exposing
    ( allErrorsForView
    , allValidationKeysMaker
    , entitiesWithErrors
    , entitiesWithErrorsForOnlyExistingValidations
    , isEntireFormValid
    , isExistingFormFieldsValid
    , isFormSubmittableAndSubmitted
    , runAllValidations
    , runOnlyExistingValidations
    , shouldShowTheValidationOverview
    , submit
    , submittable
    , update
    , validateDirtyFormFields
    , validateEntireForm
    )

import Dict
import R10.Form.Internal.Conf
import R10.Form.Internal.Dict
import R10.Form.Internal.FieldConf
import R10.Form.Internal.FieldState
import R10.Form.Internal.Key
import R10.Form.Internal.MakerForValidationKeys
import R10.Form.Internal.QtySubmitAttempted as QtySubmitAttempted exposing (QtySubmitAttempted)
import R10.Form.Internal.State
import R10.Form.Internal.Validation
import R10.Form.Msg
import R10.FormComponents.Single.Common
import R10.FormComponents.Single.Update
import Set


stateWithDefault : Maybe R10.Form.Internal.FieldState.FieldState -> R10.Form.Internal.FieldState.FieldState
stateWithDefault maybeFieldState =
    Maybe.withDefault R10.Form.Internal.FieldState.init maybeFieldState



-- ██   ██ ███████ ██      ██████  ███████ ██████  ███████
-- ██   ██ ██      ██      ██   ██ ██      ██   ██ ██
-- ███████ █████   ██      ██████  █████   ██████  ███████
-- ██   ██ ██      ██      ██      ██      ██   ██      ██
-- ██   ██ ███████ ███████ ██      ███████ ██   ██ ███████


{-| Is there no validation error inside the form
-}
isEntireFormValid : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> Bool
isEntireFormValid conf state =
    let
        allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        allKeys =
            allValidationKeysMaker conf state

        fieldsWithErrors_ : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        fieldsWithErrors_ =
            entitiesWithErrors allKeys state.fieldsState
    in
    List.head fieldsWithErrors_ == Nothing


{-| Is there no validation error inside the form
-}
isExistingFormFieldsValid : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> Bool
isExistingFormFieldsValid conf state =
    let
        allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        allKeys =
            allValidationKeysMaker conf state

        fieldsWithErrors_ : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        fieldsWithErrors_ =
            entitiesWithErrorsForOnlyExistingValidations allKeys state.fieldsState
    in
    List.head fieldsWithErrors_ == Nothing


{-| Validate the entire form
-}
validateEntireForm : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
validateEntireForm conf state =
    let
        allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        allKeys =
            allValidationKeysMaker conf state

        newFieldsState : Dict.Dict String R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            runAllValidations allKeys state state.fieldsState
    in
    { state | fieldsState = newFieldsState }


{-| Validate the entire form
-}
validateDirtyFormFields : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
validateDirtyFormFields conf state =
    let
        allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        allKeys =
            allValidationKeysMaker conf state

        newFieldsState : Dict.Dict String R10.Form.Internal.FieldState.FieldState
        newFieldsState =
            runOnlyExistingValidations allKeys state state.fieldsState
    in
    { state | fieldsState = newFieldsState }


helperToggleShowPassword : Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperToggleShowPassword maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | showPassword = not fieldState.showPassword }


helperUpdateValue : String -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperUpdateValue value maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | value = value }


helperUpdateSearch : String -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperUpdateSearch value maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | search = value }


helperUpdateSelect : String -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperUpdateSelect value maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | select = value }


helperUpdateScroll : Float -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperUpdateScroll value maybeScroll =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeScroll
    in
    Just { fieldState | scroll = value }


helperUpdateDirty : Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperUpdateDirty maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | dirty = True }


helperLostFocus : Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperLostFocus maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just { fieldState | lostFocusOneOrMoreTime = True }


helperValidateCreatingFieldsState : R10.Form.Internal.Key.Key -> Maybe R10.Form.Internal.FieldConf.ValidationSpecs -> R10.Form.Internal.State.State -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperValidateCreatingFieldsState key maybeValidationSpec formState maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    Just <| R10.Form.Internal.Validation.validate key maybeValidationSpec formState fieldState


helperValidateWithoutCreatingFieldsState : Maybe R10.Form.Internal.FieldConf.ValidationSpecs -> R10.Form.Internal.State.State -> R10.Form.Internal.Key.Key -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperValidateWithoutCreatingFieldsState maybeValidationSpec formState key maybeFieldState =
    Maybe.map (R10.Form.Internal.Validation.validate key maybeValidationSpec formState) maybeFieldState


helperValidateOnChangeValue : R10.Form.Internal.Key.Key -> Maybe R10.Form.Internal.FieldConf.ValidationSpecs -> QtySubmitAttempted -> R10.Form.Internal.State.State -> Maybe R10.Form.Internal.FieldState.FieldState -> Maybe R10.Form.Internal.FieldState.FieldState
helperValidateOnChangeValue key maybeValidationSpec qtySubmitAttempted formState maybeFieldState =
    let
        fieldState : R10.Form.Internal.FieldState.FieldState
        fieldState =
            stateWithDefault maybeFieldState
    in
    if fieldState.lostFocusOneOrMoreTime || QtySubmitAttempted.toInt qtySubmitAttempted > 0 then
        helperValidateCreatingFieldsState key maybeValidationSpec formState maybeFieldState

    else
        maybeFieldState



--
-- OTHER HELPERS
--


allValidationKeysMaker : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> List R10.Form.Internal.MakerForValidationKeys.Outcome
allValidationKeysMaker conf state =
    R10.Form.Internal.MakerForValidationKeys.maker R10.Form.Internal.Key.empty state conf


runAllValidations :
    List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
    -> R10.Form.Internal.State.State
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
runAllValidations allKeys formState fieldsState =
    -- Validate the entire form, creating new `fieldState` if necessary,
    -- when such fields were not yet touched, for example
    List.foldl
        (\( key, validationSpec ) acc ->
            R10.Form.Internal.Dict.update key (helperValidateCreatingFieldsState key validationSpec formState) acc
        )
        fieldsState
        allKeys


runOnlyExistingValidations :
    List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
    -> R10.Form.Internal.State.State
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
runOnlyExistingValidations allKeys formState fieldsState =
    -- Validate the entire form, without creating new `fieldState`
    List.foldl
        (\( key, fieldConf ) acc ->
            R10.Form.Internal.Dict.update key (helperValidateWithoutCreatingFieldsState fieldConf formState key) acc
        )
        fieldsState
        allKeys


entitiesWithErrors :
    List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
    -> List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
entitiesWithErrors allKeys fieldsState =
    -- Return the list of field that either didn't pass
    -- the validation or were not validated. Used to understand if a form has been
    -- filled properly and show a comprehensive error at the bottom.
    -- If a field has not yet been validated, it is considered as an error.
    -- So this function require all validations to be run before being called.
    List.filter
        (\( key, _ ) ->
            let
                fieldState : R10.Form.Internal.FieldState.FieldState
                fieldState =
                    Maybe.withDefault R10.Form.Internal.FieldState.init <| R10.Form.Internal.Dict.get key fieldsState
            in
            case R10.Form.Internal.FieldState.isValid fieldState.validation of
                R10.Form.Internal.FieldState.NotYetValidated2 ->
                    True

                R10.Form.Internal.FieldState.NotValid ->
                    True

                R10.Form.Internal.FieldState.Valid ->
                    False
        )
        allKeys


entitiesWithErrorsForOnlyExistingValidations :
    List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
    -> Dict.Dict String R10.Form.Internal.FieldState.FieldState
    -> List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
entitiesWithErrorsForOnlyExistingValidations allKeys fieldsState =
    List.filter
        (\( key, _ ) ->
            let
                fieldState : R10.Form.Internal.FieldState.FieldState
                fieldState =
                    Maybe.withDefault R10.Form.Internal.FieldState.init <| R10.Form.Internal.Dict.get key fieldsState
            in
            case R10.Form.Internal.FieldState.isValid fieldState.validation of
                R10.Form.Internal.FieldState.NotYetValidated2 ->
                    False

                R10.Form.Internal.FieldState.NotValid ->
                    True

                R10.Form.Internal.FieldState.Valid ->
                    False
        )
        allKeys


allErrorsForView : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
allErrorsForView conf state =
    if shouldShowTheValidationOverview state then
        let
            allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
            allKeys =
                allValidationKeysMaker conf state
        in
        entitiesWithErrors allKeys state.fieldsState

    else
        []


shouldShowTheValidationOverview : R10.Form.Internal.State.State -> Bool
shouldShowTheValidationOverview formState =
    QtySubmitAttempted.toInt formState.qtySubmitAttempted > 0 && not formState.changesSinceLastSubmissions


submittable : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> Bool
submittable conf state =
    if QtySubmitAttempted.toInt state.qtySubmitAttempted == 0 then
        -- Always submittable if it has never been submitted
        True

    else
        isEntireFormValid conf state


isFormSubmittableAndSubmitted : R10.Form.Internal.Conf.Conf -> R10.Form.Internal.State.State -> R10.Form.Msg.Msg -> Bool
isFormSubmittableAndSubmitted conf state formMsg =
    submittable conf state && R10.Form.Msg.isSubmitted formMsg



-- ███████ ██    ██ ██████  ███    ███ ██ ████████     ███████  ██████  ██████  ███    ███
-- ██      ██    ██ ██   ██ ████  ████ ██    ██        ██      ██    ██ ██   ██ ████  ████
-- ███████ ██    ██ ██████  ██ ████ ██ ██    ██        █████   ██    ██ ██████  ██ ████ ██
--      ██ ██    ██ ██   ██ ██  ██  ██ ██    ██        ██      ██    ██ ██   ██ ██  ██  ██
-- ███████  ██████  ██████  ██      ██ ██    ██        ██       ██████  ██   ██ ██      ██


submit :
    R10.Form.Internal.Conf.Conf
    -> R10.Form.Internal.State.State
    -> R10.Form.Internal.State.State
submit conf state =
    let
        newFieldsState : R10.Form.Internal.State.State
        newFieldsState =
            validateEntireForm conf state

        newQtySubmitAttempted : QtySubmitAttempted
        newQtySubmitAttempted =
            QtySubmitAttempted.increment state.qtySubmitAttempted
    in
    { newFieldsState | qtySubmitAttempted = newQtySubmitAttempted }



-- ██    ██ ██████  ██████   █████  ████████ ███████
-- ██    ██ ██   ██ ██   ██ ██   ██    ██    ██
-- ██    ██ ██████  ██   ██ ███████    ██    █████
-- ██    ██ ██      ██   ██ ██   ██    ██    ██
--  ██████  ██      ██████  ██   ██    ██    ███████


onGetFocus : R10.Form.Internal.Key.Key -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onGetFocus key formState =
    { formState
        | focused = Just (R10.Form.Internal.Key.toString key)
    }


onLoseFocus : R10.Form.Internal.Key.Key -> R10.Form.Internal.FieldConf.FieldConf -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onLoseFocus key fieldConf formState =
    { formState
        | focused = Nothing
        , fieldsState =
            formState.fieldsState
                |> R10.Form.Internal.Dict.update key helperLostFocus
                |> R10.Form.Internal.Dict.update key (helperValidateCreatingFieldsState key fieldConf.validationSpecs formState)
    }


onDeactivate : R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onDeactivate formState =
    { formState | active = Nothing }


onActivate : R10.Form.Internal.Key.Key -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onActivate key formState =
    { formState
        | active = Just (R10.Form.Internal.Key.toString key)
    }


onScroll : R10.Form.Internal.Key.Key -> Float -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onScroll key scroll formState =
    { formState | fieldsState = formState.fieldsState |> R10.Form.Internal.Dict.update key (helperUpdateScroll scroll) }


onChangeValue : R10.Form.Internal.Key.Key -> R10.Form.Internal.FieldConf.FieldConf -> R10.Form.Internal.Conf.Conf -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onChangeValue key fieldConf formConf string formState =
    let
        newState : R10.Form.Internal.State.State
        newState =
            { formState
                | focused = Just (R10.Form.Internal.Key.toString key)
                , fieldsState =
                    formState.fieldsState
                        |> R10.Form.Internal.Dict.update key (helperUpdateValue string)
                        |> R10.Form.Internal.Dict.update key helperUpdateDirty
                        |> R10.Form.Internal.Dict.update key (helperValidateOnChangeValue key fieldConf.validationSpecs formState.qtySubmitAttempted formState)
            }

        allKeys : List ( R10.Form.Internal.Key.Key, Maybe R10.Form.Internal.FieldConf.ValidationSpecs )
        allKeys =
            allValidationKeysMaker formConf newState
    in
    { newState
        | fieldsState =
            runOnlyExistingValidations allKeys newState newState.fieldsState
    }


onChangeSearch : R10.Form.Internal.Key.Key -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onChangeSearch key string formState =
    { formState | fieldsState = formState.fieldsState |> R10.Form.Internal.Dict.update key (helperUpdateSearch string) }


onChangeSelect : R10.Form.Internal.Key.Key -> String -> R10.Form.Internal.State.State -> R10.Form.Internal.State.State
onChangeSelect key string formState =
    { formState | fieldsState = formState.fieldsState |> R10.Form.Internal.Dict.update key (helperUpdateSelect string) }


update : R10.Form.Msg.Msg -> R10.Form.Internal.State.State -> ( R10.Form.Internal.State.State, Cmd R10.Form.Msg.Msg )
update msg formStateBeforeHandleChangesSinceLastSubmissions =
    let
        formState : R10.Form.Internal.State.State
        formState =
            { formStateBeforeHandleChangesSinceLastSubmissions
                | changesSinceLastSubmissions =
                    R10.Form.Msg.handleChangesSinceLastSubmissions
                        formStateBeforeHandleChangesSinceLastSubmissions.changesSinceLastSubmissions
                        msg
            }
    in
    case msg of
        R10.Form.Msg.NoOp ->
            ( formState, Cmd.none )

        R10.Form.Msg.Submit formConf ->
            ( submit formConf formState, Cmd.none )

        R10.Form.Msg.GetFocus key ->
            ( onGetFocus key formState
            , Cmd.none
            )

        R10.Form.Msg.LoseFocus key fieldConf ->
            ( onLoseFocus key fieldConf formState
            , Cmd.none
            )

        R10.Form.Msg.TogglePasswordShow key ->
            ( { formState
                | fieldsState =
                    formState.fieldsState
                        |> R10.Form.Internal.Dict.update key helperToggleShowPassword
              }
            , Cmd.none
            )

        R10.Form.Msg.ChangeTab key string ->
            ( { formState
                | activeTabs =
                    formState.activeTabs
                        |> R10.Form.Internal.Dict.insert key string
              }
            , Cmd.none
            )

        R10.Form.Msg.AddEntity key ->
            let
                presentQuantity : Int
                presentQuantity =
                    Maybe.withDefault 1 <| R10.Form.Internal.Dict.get key formState.multiplicableQuantities
            in
            ( { formState
                | multiplicableQuantities =
                    formState.multiplicableQuantities
                        |> R10.Form.Internal.Dict.insert key (presentQuantity + 1)
              }
            , Cmd.none
            )

        R10.Form.Msg.RemoveEntity key ->
            ( { formState
                | removed =
                    formState.removed
                        |> Set.insert (R10.Form.Internal.Key.toString key)
              }
            , Cmd.none
            )

        R10.Form.Msg.ChangeValue key fieldConf formConf string ->
            ( onChangeValue key fieldConf formConf string formState, Cmd.none )

        R10.Form.Msg.OnSingleMsg key fieldConf formConf singleMsg ->
            let
                fieldState : R10.Form.Internal.FieldState.FieldState
                fieldState =
                    R10.Form.Internal.Dict.get key formState.fieldsState
                        |> stateWithDefault

                singleModel : R10.FormComponents.Single.Common.Model
                singleModel =
                    { value = fieldState.value
                    , search = fieldState.search
                    , select = fieldState.select
                    , scroll = fieldState.scroll
                    , focused = formState.focused == Just (R10.Form.Internal.Key.toString key)
                    , opened = formState.active == Just (R10.Form.Internal.Key.toString key)
                    }

                ( newSingleModel, singleCmd ) =
                    R10.FormComponents.Single.Update.update singleMsg singleModel

                newFormState : R10.Form.Internal.State.State
                newFormState =
                    formState
                        |> (if fieldState.value /= newSingleModel.value then
                                onChangeValue key fieldConf formConf newSingleModel.value

                            else
                                identity
                           )
                        |> (if fieldState.search /= newSingleModel.search then
                                onChangeSearch key newSingleModel.search

                            else
                                identity
                           )
                        |> (if fieldState.select /= newSingleModel.select then
                                onChangeSelect key newSingleModel.select

                            else
                                identity
                           )
                        |> (if fieldState.scroll /= newSingleModel.scroll then
                                onScroll key newSingleModel.scroll

                            else
                                identity
                           )
                        |> (if singleModel.focused /= newSingleModel.focused then
                                if newSingleModel.focused then
                                    onGetFocus key

                                else
                                    onLoseFocus key fieldConf

                            else
                                identity
                           )
                        |> (if singleModel.opened /= newSingleModel.opened then
                                if newSingleModel.opened then
                                    onActivate key

                                else
                                    onDeactivate

                            else
                                identity
                           )
            in
            ( newFormState
            , Cmd.map (R10.Form.Msg.OnSingleMsg key fieldConf formConf) singleCmd
            )

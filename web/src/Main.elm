module Main exposing (main)

import AjaxRequest exposing (AjaxRequest)
import Api exposing (send, withBasePath)
import Api.Data exposing (Ingredient, PotentialCocktailsJsonPayload)
import Api.Request.Default as MixologistApi
import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import IngredientCheckbox
import Msg exposing (Msg(..))
import Set exposing (Set(..))


apiBasePath : String
apiBasePath =
    "http://localhost:8080"


isChecked : Set String -> String -> Bool
isChecked checkedIngredients candaditeIngredient =
    Set.member candaditeIngredient checkedIngredients


toggleElement : comparable -> Set comparable -> Set comparable
toggleElement elementToToggle setToToggle =
    if Set.member elementToToggle setToToggle then
        Set.remove elementToToggle setToToggle

    else
        Set.insert elementToToggle setToToggle


getIngredients : Cmd Msg
getIngredients =
    send IngredientsRequestComplete (withBasePath apiBasePath MixologistApi.getIngredients)


getPotentialCocktails : PotentialCocktailsJsonPayload -> Cmd Msg
getPotentialCocktails payload =
    send PotentialCocktailsRequestComplete (withBasePath apiBasePath (MixologistApi.postPotentialIngredients payload))


type alias Model =
    { ingredientsRequest : AjaxRequest (List Ingredient)
    , checkedIngredients : Set String
    }


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { ingredientsRequest = AjaxRequest.Loading, checkedIngredients = Set.empty }, getIngredients )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PotentialCocktailsRequestComplete _ ->
            ( model, Cmd.none )

        IngredientsRequestRetry ->
            ( { ingredientsRequest = AjaxRequest.Loading, checkedIngredients = Set.empty }, getIngredients )

        IngredientsRequestComplete result ->
            case result of
                Ok ingredientsResponse ->
                    case ingredientsResponse.data of
                        Just ingredients ->
                            ( { ingredientsRequest = AjaxRequest.Success ingredients, checkedIngredients = Set.empty }, Cmd.none )

                        Nothing ->
                            ( { ingredientsRequest = AjaxRequest.Failure, checkedIngredients = Set.empty }, Cmd.none )

                Err _ ->
                    ( { ingredientsRequest = AjaxRequest.Failure, checkedIngredients = Set.empty }, Cmd.none )

        ToggleIngredient toggledIngredient ->
            ( { model | checkedIngredients = toggleElement toggledIngredient.name model.checkedIngredients }, Cmd.none )

        PotentialCocktailsRequestSubmitted ->
            ( model, getPotentialCocktails (PotentialCocktailsJsonPayload (Just (List.map Ingredient (Set.toList model.checkedIngredients)))) )


view : Model -> Html Msg
view model =
    case model.ingredientsRequest of
        AjaxRequest.Failure ->
            div []
                [ text "Failed to load ingredients"
                , button [ onClick IngredientsRequestRetry ] [ text "Try Again!" ]
                ]

        AjaxRequest.Loading ->
            text "Loading..."

        AjaxRequest.Success ingredients ->
            div []
                [ div []
                    (List.map (\i -> IngredientCheckbox.component { ingredient = i, isChecked = isChecked model.checkedIngredients i.name, onCheck = ToggleIngredient }) ingredients)
                , button
                    [ onClick PotentialCocktailsRequestSubmitted ]
                    [ text "Find Cocktails" ]
                ]

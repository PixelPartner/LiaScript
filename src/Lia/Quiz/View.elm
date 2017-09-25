module Lia.Quiz.View exposing (view)

import Array exposing (Array)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onInput)
import Lia.Inline.Types exposing (Line)
import Lia.Inline.View exposing (view_inf)
import Lia.Quiz.Model exposing (..)
import Lia.Quiz.Types exposing (..)
import Lia.Quiz.Update exposing (Msg(..))


view : Model -> Quiz -> Html Msg
view model quiz =
    let
        state =
            get_state model
    in
    case quiz of
        Text solution idx hints ->
            view_quiz (state idx) view_text idx hints (TextState solution)

        SingleChoice solution questions idx hints ->
            view_quiz (state idx) (view_single_choice questions) idx hints (SingleChoiceState solution)

        MultipleChoice solution questions idx hints ->
            view_quiz (state idx) (view_multiple_choice questions) idx hints (MultipleChoiceState solution)


view_quiz : Maybe QuizElement -> (Int -> QuizState -> Bool -> Html Msg) -> Int -> List Line -> QuizState -> Html Msg
view_quiz state fn_view idx hints solution =
    case state of
        Just s ->
            Html.p [ Attr.class "lia-quiz" ]
                (fn_view idx s.state s.solved
                    :: view_button s.trial s.solved (Check idx solution)
                    :: view_hints idx s.hints hints
                )

        Nothing ->
            Html.text ""


view_button : Int -> Bool -> Msg -> Html Msg
view_button trials solved msg =
    if solved then
        Html.button
            [ Attr.class "lia-btn", Attr.class "lia-success" ]
            [ Html.text ("Check " ++ toString trials) ]
    else if trials == 0 then
        Html.button [ Attr.class "lia-btn", onClick msg ] [ Html.text "Check" ]
    else
        Html.button
            [ Attr.class "lia-btn", Attr.class "lia-failure", onClick msg ]
            [ Html.text ("Check " ++ toString trials) ]


view_text : Int -> QuizState -> Bool -> Html Msg
view_text idx state solved =
    case state of
        TextState x ->
            Html.input
                [ Attr.type_ "input"
                , Attr.class "lia-input"
                , Attr.value x
                , Attr.disabled solved
                , onInput (Input idx)
                ]
                []

        _ ->
            Html.text ""


view_single_choice : List Line -> Int -> QuizState -> Bool -> Html Msg
view_single_choice questions idx state solved =
    case state of
        SingleChoiceState x ->
            questions
                |> List.indexedMap (,)
                |> List.map
                    (\( i, elements ) ->
                        Html.p [ Attr.class "lia-radio-item" ]
                            [ Html.input
                                [ Attr.type_ "radio"
                                , Attr.checked (i == x)
                                , if solved then
                                    Attr.disabled True
                                  else
                                    onClick (RadioButton idx i)
                                ]
                                []
                            , Html.span [ Attr.class "lia-radio-btn" ] []
                            , Html.span [ Attr.class "lia-label" ] (List.map view_inf elements)
                            ]
                    )
                |> Html.div []

        _ ->
            Html.text ""


view_multiple_choice : List Line -> Int -> QuizState -> Bool -> Html Msg
view_multiple_choice questions idx state solved =
    let
        fn b ( i, line ) =
            Html.p [ Attr.class "lia-check-item" ]
                [ Html.input
                    [ Attr.type_ "checkbox"
                    , Attr.checked b
                    , if solved then
                        Attr.disabled True
                      else
                        onClick (RadioButton idx i)
                    ]
                    []
                , Html.span [ Attr.class "lia-check-btn" ] [ Html.text "check" ]
                , Html.span [ Attr.class "lia-label" ] (List.map view_inf line)
                ]
    in
    case state of
        MultipleChoiceState x ->
            questions
                |> List.indexedMap (,)
                |> List.map2 fn (Array.toList x)
                |> Html.div []

        _ ->
            Html.text ""


view_hints : Int -> Int -> List Line -> List (Html Msg)
view_hints idx counter hints =
    let
        v_hints h c =
            case ( h, c ) of
                ( [], _ ) ->
                    []

                ( _, 0 ) ->
                    []

                ( x :: xs, _ ) ->
                    Html.p []
                        (Html.span [ Attr.class "lia-icon" ] [ Html.text "lightbulb_outline" ]
                            :: List.map view_inf x
                        )
                        :: v_hints xs (c - 1)
    in
    if counter < List.length hints then
        [ Html.text " "
        , Html.a [ Attr.class "lia-hint-btn", Attr.href "#", onClick (ShowHint idx) ] [ Html.text "live_help" ]
        , Html.div
            [ Attr.class "lia-hints"
            ]
            (v_hints hints counter)
        ]
    else
        [ Html.div
            [ Attr.class "lia-hints"
            ]
            (v_hints hints counter)
        ]

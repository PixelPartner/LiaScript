module Lia.Parser.State exposing
    ( State
    , ident_skip
    , identation
    , identation_append
    , identation_pop
    , init
    , searchIndex
    )

import Array
import Combine exposing (Parser, ignore, lazy, modifyState, regex, skip, succeed, withState)
import Lia.Definition.Types exposing (Definition)
import Lia.Markdown.Code.Types as Code
import Lia.Markdown.Effect.Model as Effect
import Lia.Markdown.Footnote.Model as Footnote
import Lia.Markdown.Quiz.Types as Quiz
import Lia.Markdown.Survey.Types as Survey


type alias State =
    { identation : List String
    , identation_skip : Bool
    , code_vector : Code.Vector
    , quiz_vector : Quiz.Vector
    , survey_vector : Survey.Vector
    , effect_model : Effect.Model
    , effect_number : List Int
    , defines : Definition
    , footnotes : Footnote.Model
    , defines_updated : Bool
    , search_index : String -> String
    }


init : (String -> String) -> Definition -> State
init search_index global =
    { identation = []
    , identation_skip = False
    , code_vector = Array.empty
    , quiz_vector = Array.empty
    , survey_vector = Array.empty
    , effect_model = Effect.init
    , effect_number = [ 0 ]
    , defines = global
    , footnotes = Footnote.init
    , defines_updated = False
    , search_index = search_index
    }


searchIndex : Parser State (String -> String)
searchIndex =
    withState (\state -> state.search_index |> succeed)


par_ : State -> Parser State ()
par_ s =
    if s.identation == [] then
        succeed ()

    else if s.identation_skip then
        skip (succeed ())

    else
        String.concat s.identation
            |> regex
            |> skip


identation : Parser State ()
identation =
    withState par_
        |> ignore (modifyState (skip_ False))


identation_append : String -> Parser State ()
identation_append str =
    modifyState
        (\state ->
            { state
                | identation_skip = True
                , identation = List.append state.identation [ str ]
            }
        )


identation_pop : Parser State ()
identation_pop =
    modifyState
        (\state ->
            { state
                | identation_skip = False
                , identation =
                    state.identation
                        |> List.reverse
                        |> List.drop 1
                        |> List.reverse
            }
        )


ident_skip : Parser State ()
ident_skip =
    modifyState (skip_ True)


skip_ : Bool -> State -> State
skip_ bool state =
    { state | identation_skip = bool }

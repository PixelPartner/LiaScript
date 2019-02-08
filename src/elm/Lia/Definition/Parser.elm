module Lia.Definition.Parser exposing (parse)

import Combine
    exposing
        ( Parser
        , andMap
        , andThen
        , choice
        , ignore
        , keep
        , lazy
        , many1
        , map
        , maybe
        , modifyState
        , regex
        , skip
        , string
        , whitespace
        )
import Lia.Definition.Types exposing (Definition, Resource(..), add_imports, add_translation, toURL)
import Lia.Markdown.Inline.Parser exposing (comment)
import Lia.Markdown.Macro.Parser as Macro
import Lia.Parser.Helper exposing (newline, stringTill)
import Lia.Parser.State
    exposing
        ( State
        , ident_skip
        , identation
        , identation_append
        , identation_pop
        )


parse : Parser State ()
parse =
    lazy <|
        \() ->
            definition
                |> keep (modifyState (\s -> { s | defines_updated = True }))
                |> maybe
                |> ignore whitespace
                |> skip


definition : Parser State ()
definition =
    lazy <|
        \() ->
            let
                list =
                    choice
                        [ store "author:" (\x d -> { d | author = x })
                        , store "base:" (\x d -> { d | base = x })
                        , store "comment:" (\x d -> { d | comment = String.replace "\n" " " x })
                        , store "date:" (\x d -> { d | date = x })
                        , store "email:" (\x d -> { d | email = x })
                        , store "language:" (\x d -> { d | language = x })
                        , store "logo:" (\x d -> { d | logo = x })
                        , store "narrator:" (\x d -> { d | narrator = x })
                        , store "script:" (addToResources Script)
                        , store "import:" add_imports
                        , store "link:" (addToResources Link)
                        , store "translation:" add_translation
                        , store "version:" (\x d -> { d | version = x })
                        , store "debug:"
                            (\x d ->
                                { d
                                    | debug =
                                        if x == "true" then
                                            True

                                        else
                                            False
                                }
                            )
                        , regex "@onload[\t ]*\\n"
                            |> keep (stringTill (string "\n@end"))
                            |> andThen (\x -> set (\def -> { def | onload = String.trim x }))
                        , Macro.pattern
                            |> ignore (regex "[\t ]*:[\t ]*")
                            |> map Tuple.pair
                            |> andMap (regex ".+")
                            |> ignore newline
                            |> andThen (\x -> set (Macro.add x))
                        , Macro.pattern
                            |> ignore (regex "[\t ]*\\n")
                            |> map Tuple.pair
                            |> andMap (stringTill (string "\n@end"))
                            |> andThen (\x -> set (Macro.add x))
                        ]
            in
            (whitespace |> keep list)
                |> many1
                |> ignore whitespace
                |> comment
                |> skip


store : String -> (String -> Definition -> Definition) -> Parser State ()
store str fn =
    string str |> keep (ending |> andThen (fn >> set))


ending : Parser State String
ending =
    identation_append "  "
        |> ignore ident_skip
        |> keep (many1 (identation |> keep (regex ".+\\n")))
        |> ignore identation_pop
        |> map (\list -> list |> List.map String.trimLeft |> String.concat |> String.trimRight)


set : (Definition -> Definition) -> Parser State ()
set fct =
    modifyState (\s -> { s | defines = fct s.defines })


append : (String -> a) -> String -> String -> List a -> List a
append to base urls list =
    urls
        |> String.split "\n"
        |> List.map (toURL base >> to)
        |> List.append list


addToResources : (String -> Resource) -> String -> Definition -> Definition
addToResources to urls def =
    { def | resources = append to def.base urls def.resources }

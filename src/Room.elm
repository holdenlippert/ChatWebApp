module Room exposing (Room, newRoom, addMessage, addMessages, decodeRoom)

import Json.Decode exposing (Decoder, field, string)

type alias Room = 
        { name: String
        , messages: List String
        , members: List String
        , draftMessage: String
        }

newRoom : String -> Room
newRoom name = Room name [] [] ""

addMessage : String -> Room -> Room
addMessage newMsg room = { room | messages = room.messages ++ [newMsg] }

addMessages : List String -> Room -> Room
addMessages messages room = List.foldl addMessage room messages

decodeRoom : Decoder Room
decodeRoom =
        Json.Decode.map4
                Room
                (field "name" string)
                (field "messages" (Json.Decode.list Json.Decode.string))
                (field "users" (Json.Decode.list Json.Decode.string))
                (Json.Decode.succeed "")

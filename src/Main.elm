module Main exposing (main)

import Room
import Browser
import Html exposing (..)
import Html.Events as Events
import Html.Attributes as Attributes
import Http
import Json.Decode exposing (list)
import Json.Encode exposing (string)
import Maybe


-- Simple utilities to build a url pointed at the backend url.
base_url : String
base_url = "http://localhost:8000"
url : List String -> String
url components = String.concat (base_url :: components)


main = Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = (\x -> Sub.none)
        }


type alias Model = 
        { rooms: List Room.Room
        , openRoom: Maybe Int -- the index of the currently open room
        , connections: List String
        , draftRoomName: String
        , draftIP: String
        , selectedConnection: Maybe String
        }


-- On startup, load the rooms and connections from the backend.
init : () -> (Model, Cmd Msg)
init _ = 
        ( Model [] Nothing [] "" "" Nothing
        , Cmd.batch
                [ Http.get
                        { url = url ["/rooms"]
                        , expect = Http.expectJson GotRooms (Json.Decode.list Room.decodeRoom)
                        }
                , Http.get
                        { url =  url ["/users"]
                        , expect = Http.expectJson GotUsers (Json.Decode.list Json.Decode.string)
                        }
                ]
        )


-- Helper method, basically just gets element model.openRoom from model.rooms.
-- The fact that Elm doesn't provide random access to a list makes me feel like
-- there's a better way to structure this.
getOpenRoom : Model -> Maybe Room.Room
getOpenRoom model =
        let getOpenRoomHelper roomlist idx = case roomlist of
                    (x :: xs) -> if idx == 0 then Just x else getOpenRoomHelper xs (idx - 1)
                    [] -> Nothing
        in
                Maybe.andThen (getOpenRoomHelper model.rooms) model.openRoom



type Msg = 
        -- Interaction bookkeeping events:
        UpdateDraft String
        | UpdateDraftIP String
        | UpdateDraftRoomName String
        | SelectConnection String
        -- User action events:
        | ClickRoom Int
        | SendMessage
        | CreateRoom
        | ConnectIP
        | LeaveRoom Int
        | SendInvite Int
        -- Server response events:
        | GotRooms (Result Http.Error (List Room.Room))
        | GotUsers (Result Http.Error (List String))


update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
        -- Interaction bookkeeping events:
        UpdateDraft draft ->
                let 
                        updateRoom idx roomTarget =
                                if 
                                        Just idx == model.openRoom
                                then
                                        { roomTarget | draftMessage = draft }
                                else
                                        roomTarget
                in
                        ({ model | rooms = List.indexedMap updateRoom model.rooms }
                        , Cmd.none
                        )
        UpdateDraftIP draft -> 
                ({ model | draftIP = draft }
                , Cmd.none
                )
        UpdateDraftRoomName draft ->
                ({ model | draftRoomName = draft }
                , Cmd.none
                )
        SelectConnection conn ->
                ({ model | selectedConnection = Just conn }
                , Cmd.none
                )
        -- User action events:
        ClickRoom room -> 
                ({ model | openRoom = if model.openRoom == Just room then Nothing else Just room }
                , Cmd.none
                )
        SendMessage ->
                case (model.openRoom, getOpenRoom model) of
                        (Just idx, Just room) ->
                                ( model
                                , Http.post
                                        { url = url ["/message/", String.fromInt idx]
                                        , body = Http.stringBody "text/plain" room.draftMessage
                                        , expect = Http.expectJson GotRooms (Json.Decode.list Room.decodeRoom)
                                        }
                                )
                        _ -> 
                                (model, Cmd.none)
        CreateRoom ->
                ({ model | draftRoomName = "" }
                , Http.post
                        { url = url ["/rooms/", model.draftRoomName]
                        , body = Http.emptyBody
                        , expect = Http.expectJson GotRooms (Json.Decode.list Room.decodeRoom)
                        }
                )
        ConnectIP ->
                ({ model | draftIP = "" }
                , Http.post
                        { url = url ["/users/", model.draftIP]
                        , body = Http.emptyBody
                        , expect = Http.expectJson GotUsers (Json.Decode.list Json.Decode.string)
                        }
                )
        LeaveRoom idx -> 
                ({ model | openRoom = Nothing }
                , Http.post
                        { url = url ["/rooms/", String.fromInt idx, "/leave"]
                        , body = Http.emptyBody
                        , expect = Http.expectJson GotRooms (Json.Decode.list Room.decodeRoom)
                        }
                )
        SendInvite idx ->
                case model.selectedConnection of
                        Just conn ->
                                ( model
                                , Http.post
                                        { url = url ["/invite/", String.fromInt idx, "/", conn]
                                        , body = Http.emptyBody
                                        , expect = Http.expectJson GotRooms (Json.Decode.list Room.decodeRoom)
                                        }
                                )
                        Nothing ->
                                ( model, Cmd.none )
        -- Server response events:
        GotRooms result -> case result of
                Ok newRooms -> ({ model | rooms = newRooms }, Cmd.none )
                Err _ -> (model, Cmd.none)
        GotUsers result -> case result of
                Ok newUsers ->
                        ({ model | connections = newUsers
                                 , selectedConnection = 
                                         if 
                                                 Maybe.map (\x -> List.member x newUsers) model.selectedConnection == Just True
                                         then 
                                                 model.selectedConnection
                                         else
                                                 Nothing
                         }
                        , Cmd.none
                        )
                Err _ ->
                        (model, Cmd.none)




view : Model -> Html Msg
view model = div [] 
        [ div []
                [ text "Connect to an IP:"
                , input [Attributes.type_ "text", Attributes.placeholder "IP Address...", Events.onInput UpdateDraftIP] []
                , button [Events.onClick ConnectIP] [text "Connect"]
                ]
        , div []
                [ text "Connected users:"
                , select
                        [Events.onInput SelectConnection]
                        (List.map
                                (\c -> option [Attributes.value c] [text c])
                                model.connections)
                ]
        , ul [Attributes.class "nav nav-tabs"]
                ((List.indexedMap
                        (\idx room ->
                                let 
                                        class = if Just idx == model.openRoom then "nav-link active" else "nav-link"
                                in 
                                        li [Attributes.class "nav-item"] [a [Attributes.class class, Attributes.href "#", Events.onClick (ClickRoom idx)] [text room.name]])
                        model.rooms
                ) 
                ++ [li [Attributes.class "nav-item dropdown"]
                        [ a [Attributes.class "nav-link", Attributes.attribute "data-toggle" "dropdown", Attributes.attribute "role" "button", Attributes.href "#"] [text "+"]
                        , div [Attributes.class "dropdown-menu"]
                                [span [] [input [Attributes.type_ "text", Events.onInput UpdateDraftRoomName, Attributes.value model.draftRoomName, Attributes.placeholder "New room..."] []
                                          , button [Events.onClick CreateRoom] [text "+"]]]
                        ]
                   ]
                )

        , case (model.openRoom, getOpenRoom model) of
                (Just idx, Just room) -> div [] [showOpenRoom idx room]
                _ -> text ""
        ]


showOpenRoom : Int -> Room.Room -> Html Msg
showOpenRoom idx room =
         div [Attributes.class "room"]
                 [ h2 [] [text room.name]
                 , button [Attributes.type_ "button", Events.onClick (SendInvite idx)] [text "Invite"]
                 , button [Events.onClick (LeaveRoom idx)] [text "Leave"]
                 , div [Attributes.class "roomInfo"]
                        [ pre [Attributes.class "chat"] (List.map (p [] << List.singleton << text) room.messages)
                        , div [Attributes.class "members"] 
                                [ h6 [] [text "Members"]
                                , div [Attributes.class "membersList"] (List.map (p [] << List.singleton << text) room.members)
                                ]
                        ]
                 , form [Events.onSubmit SendMessage]
                        [ input [ Attributes.class "draftMsg", Attributes.type_ "text", Events.onInput UpdateDraft, Attributes.value room.draftMessage, Attributes.placeholder "Send a message..."] []
                        , button [] [text "Send"]
                        ]
                 ]

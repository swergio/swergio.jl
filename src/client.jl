module ClientModule 
using Sockets
using JSON
using UUIDs
import ..messagetype: MESSAGE_TYPE, by_id

reserved_rooms = ["_command"]#,'_logging']


"""
A client, which can be used to connect to a server and send and
receive messages.

:param client: TCPSocket to connect the client to the server.
:param name: The name of the client.
:param server: The IP address of the server.
:param port: The port number of the server.
:param header_length: The length of the message header in bytes.
:param eventHandlers: A set of `EventHandler` instances registered with this client.
:param rooms: A set of rooms that the client has joined.
:param kwargs: Additional keyword arguments that will be passed to event handler
        functions when they are called.
"""
mutable struct Client
    client
    name
    server
    port
    header_length
    eventHandlers
    rooms
    kwargs
end

"""
Function to create a client struct

:param name: The name of the client.
:param server: The IP address of the server.
:param port: The port number of the server.
:param header_length: The length of the message header in bytes.
:param kwargs: Additional keyword arguments that will be passed to event handler
        functions when they are called.
:return: The created client
"""
function Client(name,server,port; header_length = 10,kwargs...)
    client = connect(server,port)
    eventHandlers = Set()
    rooms = Set()
    self = Client(client,name, server,port,header_length,eventHandlers,rooms, kwargs)
    register(self)
    return self
end

"""
Send the given message to the server.

:param client: Used client struct.
:param message: The message to send.
"""
function send(client::Client,message)
    msg = JSON.json(message)
    l = length(Vector{UInt8}(msg))
    l_pad = rpad(string(l),client.header_length)
    write(client.client,l_pad)
    write(client.client,msg)
end

"""
Register this client with the server. This will send a REGISTER command message
to the server and join the reserved rooms.

:param client: Used client struct.
"""
function register(client::Client)
    d = Dict()
    d["ID"] = string(uuid4())
    d["TYPE"] = MESSAGE_TYPE.COMMAND.REGISTER.id
    d["NAME"] = client.name
    d["TO_ROOM"] = "_command"
    send(client,d)

    for room in reserved_rooms
        join_room(client,room)
    end
end

"""
Receive a message from the server.

:param client: Used client struct.
:return: The received message, or False if an error occurred.
"""
function receive(client::Client)
    message_header = read(client.client,client.header_length)
    message_length = parse(Int64, String(message_header))

    full_message_received = false
    message = b""
    message_length_left = message_length
    while !full_message_received
        message_recv = read(client.client,message_length_left)
        message_length_left = message_length_left - length(message_recv)
        message = vcat(message,message_recv)
        if message_length_left <= 0
            full_message_received = true
        end
    end

    return JSON.parse(String(message))
end

"""
Close the connection to the server. This will send a DISCONNECT command message
to the server and close the socket.

:param client: Used client struct.
"""
function close(client::Client)
    d = Dict()
    d["ID"] = string(uuid4())
    d["TYPE"] = MESSAGE_TYPE.COMMAND.DISCONNECT.id
    d["TO_ROOM"] = "_command"
    send(client,d)
end


"""
Add a new event handler to this client.

:param client: Used client struct.
:param handleFunction: The function to call when a message is handled by this event
                        handler. This function should take the same arguments as the
                        `handle` method of the `EventHandler` class and return a
                        response message, or None if no response is needed.
:param responseType: The type of the response message.
:param responseRooms: A list of room IDs where the response message should be sent.
                        If not specified, the response will be sent to the same room as
                        the original message.
:param responseComponent: The component ID where the response message should be sent.
:param trigger: A `Trigger` instance that specifies the criteria for triggering this
                event handler. If not specified, the event handler will never be
                triggered.
"""
function add_eventHandler(client::Client,handleFunction,responseType; responseRooms = nothing, responseComponent = nothing,trigger = nothing)

    if trigger !== nothing
        for room in trigger.rooms
            join_room(client,room)
        end
    end
    if responseRooms !== nothing
        for room in responseRooms
            join_room(client,room)
        end
    end
    push!(client.eventHandlers,EventHandler(handleFunction, responseType,responseRooms = responseRooms,responseComponent = responseComponent, trigger = trigger))

end

"""
Join the given room. This will send a JOINROOM command message to the server.

:param client: Used client struct.
:param room: The ID of the room to join.
"""
function join_room(client::Client,room)
    msg = Dict([("ID", string(uuid4())), ("TYPE", MESSAGE_TYPE.COMMAND.JOINROOM.id),("ROOM", room),("TO_ROOM","_command")])
    send(client,msg)
    push!(client.rooms,room)
end

"""
Listen for incoming messages from the server and handle them using the registered
event handlers. This method will block until the connection to the server is closed.

:param client: Used client struct.
"""
function listen(client::Client)
    while isopen(client.client)
        message = receive(client)
        if !(message == false)
            for eventHandler in client.eventHandlers
                if is_triggered(eventHandler,message)
                    responses = handle(eventHandler,message;client.kwargs...)
                    if !(responses === nothing)
                        for response in responses
                            response = add_propagated_fields(client,message,response)
                            send(client,response)
                        end
                    end
                end
            end
        else
            println("disconnected")
            break
        end 
    end
end

"""
Add the fields from the original message that should be propagated to the response
message. This includes the root ID, the model status of the original message as 
well as the name of the sender.

:param client: Used client struct.
:param message: The original message.
:param response: The response message.
:return: The updated response message.
"""
function add_propagated_fields(client::Client,message,response)
    if "ROOT_ID" in keys(message) && !("ROOT_ID" in keys(response)) 
        response["ROOT_ID"] = message["ROOT_ID"]
    end
    if "MODEL_STATUS" in keys(message) && !("MODEL_STATUS" in keys(response)) 
        response["MODEL_STATUS"] = message["MODEL_STATUS"]
    end
    if !("SENT_BY" in keys(response))
        response["SENT_BY"] = client.name
    end
    return response
end


# function filter_dict(dict_to_filter, thing_with_kwargs)
#     filtered_dict = dict_to_filter
#     return filtered_dict
# end

"""
This typ defines an event handler, which can be used to handle messages that match
certain criteria.

:param handleFunction: The function to call when a message is handled by this event
                        handler. This function should take the same arguments as the
                        `handle` method of this class and return a response message, or
                        None if no response is needed.
:param responseType: The type of the response message.
:param responseRooms: A list of room IDs where the response message should be sent. If
                        not specified, the response will be sent to the same room as the
                        original message.
:param responseComponent: The component ID where the response message should be sent.
:param trigger: A `Trigger` instance that specifies the criteria for triggering this
                event handler. If not specified, the event handler will never be
                triggered.
"""
mutable struct EventHandler
    handleFunction
    responseType
    responseRooms
    responseComponent
    trigger
end

"""
Function to create a EventHandler.

:param handleFunction: The function to call when a message is handled by this event
    handler. This function should take the same arguments as the
    `handle` method of this class and return a response message, or
    None if no response is needed.
:param responseType: The type of the response message.
:param responseRooms: A list of room IDs where the response message should be sent. If
            not specified, the response will be sent to the same room as the
            original message.
:param responseComponent: The component ID where the response message should be sent.
:param trigger: A `Trigger` instance that specifies the criteria for triggering this
    event handler. If not specified, the event handler will never be
    triggered..
:return: Created EventHandler struct.
        """
function EventHandler(handleFunction, responseType; responseRooms = nothing,responseComponent = nothing, trigger = nothing)
    if !isa(responseRooms,Array)
        responseRooms = [responseRooms]
    end
    return EventHandler(handleFunction,responseType,responseRooms,responseComponent,trigger)
end

"""
Check if this event handler is triggered by the given message.

:param eventHandler: Used EventHandler.
:param message: The message to check.
:return: True if the message matches the criteria specified for this event handler,
            False otherwise.
"""
function is_triggered(eventHandler::EventHandler,message)
    if eventHandler !== nothing
        return is_triggered(eventHandler.trigger,message)
    end
    return false
end

"""
Handle the given message by calling the `handleFunction` specified in the
constructor, and return a response message if needed.

:param eventHandler: Used EventHandler.
:param args: Positional arguments to pass to `handleFunction`.
:param kwargs: Keyword arguments to pass to `handleFunction`.
:return: A response message, or None if no response is needed.
"""
function handle(eventHandler::EventHandler,args...; kwargs...)
    response = eventHandler.handleFunction(args...; kwargs...)
    if response === nothing
        return nothing
    end
    if !("ID" in keys(response))
        response["ID"] = response_id
    end

    if !(eventHandler.responseType === nothing)
        response["TYPE"] = eventHandler.responseType.id
    end

    if !(eventHandler.responseComponent === nothing)
        response["TO"] = eventHandler.responseComponent
    end

    responses = []
    if !(eventHandler.responseRooms === nothing)
        for room in eventHandler.responseRooms
            resp = copy(response)
            resp["TO_ROOM"] = room
            push!(responses,resp)
        end
    end
    return responses
end


"""
This type defines a trigger, which can be used to check if a given message matches
certain criteria.

:param types: A list of message types that should trigger this trigger.
:param rooms: A list of room IDs that should trigger this trigger. If not specified,
                the trigger will be triggered by messages in any room.
:param directmessage: A boolean indicating whether direct messages (messages not
                        sent to a specific room) should trigger this trigger.
"""
struct Trigger
    types
    rooms
    directmessages
end

"""
Function to create a Trigger

:param types: A list of message types that should trigger this trigger.
:param rooms: A list of room IDs that should trigger this trigger. If not specified,
                the trigger will be triggered by messages in any room.
:param directmessage: A boolean indicating whether direct messages (messages not
                        sent to a specific room) should trigger this trigger.
:return: Cretated Trigger.
"""
function Trigger(types,rooms;directmessages = false)
    if !isa(types,Array)
        types = [types]
    end
    if !isa(rooms,Array)
        rooms = [rooms]
    end
    return Trigger(types,rooms,directmessages)
end

"""
Check if this trigger is triggered by the given message.

:param trigger: Used Trigger.
:param message: The message to check.
:return: True if the message matches the criteria specified for this trigger, False
            otherwise.
"""
function is_triggered(trigger::Trigger,message)
    if message["TO_ROOM"] in trigger.rooms && by_id(MESSAGE_TYPE,message["TYPE"]) in trigger.types
        return true
    end
    if trigger.directmessages &&  !("TO_ROOM" in keys(message))
        return true
    end
    return false
end

end


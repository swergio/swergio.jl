module ClientModule 
using Sockets
using JSON
using UUIDs
import ..messagetype: MESSAGE_TYPE, by_id

reserved_rooms = ["_command"]#,'_logging']

mutable struct Client
    client
    name
    server
    port
    #format
    header_length
    eventHandlers
    rooms
    kwargs
end

function Client(name,server,port; header_length = 10,kwargs...)
    client = connect(server,port)
    eventHandlers = Set()
    rooms = Set()
    self = Client(client,name, server,port,header_length,eventHandlers,rooms, kwargs)
    register(self)
    return self
end

function send(client::Client,message)
    msg = JSON.json(message)
    l = length(Vector{UInt8}(msg))
    l_pad = rpad(string(l),client.header_length) #-length(string(l)))
    write(client.client,l_pad)
    #println(msg)
    write(client.client,msg)
end

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

function receive(client::Client)
    message_header = read(client.client,client.header_length)
    #println(message_header)
    #println(length(message_header))
    message_length = parse(Int64, String(message_header))

    full_message_received = false
    message = b""
    message_length_left = message_length
    while !full_message_received
        message_recv = read(client.client,message_length_left)
        #println("RCV MSG:")
        #println(message_recv)
        message_length_left = message_length_left - length(message_recv)
        #println("MSG LEN:")
        #println(length(message_recv))
        #println("MSG LEN LEFT:")
        #println(message_length_left)
        message = vcat(message,message_recv)
        #println("MSG T LEN:")
        #println(length(message))
        if message_length_left <= 0
            full_message_received = true
        end
    end

    return JSON.parse(String(message))
end

function close(client::Client)
    d = Dict()
    d["ID"] = string(uuid4())
    d["TYPE"] = MESSAGE_TYPE.COMMAND.DISCONNECT.id
    d["TO_ROOM"] = "_command"
    send(client,d)
end

function add_eventHandler(client::Client,handleFunction,responseType; responseRooms = nothing, responseComponent = nothing,trigger = nothing)

    #if !(typeof(responseRooms) ==  Array)
    #    responseRooms = [responseRooms]
    #end

    # join trigger and response rooms
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

function join_room(client::Client,room)
    msg = Dict([("ID", string(uuid4())), ("TYPE", MESSAGE_TYPE.COMMAND.JOINROOM.id),("ROOM", room),("TO_ROOM","_command")])
    send(client,msg)
    push!(client.rooms,room)
end

function listen(client::Client)
    #@async 
    while isopen(client.client)
        message = receive(client)
        if !(message == false)
            for eventHandler in client.eventHandlers
                if is_triggered(eventHandler,message)
                    responses = handle(eventHandler,message;client.kwargs...) ### ADD FILTER KWARGS??!!
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
            #close(client)
            break
        end 
    end
end

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

function filter_dict(dict_to_filter, thing_with_kwargs)
    filtered_dict = dict_to_filter
    return filtered_dict
end

mutable struct EventHandler
    handleFunction
    responseType
    responseRooms
    responseComponent
    trigger
end

function EventHandler(handleFunction, responseType; responseRooms = nothing,responseComponent = nothing, trigger = nothing)
    if !isa(responseRooms,Array)
        responseRooms = [responseRooms]
    end
    return EventHandler(handleFunction,responseType,responseRooms,responseComponent,trigger)
end

function is_triggered(eventHandler::EventHandler,message)
    if eventHandler !== nothing
        return is_triggered(eventHandler.trigger,message)
    end
    return false
end

#### HOW ARGS AND KWARGS
function handle(eventHandler::EventHandler,args...; kwargs...)
    #response_id = string(uuid4())
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


struct Trigger
    types
    rooms
    directmessages
end

function Trigger(types,rooms;directmessages = false)
    if !isa(types,Array)
        types = [types]
    end
    if !isa(rooms,Array)
        rooms = [rooms]
    end
    return Trigger(types,rooms,directmessages)
end

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


"""
Module containing message type definitions.

Exported constant settings:
    - **DATA** containing the possible settings for a DATA message
    - **COMMAND** containing the possible settings for a COMMAND message
    - **LOG** containing the possible settings for a LOG message
    - **MESSAGE_TYPE** containing the possible settings for a all message types
"""
module messagetype

"""
This type represents a setting for a message type.

:param id: The unique identifier for the message type setting.
:param name: The name of the message type setting.
:param required_fields: A list of field names that are required for a message of this type.
:param optional_fields: A list of field names that are optional for a message of this type.
"""
struct MessageTypeSetting
    id::String
    name::String
    required_fields
    optional_fields
end

"""
Checks if the given message content contains all of the required fields for this message type.

:param cls: A MessageTypeSetting.
:param msg_content: A dictionary containing the fields and values for the message.
:return: True if the message content contains all of the required fields, False otherwise.
:rtype: bool
"""
function check_fields(cls::MessageTypeSetting,msg_content::Dict)
    for field in cls.required_fields
        if !(field in keys(msg_content))
            return false
        end
    end
    return true
end


"""
Abstract type to define a set of MessageTypeSettings.
"""
abstract type MessageMainType end

"""
Returns the message type setting with the given id from the given class, or None if no such setting exists.

:param cls: A MessageMainType.
:param id: The unique identifier of the message type setting to return.
:param cls: The class to search for the message type setting.
:return: The message type setting with the given id, or None if no such setting exists.
:rtype: MessageTypeSetting or None
"""
function by_id(cls::MessageMainType,id::String)
    FieldsInStruct=fieldnames(typeof(cls));
	for i=1:length(FieldsInStruct)
		Value=getfield(cls, FieldsInStruct[i])
		if Value.id==id
            return Value
        end
	end
    return Nothing
end

"""
The type to define the possible settings for a DATA message.

:param FORWARD: MessageTypeSetting for forward messages.
:param GRADIENT: MessageTypeSetting for gradient messages.
:param REWARD: MessageTypeSetting for reward messages.
:param TEXT: MessageTypeSetting for text messages.
:param CUSTOM: MessageTypeSetting for custom messages.
"""
struct data_struct <: MessageMainType
    FORWARD::MessageTypeSetting
    GRADIENT::MessageTypeSetting
    REWARD::MessageTypeSetting
    TEXT::MessageTypeSetting
    CUSTOM::MessageTypeSetting
end

"""
This type contains the possible settings for a DATA message.
"""
DATA = data_struct(
    MessageTypeSetting("DATA/FORWARD","FORWARD",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/GRADIENT","GRADIENT",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/REWARD","REWARD",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/TEXT","TEXT",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/CUSTOM","CUSTOM",[],[])
)

"""
The type to define the possible settings for a COMMAND message.

:param REGISTER: MessageTypeSetting for regsiter messages.
:param DISCONNECT: MessageTypeSetting for disconnect messages.
:param JOINROOM: MessageTypeSetting for join room messages.
:param LEAVEROOM: MessageTypeSetting for leave room messages.
:param ENABLELOGGING: MessageTypeSetting for messages to enable logging.
:param DISABLELOGGING: MessageTypeSetting for messages to disable logging.
:param SAVEMODELWEIGHTS: MessageTypeSetting for messages to save model weights.
:param LOADMODELWEIGHTS: MessageTypeSetting for messages to load model weights.
:param SAVESETTINGS: MessageTypeSetting for save settings messages.
:param LOADSETTINGS: MessageTypeSetting for load settings messages.
:param CUSTOM: MessageTypeSetting for custom messages.
"""
struct command_struct <: MessageMainType
    REGISTER::MessageTypeSetting
    DISCONNECT::MessageTypeSetting
    JOINROOM::MessageTypeSetting
    LEAVEROOM::MessageTypeSetting
    ENABLELOGGING::MessageTypeSetting
    DISABLELOGGING::MessageTypeSetting
    SAVEMODELWEIGHTS::MessageTypeSetting
    LOADMODELWEIGHTS::MessageTypeSetting
    SAVESETTINGS::MessageTypeSetting
    LOADSETTINGS::MessageTypeSetting
    CUSTOM::MessageTypeSetting
end

"""
This type contains the possible settings for a COMMAND message.
"""
COMMAND = command_struct(
    MessageTypeSetting("COMMAND/REGISTER","REGISTER",["NAME"],[]),
    MessageTypeSetting("COMMAND/DISCONNECT","DISCONNECT",[],[]),
    MessageTypeSetting("COMMAND/JOINROOM","JOINROOM",["ROOM"],[]),
    MessageTypeSetting("COMMAND/LEAVEROOM","LEAVEROOM",["ROOM"],[]),
    MessageTypeSetting("COMMAND/ENABLELOGGING","ENABLELOGGING",[],["COMPONENT"]),
    MessageTypeSetting("COMMAND/DISABLELOGGING","DISABLELOGGING",[],["COMPONENT"]),
    MessageTypeSetting("COMMAND/SAVEMODELWEIGHTS","SAVEMODELWEIGHTS",[],["WEIGHTS","COMPONENT"]),
    MessageTypeSetting("COMMAND/LOADMODELWEIGHTS","LOADMODELWEIGHTS",[],["WEIGHTS","COMPONENT"]),
    MessageTypeSetting("COMMAND/SAVESETTINGS","SAVESETTINGS",["SETTINGS"],["COMPONENT"]),
    MessageTypeSetting("COMMAND/LOADSETTINGS","LOADSETTINGS",["SETTINGS"],["COMPONENT"]),
    MessageTypeSetting("COMMAND/CUSTOM","CUSTOM",[],[])
)

"""
The type to define the possible settings for a LOG message.

:param MODELWEIGHTS: MessageTypeSetting for log mdoel weights messages.
:param SETTINGS: MessageTypeSetting for log settings messages.
:param MESSAGE: MessageTypeSetting for messages to log messages.
:param KPI: MessageTypeSetting for messages to log KPIs.
:param RUN: MessageTypeSetting for messages to log runs.
:param CUSTOM: MessageTypeSetting for custom messages.
"""
struct log_struct <: MessageMainType
    MODELWEIGHTS::MessageTypeSetting
    SETTINGS::MessageTypeSetting
    MESSAGE::MessageTypeSetting
    KPI::MessageTypeSetting
    RUN::MessageTypeSetting
    CUSTOM::MessageTypeSetting
end

"""
This type contains the possible settings for a LOG message.
"""
LOG = log_struct(
    MessageTypeSetting("LOG/MODELWEIGHTS","MODELWEIGHTS",["WEIGHTS", "COMPONENT"],["DM"]),
    MessageTypeSetting("LOG/SETTINGS","SETTINGS",["SETTINGS", "COMPONENT"],["DM"]),
    MessageTypeSetting("LOG/MESSAGES","MESSAGES",["MESSAGE", "SENDER", "ROOM"],[]),
    MessageTypeSetting("LOG/KPI","KPI",["KPI", "COMPONENT","TIME","VALUE"],[]),
    MessageTypeSetting("LOG/RUN","RUN",["RUN"],["TYPE","STARTTIME","ENDTIME"]),
    MessageTypeSetting("LOG/CUSTOM","CUSTOM",[],[])
)

"""
The type to define the possible settings for a all message types.
"""
struct messagetype_struct
    DATA::data_struct
    COMMAND::command_struct
    LOG::log_struct
end

"""
Returns the message type setting with the given id, or None if no such setting exists.

:param cls: A messagetype_struct.
:param id: The unique identifier of the message type setting to return.
:return: The message type setting with the given id, or None if no such setting exists.
:rtype: MessageTypeSetting or None
"""
function by_id(cls::messagetype_struct,id::String)
    FieldsInStruct=fieldnames(typeof(cls));
    for i=1:length(FieldsInStruct)
        Value=getfield(cls, FieldsInStruct[i])
        messagetype = by_id(Value,id)
        if messagetype!=Nothing
            return messagetype
        end
    end
    return Nothing
end

"""
This class contains the possible settings for a all message types.
"""
MESSAGE_TYPE = messagetype_struct(
    DATA,
    COMMAND,
    LOG
)

end
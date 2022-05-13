module messagetype

struct MessageTypeSetting
    id::String
    name::String
    required_fields
    optional_fields
end

function check_fields(cls::MessageTypeSetting,msg_content::Dict)
    for field in cls.required_fields
        if !(field in keys(ms_content))
            return false
        end
    end
    return true
end

abstract type MessageMainType end

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

struct data_struct <: MessageMainType
    FORWARD::MessageTypeSetting
    GRADIENT::MessageTypeSetting
    REWARD::MessageTypeSetting
    TEXT::MessageTypeSetting
    CUSTOM::MessageTypeSetting
end

DATA = data_struct(
    MessageTypeSetting("DATA/FORWARD","FORWARD",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/GRADIENT","GRADIENT",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/REWARD","REWARD",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/TEXT","TEXT",["DATA"],["ROOM"]),
    MessageTypeSetting("DATA/CUSTOM","CUSTOM",[],[])
)

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

struct log_struct <: MessageMainType
    MODELWEIGHTS::MessageTypeSetting
    SETTINGS::MessageTypeSetting
    MESSAGE::MessageTypeSetting
    KPI::MessageTypeSetting
    RUN::MessageTypeSetting
    CUSTOM::MessageTypeSetting
end

LOG = log_struct(
    MessageTypeSetting("LOG/MODELWEIGHTS","MODELWEIGHTS",["WEIGHTS", "COMPONENT"],["DM"]),
    MessageTypeSetting("LOG/SETTINGS","SETTINGS",["SETTINGS", "COMPONENT"],["DM"]),
    MessageTypeSetting("LOG/MESSAGES","MESSAGES",["MESSAGE", "SENDER", "ROOM"],[]),
    MessageTypeSetting("LOG/KPI","KPI",["KPI", "COMPONENT","TIME","VALUE"],[]),
    MessageTypeSetting("LOG/RUN","RUN",["RUN"],["TYPE","STARTTIME","ENDTIME"]),
    MessageTypeSetting("LOG/CUSTOM","CUSTOM",[],[])
)

struct messagetype_struct
    DATA::data_struct
    COMMAND::command_struct
    LOG::log_struct
end

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

MESSAGE_TYPE = messagetype_struct(
    DATA,
    COMMAND,
    LOG
)

end
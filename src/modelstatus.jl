module modelstatus

struct ModelStatusSetting
    id::Int
    name::String
end

struct modelstatus_struct
    TRAIN::ModelStatusSetting
    VALIDATE::ModelStatusSetting
end

function by_id(cls::modelstatus_struct, id::Int)
    FieldsInStruct=fieldnames(typeof(cls));
	for i=1:length(FieldsInStruct)
		#Check field i
		Value=getfield(cls, FieldsInStruct[i])
		if Value.id==id
            return Value
        end
	end
    return Nothing
end

MODEL_STATUS = modelstatus_struct(ModelStatusSetting(1, "TRAIN"), ModelStatusSetting(2, "VALIDATE"))

end
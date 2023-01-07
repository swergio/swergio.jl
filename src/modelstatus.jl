"""
Module containing models status definition.

Exported constant settings:
    - **MODEL_STATUS** containing the possible settings for a model's status
"""
module modelstatus

"""
This type represents a setting for a model's status.

:param id: The unique identifier for the model status setting.
:param name: The name of the model status setting.
"""
struct ModelStatusSetting
    id::Int
    name::String
end

"""
The type to define the possible settings for a model's status.

:param TRAIN: ModelStatusSetting for training.
:param VALIDATE: ModelStatusSetting for validation.
"""
struct modelstatus_struct
    TRAIN::ModelStatusSetting
    VALIDATE::ModelStatusSetting
end

"""
Returns the model status setting with the given id, or None if no such setting exists.

:param cls: A modelstatus_struct type.
:param id: The unique identifier of the model status setting to return.
:return: The model status setting with the given id, or None if no such setting exists.
"""
function by_id(cls::modelstatus_struct, id::Int)
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
This type contains the possible settings for a model's status.
"""
MODEL_STATUS = modelstatus_struct(ModelStatusSetting(1, "TRAIN"), ModelStatusSetting(2, "VALIDATE"))

end
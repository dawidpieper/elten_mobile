# Abstract class for MTFL Controllers
class Control_MTFL
def initialize(struct)
raise(ArgumentError, "not MTLF struct") if !@struct.is_a?(Struct_MTLFContainer)
@struct=struct
end
end
package funkin.backend;

//c++ types for haxe
#if cpp
//they are separated by their support of negative values

//-128 to 127
typedef ByteInt = cpp.Int8;
//-32768 to 32767
typedef ShortInt = cpp.Int16;

//0 to 255
typedef ByteUInt = cpp.UInt8;
//0 to 65535
typedef ShortUInt = cpp.UInt16;

#else //just in case the engine isn't being compiled for cpp
typedef ByteInt = Int;
typedef ShortInt = Int;
typedef ByteUInt = Int;
typedef ShortUInt = Int;
#end
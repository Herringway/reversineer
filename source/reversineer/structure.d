module reversineer.structure;

import std.traits;

enum isPODStruct(T) = !isIntegral!T && !isSomeChar!T && !isBoolean!T && !isFloatingPoint!T && isMutable!T && isSimpleStruct!T;

template isSimpleStruct(T) {
	static if (!is(T == struct)) {
		enum isSimpleStruct = false;
	}
	else static if (!__traits(compiles, { T val; })) {
		enum isSimpleStruct = false;
	} else {
		enum isSimpleStruct = true;
	}
}
@safe pure nothrow @nogc unittest {
	struct SimpleStruct { int v; }
	struct NonSimpleStruct { int v; @disable this(); }
	static assert(!isSimpleStruct!int);
	static assert(isSimpleStruct!SimpleStruct);
	static assert(!isSimpleStruct!NonSimpleStruct);
}

pure @safe nothrow unittest {
	import reversineer.io : read;
	struct Basic {
		int x;
	}
	assert((cast(ubyte[])[4, 0, 0, 0]).read!Basic == Basic(4));

	struct InputRangeReduce {
		ubyte[] bytes;
		size_t index = 0;
		ubyte front() @safe pure nothrow @nogc {
			return bytes[index];
		}
		bool empty() @safe pure nothrow @nogc {
			return index >= bytes.length;
		}
		void popFront() @safe pure nothrow @nogc {
			index++;
		}
	}
	assert(InputRangeReduce([4, 0, 0, 0]).read!Basic == Basic(4));
}

struct Offset {
	ulong offset;
}

struct Palette {
	bool shareSeed = false;
	bool dontSkipFirst = false;
}
struct Name {
}

struct Label {
	string name;
	string description;
}

struct Randomize {}

struct Width {
	ulong width;
}

struct Height {
	ulong height;
}

enum RowByRow;

align(1) struct UnknownData(size_t Size) {
	align(1):
	ubyte[Size] raw;
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
}

@safe pure unittest {
	UnknownData!4 data;
	data.raw = [1, 2, 3, 4];
	assert(data.toBase64 == "AQIDBA==");
}

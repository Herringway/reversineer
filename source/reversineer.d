module reversineer;
import std.exception : enforce;
import std.random;
import std.range;
import std.stdio;
import std.system;
import std.traits;

/++
+ Reads a POD struct from a range of bytes.
+
+ Params:
+		T = type to read
+		input = bytes to read data from
+		val = destination to place read data at
+/
T read(T, Range)(Range input) if (isPODStruct!T && isInputRange!Range && is(ElementType!Range : const ubyte)) {
	T val = void;
	read(input, val);
	return val;
}
/// ditto
void read(T, Range)(Range input, ref T val) @safe if (isPODStruct!T && isInputRange!Range && is(ElementType!Range : const ubyte)) {
	union Output {
		T val;
		ubyte[T.sizeof] bytes;
	}
	Output output = void;
	static if (hasSlicing!Range) {
		output.bytes = input[0..val.sizeof];
	} else {
		foreach (ref target; output.bytes) {
			target = input.front;
			input.popFront();
		}
	}
	val = output.val;
}
/// ditto
void read(T, Range)(Range input, T* val) @safe if (isPODStruct!T && isInputRange!Range && is(ElementType!Range : const ubyte)) {
	union Output {
		T val;
		ubyte[T.sizeof] bytes;
	}
	auto output = cast(Output*)val;
	static if (hasSlicing!Range) {
		output.bytes = input[0..T.sizeof];
	} else {
		foreach (ref target; output.bytes) {
			assert(!input.empty, "Not enough bytes left to read!");
			target = input.front;
			input.popFront();
		}
	}
}
/// Read struct from raw data
@safe unittest {
	ubyte[] data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
	align(1)
	struct X {
		align(1):
		ubyte a;
		ushort b;
		uint c;
		ulong d;
		ubyte[5] e;
	}

	auto readData = data.read!X();
	with (readData) {
		assert(a == 0);
		assert(b == 0x201);
		assert(c == 0x6050403);
		assert(d == 0x0E0D0C0B0A090807);
		assert(e == [15, 16, 17, 18, 19]);
	}
}
/// Read struct from raw data with destination premade
@safe unittest {
	ubyte[] data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
	align(1)
	struct X {
		align(1):
		ubyte a;
		ushort b;
		uint c;
		ulong d;
		ubyte[5] e;
	}

	X readData;
	data.read!X(readData);
	with (readData) {
		assert(a == 0);
		assert(b == 0x201);
		assert(c == 0x6050403);
		assert(d == 0x0E0D0C0B0A090807);
		assert(e == [15, 16, 17, 18, 19]);
	}
}
/// Read struct from raw data with destination preallocated on heap
@safe unittest {
	ubyte[] data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
	align(1)
	struct X {
		align(1):
		ubyte a;
		ushort b;
		uint c;
		ulong d;
		ubyte[5] e;
	}

	auto readData = new X;
	data.read!X(readData);
	with (readData) {
		assert(a == 0);
		assert(b == 0x201);
		assert(c == 0x6050403);
		assert(d == 0x0E0D0C0B0A090807);
		assert(e == [15, 16, 17, 18, 19]);
	}
}

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

private struct EndianType(T, bool littleEndian) {
	ubyte[T.sizeof] raw;
	alias native this;
	version(BigEndian) {
		enum needSwap = littleEndian;
	} else {
		enum needSwap = !littleEndian;
	}
	T native() const @safe {
		T result = (cast(T[])(raw[].dup))[0];
		static if (needSwap) {
			swapEndianness(result);
		}
		return result;
	}
	void toString(Range)(Range sink) const if (isOutputRange!(Range, const(char))) {
		import std.format : formattedWrite;
		sink.formattedWrite!"%s"(this.native);
	}
	void opAssign(ubyte[T.sizeof] input) {
		raw = input;
	}
	void opAssign(ubyte[] input) {
		assert(input.length == T.sizeof, "Array must be "~T.sizeof.stringof~" bytes long");
		raw = input;
	}
	void opAssign(T input) @safe {
		static if (needSwap) {
			swapEndianness(input);
		}
		union Raw {
			T val;
			ubyte[T.sizeof] raw;
		}
		raw = Raw(input).raw;
	}
}

void swapEndianness(T)(ref T val) {
	import std.bitmanip : swapEndian;
	static if (isIntegral!T || isSomeChar!T || isBoolean!T) {
		val = swapEndian(val);
	} else static if (isFloatingPoint!T) {
		import std.algorithm : reverse;
		union Raw {
			T val;
			ubyte[T.sizeof] raw;
		}
		auto raw = Raw(val);
		reverse(raw.raw[]);
		val = raw.val;
	} else static if (is(T == struct)) {
		foreach (ref field; val.tupleof) {
			swapEndianness(field);
		}
	} else static assert(0, "Unsupported type "~T.stringof);
}

/++
+ Represents a little endian type. Most significant bits come last, so 0x4000
+ is, for example, represented as [00, 04].
+/
alias LittleEndian(T) = EndianType!(T, true);
///
@safe unittest {
	import std.conv : text;
	LittleEndian!ushort x;
	x = cast(ubyte[])[0, 2];
	assert(x == 0x200);
	assert(x.text == "512");
	ubyte[] z = [0, 3];
	x = z;
	assert(x == 0x300);
	assert(x.text == "768");
	x = 1024;
	assert(x.raw == [0, 4]);

	LittleEndian!float f;
	f = cast(ubyte[])[0, 0, 32, 64];
	assert(f == 2.5);

	align(1) static struct Test {
		align(1):
		uint a;
		ushort b;
	}
	LittleEndian!Test t;
	t = cast(ubyte[])[3, 2, 1, 0, 2, 1];
	assert(t.a == 0x010203);
	assert(t.b == 0x0102);
	t = Test(42, 42);
	assert(t.raw == [42, 0, 0, 0, 42, 0]);
}

/++
+ Represents a big endian type. Most significant bits come first, so 0x4000
+ is, for example, represented as [04, 00].
+/
alias BigEndian(T) = EndianType!(T, false);
///
@safe unittest {
	import std.conv : text;
	BigEndian!ushort x;
	x = cast(ubyte[])[2, 0];
	assert(x == 0x200);
	assert(x.text == "512");
	x = 1024;
	assert(x.raw == [4, 0]);

	BigEndian!float f;
	f = cast(ubyte[])[64, 32, 0, 0];
	assert(f == 2.5);

	align(1) static struct Test {
		align(1):
		uint a;
		ushort b;
	}
	BigEndian!Test t;
	t = cast(ubyte[])[0, 1, 2, 3, 1, 2];
	assert(t.a == 0x010203);
	assert(t.b == 0x0102);
	t = Test(42, 42);
	assert(t.raw == [0, 0, 0, 42, 0, 42]);
}

private T fromPBCD(T)(ubyte[T.sizeof] input) {
	import std.algorithm : map;
	import std.array : array;
	import std.math : pow;
	static immutable ulong[] multipliers = iota(T.sizeof*2).retro.map!(x => pow(10,x)).array;
	T output;
	foreach (index, b; input) {
		output += (b&0xF) * multipliers[index*2+1];
		output += ((b&0xF0)>>4) * multipliers[index*2];
	}
	return output;
}
///
@safe unittest {
	ubyte[2] data = [0x98, 0x76];
	assert(data.fromPBCD!ushort() == 9876);
}


private ubyte[T.sizeof] toPBCD(T)(T input) {
	import std.algorithm : map;
	import std.array : array;
	import std.math : pow;
	static immutable ulong[] multipliers = iota(T.sizeof*2).retro.map!(x => pow(10,x)).array;
	ubyte[T.sizeof] output;
	foreach (index, ref b; output) {
		b += (input/multipliers[index*2+1])%10;
		b += (input/multipliers[index*2])%10*16;
	}
	return output;
}
///
@safe unittest {
	assert(9876.toPBCD!ushort == [0x98, 0x76]);
}

/++
+ Represents a little endian type in packed binary-coded decimal coding. This
+ coding is common in old processors, but doesn't see much use in the modern
+ era.
+
+ See_also: https://en.wikipedia.org/wiki/Binary-coded_decimal
+/
struct PackedBCD(T) {
	ubyte[T.sizeof] raw;
	alias toInt this;
	T toInt() const {
		return fromPBCD(raw);
	}
	void toString(Range)(Range sink) const if (isOutputRange!(Range, const(char))) {
		import std.format : formattedWrite;
		sink.formattedWrite!"%s"(this.toInt());
	}
	void opAssign(ubyte[T.sizeof] input) {
		raw = input;
	}
	void opAssign(ubyte[] input) {
		raw = input;
	}
	void opAssign(const T input) {
		raw = toPBCD(input);
	}
}
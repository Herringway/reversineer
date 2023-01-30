module reversineer.io;

import std.range;

import reversineer.structure;

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

module reversineer.strings;

ubyte[] writeTableString(bool expand)(ubyte[] data, string[char] table, string str, out size_t index) @safe pure {
	import std.algorithm.searching : startsWith;
	import std.exception : enforce;
	while (str.length > 0) {
		bool found;
		foreach (k, v; table) {
			if (str.startsWith(v)) {
				found = true;
				str = str[v.length .. $];
				if (index >= data.length) {
					enforce(expand, "String too large");
					data.length = index + 1;
				}
				data[index++] = k;
				break;
			}
		}
		assert(found, "Table does not contain anything matching '"~str~"'");
	}
	return data;
}

align(1) struct SimpleChar(alias table) {
	align(1):
	ubyte val;
	string toChar() const @safe {
		import std.format : format;
		if (val in table) {
			return table[val];
		} else {
			return format!"[%02X]"(val);
		}
	}
}

@safe pure unittest {
	SimpleChar!(['a': "bb"]) c;
	assert(c.toChar == "[00]");
}

align(1) struct SimpleString(alias table, ubyte terminator, size_t Length) {
	align(1):
	ubyte[Length] str;
	size_t length() const @safe {
		return Length;
	}
	string toString() const @safe {
		string result;
		foreach (chr; str) {
			if (chr == terminator) {
				break;
			}
			result ~= SimpleChar!table(chr).toChar();
		}
		return result;
	}
	void opAssign(const string input) @safe {
		str[] = terminator;
		foreach (i, inChar; input) {
			bool found;
			foreach (k, v; table) {
				if (v == [inChar]) {
					found = true;
					str[i] = k;
					break;
				}
			}
			assert(found, "String does not support character '"~inChar~"'");
		}
	}
	string toSiryulType()() @safe {
		return toString();
	}
	static SimpleString fromSiryulType()(string val) @safe {
		SimpleString str;
		str = val;
		return str;
	}
}

struct SimpleStringDynamic(alias table, ubyte terminator) {
	import std.algorithm.searching : countUntil;
	ubyte[] str;
	size_t length() const @safe {
		return str.countUntil!(x => x == terminator);
	}
	string toString() const @safe {
		string result;
		foreach (chr; str) {
			if (chr == terminator) {
				break;
			}
			result ~= SimpleChar!table(chr).toChar();
		}
		return result;
	}
	void opAssign(string input) @safe {
		size_t index;
		str = writeTableString!true(str[], table, input, index);
		str.length = index;
	}
	string toSiryulType()() @safe {
		return toString();
	}
	static SimpleStringDynamic fromSiryulType()(string val) @safe {
		SimpleStringDynamic str;
		str = val;
		return str;
	}
}

@safe pure unittest {
	const str = SimpleStringDynamic!(['a': "bb"], 0)(['a', 'a', 'a', 0]);
	assert(str.toString == "bbbbbb");
	SimpleStringDynamic!(['a': "bb"], 0) tmp;
	tmp = "bbbbbbbb";
	assert(tmp.str == ['a', 'a', 'a', 'a']);
	tmp = "bb";
	assert(tmp.str == ['a']);
}

align(1) struct SimpleStrings(alias table, ubyte terminator, size_t Length) {
	align(1):
	ubyte[Length] str;
	size_t length() const @safe {
		return Length;
	}
	string[] toString() const @safe {
		import std.algorithm.iteration : joiner, map, splitter;
		string[] result;
		string buf;
		foreach (chr; str) {
			if (chr == terminator) {
				result ~= buf;
				buf = "";
			} else {
				buf ~= SimpleChar!table(chr).toChar();
			}
		}
		if (buf.length > 0) {
			result ~= buf;
		}
		return result;
	}
	void opAssign(const string input) @safe {
		str[] = terminator;
		size_t _;
		writeTableString!false(str[0 .. $], table, input, _);
	}
	void opAssign(const string[] input) @safe {
		str[] = terminator;
		size_t offset;
		foreach (inputStr; input) {
			writeTableString!false(str[offset .. $], table, inputStr, offset);
			offset++;
		}
	}
	auto opSlice() {
		import std.algorithm.iteration : map, splitter;
		return str[].splitter(terminator).map!(x => SimpleStringDynamic!(table, terminator)(x));
	}
	string[] toSiryulType()() @safe {
		return toString();
	}
	static SimpleStrings fromSiryulType()(string[] val) @safe {
		SimpleStrings str;
		str = val;
		return str;
	}
}

@safe pure unittest {
	import std.conv : text;
	const strings = SimpleStrings!(['a': "bb"], 0, 3)(['a', 'a', 'a']);
	assert(strings.toString == ["bbbbbb"]);
	SimpleStrings!(['a': "bb"], 0, 10) test;
	test = ["bb", "bb"];
	assert(test.toString == ["bb", "bb", "", "", "", "", "", ""]);
}

package decode;
import haxe.ds.Vector;
import haxe.io.Bytes;
import decode.transform.Transform;

/**
 * ...
 * @author 
 */
class Transforms
{
//@:enum
//abstract WordTransformType(Int){
	public static var kIdentity       = 0;
	public static var kOmitLast1      = 1;
	public static var kOmitLast2      = 2;
	public static var kOmitLast3      = 3;
	public static var kOmitLast4      = 4;
	public static var kOmitLast5      = 5;
	public static var kOmitLast6      = 6;
	public static var kOmitLast7      = 7;
	public static var kOmitLast8      = 8;
	public static var kOmitLast9      = 9;
	public static var kUppercaseFirst = 10;
	public static var kUppercaseAll   = 11;
	public static var kOmitFirst1     = 12;
	public static var kOmitFirst2     = 13;
	public static var kOmitFirst3     = 14;
	public static var kOmitFirst4     = 15;
	public static var kOmitFirst5     = 16;
	public static var kOmitFirst6     = 17;
	public static var kOmitFirst7     = 18;
	public static var kOmitFirst8     = 19;
	public static var kOmitFirst9     = 20;
//}

public static var kTransforms:Array<Transform> = [
     new Transform(         "", kIdentity,       ""           ),
     new Transform(         "", kIdentity,       " "          ),
     new Transform(        " ", kIdentity,       " "          ),
     new Transform(         "", kOmitFirst1,     ""           ),
     new Transform(         "", kUppercaseFirst, " "          ),
     new Transform(         "", kIdentity,       " the "      ),
     new Transform(        " ", kIdentity,       ""           ),
     new Transform(       "s ", kIdentity,       " "          ),
     new Transform(         "", kIdentity,       " of "       ),
     new Transform(         "", kUppercaseFirst, ""           ),
     new Transform(         "", kIdentity,       " and "      ),
     new Transform(         "", kOmitFirst2,     ""           ),
     new Transform(         "", kOmitLast1,      ""           ),
     new Transform(       ", ", kIdentity,       " "          ),
     new Transform(         "", kIdentity,       ", "         ),
     new Transform(        " ", kUppercaseFirst, " "          ),
     new Transform(         "", kIdentity,       " in "       ),
     new Transform(         "", kIdentity,       " to "       ),
     new Transform(       "e ", kIdentity,       " "          ),
     new Transform(         "", kIdentity,       "\""         ),
     new Transform(         "", kIdentity,       "."          ),
     new Transform(         "", kIdentity,       "\">"        ),
     new Transform(         "", kIdentity,       "\n"         ),
     new Transform(         "", kOmitLast3,      ""           ),
     new Transform(         "", kIdentity,       "]"          ),
     new Transform(         "", kIdentity,       " for "      ),
     new Transform(         "", kOmitFirst3,     ""           ),
     new Transform(         "", kOmitLast2,      ""           ),
     new Transform(         "", kIdentity,       " a "        ),
     new Transform(         "", kIdentity,       " that "     ),
     new Transform(        " ", kUppercaseFirst, ""           ),
     new Transform(         "", kIdentity,       ". "         ),
     new Transform(        ".", kIdentity,       ""           ),
     new Transform(        " ", kIdentity,       ", "         ),
     new Transform(         "", kOmitFirst4,     ""           ),
     new Transform(         "", kIdentity,       " with "     ),
     new Transform(         "", kIdentity,       "'"          ),
     new Transform(         "", kIdentity,       " from "     ),
     new Transform(         "", kIdentity,       " by "       ),
     new Transform(         "", kOmitFirst5,     ""           ),
     new Transform(         "", kOmitFirst6,     ""           ),
     new Transform(    " the ", kIdentity,       ""           ),
     new Transform(         "", kOmitLast4,      ""           ),
     new Transform(         "", kIdentity,       ". The "     ),
     new Transform(         "", kUppercaseAll,   ""           ),
     new Transform(         "", kIdentity,       " on "       ),
     new Transform(         "", kIdentity,       " as "       ),
     new Transform(         "", kIdentity,       " is "       ),
     new Transform(         "", kOmitLast7,      ""           ),
     new Transform(         "", kOmitLast1,      "ing "       ),
     new Transform(         "", kIdentity,       "\n\t"       ),
     new Transform(         "", kIdentity,       ":"          ),
     new Transform(        " ", kIdentity,       ". "         ),
     new Transform(         "", kIdentity,       "ed "        ),
     new Transform(         "", kOmitFirst9,     ""           ),
     new Transform(         "", kOmitFirst7,     ""           ),
     new Transform(         "", kOmitLast6,      ""           ),
     new Transform(         "", kIdentity,       "("          ),
     new Transform(         "", kUppercaseFirst, ", "         ),
     new Transform(         "", kOmitLast8,      ""           ),
     new Transform(         "", kIdentity,       " at "       ),
     new Transform(         "", kIdentity,       "ly "        ),
     new Transform(    " the ", kIdentity,       " of "       ),
     new Transform(         "", kOmitLast5,      ""           ),
     new Transform(         "", kOmitLast9,      ""           ),
     new Transform(        " ", kUppercaseFirst, ", "         ),
     new Transform(         "", kUppercaseFirst, "\""         ),
     new Transform(        ".", kIdentity,       "("          ),
     new Transform(         "", kUppercaseAll,   " "          ),
     new Transform(         "", kUppercaseFirst, "\">"        ),
     new Transform(         "", kIdentity,       "=\""        ),
     new Transform(        " ", kIdentity,       "."          ),
     new Transform(    ".com/", kIdentity,       ""           ),
     new Transform(    " the ", kIdentity,       " of the "   ),
     new Transform(         "", kUppercaseFirst, "'"          ),
     new Transform(         "", kIdentity,       ". This "    ),
     new Transform(         "", kIdentity,       ","          ),
     new Transform(        ".", kIdentity,       " "          ),
     new Transform(         "", kUppercaseFirst, "("          ),
     new Transform(         "", kUppercaseFirst, "."          ),
     new Transform(         "", kIdentity,       " not "      ),
     new Transform(        " ", kIdentity,       "=\""        ),
     new Transform(         "", kIdentity,       "er "        ),
     new Transform(        " ", kUppercaseAll,   " "          ),
     new Transform(         "", kIdentity,       "al "        ),
     new Transform(        " ", kUppercaseAll,   ""           ),
     new Transform(         "", kIdentity,       "='"         ),
     new Transform(         "", kUppercaseAll,   "\""         ),
     new Transform(         "", kUppercaseFirst, ". "         ),
     new Transform(        " ", kIdentity,       "("          ),
     new Transform(         "", kIdentity,       "ful "       ),
     new Transform(        " ", kUppercaseFirst, ". "         ),
     new Transform(         "", kIdentity,       "ive "       ),
     new Transform(         "", kIdentity,       "less "      ),
     new Transform(         "", kUppercaseAll,   "'"          ),
     new Transform(         "", kIdentity,       "est "       ),
     new Transform(        " ", kUppercaseFirst, "."          ),
     new Transform(         "", kUppercaseAll,   "\">"        ),
     new Transform(        " ", kIdentity,       "='"         ),
     new Transform(         "", kUppercaseFirst, ","          ),
     new Transform(         "", kIdentity,       "ize "       ),
     new Transform(         "", kUppercaseAll,   "."          ),
     new Transform( "\xc2\xa0", kIdentity,       ""           ),
     new Transform(        " ", kIdentity,       ","          ),
     new Transform(         "", kUppercaseFirst, "=\""        ),
     new Transform(         "", kUppercaseAll,   "=\""        ),
     new Transform(         "", kIdentity,       "ous "       ),
     new Transform(         "", kUppercaseAll,   ", "         ),
     new Transform(         "", kUppercaseFirst, "='"         ),
     new Transform(        " ", kUppercaseFirst, ","          ),
     new Transform(        " ", kUppercaseAll,   "=\""        ),
     new Transform(        " ", kUppercaseAll,   ", "         ),
     new Transform(         "", kUppercaseAll,   ","          ),
     new Transform(         "", kUppercaseAll,   "("          ),
     new Transform(         "", kUppercaseAll,   ". "         ),
     new Transform(        " ", kUppercaseAll,   "."          ),
     new Transform(         "", kUppercaseAll,   "='"         ),
     new Transform(        " ", kUppercaseAll,   ". "         ),
     new Transform(        " ", kUppercaseFirst, "=\""        ),
     new Transform(        " ", kUppercaseAll,   "='"         ),
     new Transform(        " ", kUppercaseFirst, "='"         )
];

static public var kNumTransforms:Int = kTransforms.length;// sizeof(kTransforms) / sizeof(kTransforms[0]);


static public function ToUpperCase(p:Vector<UInt>,p_off:Int):Int {
  if (p[p_off+0] < 0xc0) {
    if (p[p_off+0] >= 'a'.charCodeAt(0) && p[p_off+0] <= 'z'.charCodeAt(0)) {
      p[p_off+0] ^= 32;
    }
    return 1;
  }
  /* An overly simplified uppercasing model for utf-8. */
  if (p[p_off+0] < 0xe0) {
    p[p_off+1] ^= 32;
    return 2;
  }
  /* An arbitrary transform for three byte characters. */
  p[p_off+2] ^= 5;
  return 3;
}

static public function TransformDictionaryWord(
    dst:Vector<UInt>, dst_off:Int, word:Vector<UInt>, word_off:Int, len:Int, transform:Int):Int {
  var prefix:Array<UInt> = kTransforms[transform].prefix;//const char*
  var prefix_off:Int = 0;//const char*
  var suffix:Array<UInt> = kTransforms[transform].suffix;//const char*
  var suffix_off:Int = 0;//const char*
  var t:Int = kTransforms[transform].transform;
  var skip:Int = t < kOmitFirst1 ? 0 : t - (kOmitFirst1 - 1);
  var idx:Int = 0;
  var i:Int = 0;
  var uppercase:Vector<UInt>;
  var uppercase_off:Int;
  if (skip > len) {
    skip = len;
  }
  for (prefix_off in 0...prefix.length) { dst[dst_off+(idx++)] = prefix[prefix_off]; }
  word_off += skip;
  len -= skip;
  if (t <= kOmitLast9) {
    len -= t;
  }
  while (i < len) { dst[dst_off+(idx++)] = word[word_off+(i++)]; }
  uppercase = dst;
  uppercase_off = dst_off+(idx - len);//&
  if (t == kUppercaseFirst) {
    ToUpperCase(uppercase,uppercase_off);
  } else if (t == kUppercaseAll) {
    while (len > 0) {
      var step:Int = ToUpperCase(uppercase,uppercase_off);
      uppercase_off += step;
      len -= step;
    }
  }
  for (suffix_off in 0...suffix.length) { dst[dst_off+(idx++)] = suffix[suffix_off]; }
  return idx;
}

	public function new() 
	{
	}
	
}
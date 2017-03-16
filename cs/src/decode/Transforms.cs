// Generated by Haxe 3.4.0

#pragma warning disable 109, 114, 219, 429, 168, 162
namespace decode {
	public class Transforms : global::haxe.lang.HxObject {
		
		static Transforms() {
			unchecked {
				global::decode.Transforms.kIdentity = 0;
				global::decode.Transforms.kOmitLast1 = 1;
				global::decode.Transforms.kOmitLast2 = 2;
				global::decode.Transforms.kOmitLast3 = 3;
				global::decode.Transforms.kOmitLast4 = 4;
				global::decode.Transforms.kOmitLast5 = 5;
				global::decode.Transforms.kOmitLast6 = 6;
				global::decode.Transforms.kOmitLast7 = 7;
				global::decode.Transforms.kOmitLast8 = 8;
				global::decode.Transforms.kOmitLast9 = 9;
				global::decode.Transforms.kUppercaseFirst = 10;
				global::decode.Transforms.kUppercaseAll = 11;
				global::decode.Transforms.kOmitFirst1 = 12;
				global::decode.Transforms.kOmitFirst2 = 13;
				global::decode.Transforms.kOmitFirst3 = 14;
				global::decode.Transforms.kOmitFirst4 = 15;
				global::decode.Transforms.kOmitFirst5 = 16;
				global::decode.Transforms.kOmitFirst6 = 17;
				global::decode.Transforms.kOmitFirst7 = 18;
				global::decode.Transforms.kOmitFirst8 = 19;
				global::decode.Transforms.kOmitFirst9 = 20;
				global::decode.Transforms.kTransforms = new global::Array<object>(new object[]{new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst1, ""), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " the "), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform("s ", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " of "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " and "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst2, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast1, ""), new global::decode.transform.Transform(", ", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ", "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " in "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " to "), new global::decode.transform.Transform("e ", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "\""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "."), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "\">"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "\n"), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast3, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "]"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " for "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst3, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast2, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " a "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " that "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ". "), new global::decode.transform.Transform(".", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, ", "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst4, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " with "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "\'"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " from "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " by "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst5, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst6, ""), new global::decode.transform.Transform(" the ", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast4, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ". The "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " on "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " as "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " is "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast7, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast1, "ing "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "\n\t"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ":"), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, ". "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ed "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst9, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitFirst7, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast6, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "("), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, ", "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast8, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " at "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ly "), new global::decode.transform.Transform(" the ", global::decode.Transforms.kIdentity, " of "), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast5, ""), new global::decode.transform.Transform("", global::decode.Transforms.kOmitLast9, ""), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, ", "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "\""), new global::decode.transform.Transform(".", global::decode.Transforms.kIdentity, "("), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, " "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "\">"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "=\""), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, "."), new global::decode.transform.Transform(".com/", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform(" the ", global::decode.Transforms.kIdentity, " of the "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "\'"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ". This "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, ","), new global::decode.transform.Transform(".", global::decode.Transforms.kIdentity, " "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "("), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "."), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, " not "), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, "=\""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "er "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, " "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "al "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, ""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "=\'"), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "\""), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, ". "), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, "("), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ful "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, ". "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ive "), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "less "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "\'"), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "est "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, "."), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "\">"), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, "=\'"), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, ","), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ize "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "."), new global::decode.transform.Transform("\u00a0", global::decode.Transforms.kIdentity, ""), new global::decode.transform.Transform(" ", global::decode.Transforms.kIdentity, ","), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "=\""), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "=\""), new global::decode.transform.Transform("", global::decode.Transforms.kIdentity, "ous "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, ", "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseFirst, "=\'"), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, ","), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, "=\""), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, ", "), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, ","), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "("), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, ". "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, "."), new global::decode.transform.Transform("", global::decode.Transforms.kUppercaseAll, "=\'"), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, ". "), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, "=\""), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseAll, "=\'"), new global::decode.transform.Transform(" ", global::decode.Transforms.kUppercaseFirst, "=\'")});
				global::decode.Transforms.kNumTransforms = global::decode.Transforms.kTransforms.length;
			}
		}
		
		
		public Transforms(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public Transforms() {
			global::decode.Transforms.__hx_ctor_decode_Transforms(this);
		}
		
		
		public static void __hx_ctor_decode_Transforms(global::decode.Transforms __hx_this) {
		}
		
		
		public static int kIdentity;
		
		public static int kOmitLast1;
		
		public static int kOmitLast2;
		
		public static int kOmitLast3;
		
		public static int kOmitLast4;
		
		public static int kOmitLast5;
		
		public static int kOmitLast6;
		
		public static int kOmitLast7;
		
		public static int kOmitLast8;
		
		public static int kOmitLast9;
		
		public static int kUppercaseFirst;
		
		public static int kUppercaseAll;
		
		public static int kOmitFirst1;
		
		public static int kOmitFirst2;
		
		public static int kOmitFirst3;
		
		public static int kOmitFirst4;
		
		public static int kOmitFirst5;
		
		public static int kOmitFirst6;
		
		public static int kOmitFirst7;
		
		public static int kOmitFirst8;
		
		public static int kOmitFirst9;
		
		public static global::Array<object> kTransforms;
		
		public static int kNumTransforms;
		
		public static int ToUpperCase(uint[] p, int p_off) {
			unchecked {
				if (((bool) (( ((uint) (((uint[]) (p) )[p_off]) ) < 192 )) )) {
					bool tmp = default(bool);
					global::haxe.lang.Null<int> tmp1 = global::haxe.lang.StringExt.charCodeAt("a", 0);
					if (((bool) (( ((uint) (((uint[]) (p) )[p_off]) ) >= (tmp1).@value )) )) {
						global::haxe.lang.Null<int> tmp2 = global::haxe.lang.StringExt.charCodeAt("z", 0);
						tmp = ((bool) (( ((uint) (((uint[]) (p) )[p_off]) ) <= (tmp2).@value )) );
					}
					else {
						tmp = false;
					}
					
					if (tmp) {
						((uint[]) (p) )[p_off] = ((uint) (( ((uint) (((uint[]) (p) )[p_off]) ) ^ 32 )) );
					}
					
					return 1;
				}
				
				if (((bool) (( ((uint) (((uint[]) (p) )[p_off]) ) < 224 )) )) {
					{
						int _g = ( p_off + 1 );
						((uint[]) (p) )[_g] = ((uint) (( ((uint) (((uint[]) (p) )[_g]) ) ^ 32 )) );
					}
					
					return 2;
				}
				
				{
					int _g1 = ( p_off + 2 );
					((uint[]) (p) )[_g1] = ((uint) (( ((uint) (((uint[]) (p) )[_g1]) ) ^ 5 )) );
				}
				
				return 3;
			}
		}
		
		
		public static int TransformDictionaryWord(uint[] dst, int dst_off, uint[] word, int word_off, int len, int transform) {
			unchecked {
				global::Array<uint> prefix = ((global::decode.transform.Transform) (global::decode.Transforms.kTransforms[transform]) ).prefix;
				global::Array<uint> suffix = ((global::decode.transform.Transform) (global::decode.Transforms.kTransforms[transform]) ).suffix;
				int t = ((global::decode.transform.Transform) (global::decode.Transforms.kTransforms[transform]) ).transform;
				int skip = ( (( t < global::decode.Transforms.kOmitFirst1 )) ? (0) : (( t - (( global::decode.Transforms.kOmitFirst1 - 1 )) )) );
				int idx = 0;
				int i = 0;
				int uppercase_off = default(int);
				if (( skip > len )) {
					skip = len;
				}
				
				{
					int _g1 = 0;
					int _g = prefix.length;
					while (( _g1 < _g )) {
						((uint[]) (dst) )[( dst_off + idx++ )] = prefix[_g1++];
					}
					
				}
				
				word_off += skip;
				len -= skip;
				if (( t <= global::decode.Transforms.kOmitLast9 )) {
					len -= t;
				}
				
				while (( i < len )) {
					((uint[]) (dst) )[( dst_off + idx++ )] = ((uint[]) (word) )[( word_off + i++ )];
				}
				
				uppercase_off = ( dst_off + (( idx - len )) );
				if (( t == global::decode.Transforms.kUppercaseFirst )) {
					global::decode.Transforms.ToUpperCase(dst, uppercase_off);
				}
				else if (( t == global::decode.Transforms.kUppercaseAll )) {
					while (( len > 0 )) {
						int step = global::decode.Transforms.ToUpperCase(dst, uppercase_off);
						uppercase_off += step;
						len -= step;
					}
					
				}
				
				{
					int _g11 = 0;
					int _g2 = suffix.length;
					while (( _g11 < _g2 )) {
						((uint[]) (dst) )[( dst_off + idx++ )] = suffix[_g11++];
					}
					
				}
				
				return idx;
			}
		}
		
		
	}
}


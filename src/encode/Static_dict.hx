package encode;
import haxe.ds.Vector;
import encode.Static_dict.*;
import encode.Port.*;
import encode.Static_dict_lut.*;
import encode.static_dict_lut.*;
import encode.Dictionary.*;
import encode.Find_match_length.*;
import encode.Transform.*;

/**
 * ...
 * @author 
 */
class Static_dict
{
	public static inline var kMaxDictionaryMatchLen = 37;
	public static inline var kInvalidMatch = 0xfffffff;


public static function Hash_1(data:Vector<UInt>, data_off:Int):UInt {// inline
#if !php
  var h:UInt = (BROTLI_UNALIGNED_LOAD32(data, data_off) * kDictHashMul32) >>> 0;
#else
  var h:UInt = (BROTLI_UNALIGNED_LOAD32(data, data_off) * kDictHashMul32) >>> 32;
#end
  // The higher bits contain more mixture from the multiplication,
  // so we take our results from there.
  return h >>> (32 - kDictNumBits);
}

public static function AddMatch(distance:Int, len:Int, len_code:Int, matches:Vector<Int>) {// inline
  matches[len] = Std.int(Math.min(matches[len], (distance << 5) + len_code));
}

public static function DictMatchLength(data:Vector<UInt>,data_off:Int, id:Int, len:Int):Int {// inline
  var offset:Int = kBrotliDictionaryOffsetsByLength[len] + len * id;
  return FindMatchLengthWithLimit(kBrotliDictionary,offset, data, data_off, len);
}

public static function IsMatch(w:DictWord, data:Vector<UInt>,data_off:Int):Bool {
  var offset:Int = kBrotliDictionaryOffsetsByLength[w.len] + w.len * w.idx;
  var dict:Vector<UInt> = kBrotliDictionary;
  var dict_off:Int = offset;
  if (w.transform == 0) {
    // Match against base dictionary word.
    return FindMatchLengthWithLimit(dict, dict_off, data, data_off, w.len) == w.len;
  } else if (w.transform == 10) {
    // Match against uppercase first transform.
    // Note that there are only ASCII uppercase words in the lookup table.
    return (dict[dict_off+0] >= 'a'.charCodeAt(0) && dict[dict_off+0] <= 'z'.charCodeAt(0) &&
            (dict[dict_off+0] ^ 32) == data[data_off+0] &&
            FindMatchLengthWithLimit(dict,dict_off+1, data,data_off+1, w.len - 1) ==
            w.len - 1);
  } else {
    // Match against uppercase all transform.
    // Note that there are only ASCII uppercase words in the lookup table.
    for (i in 0...w.len) {
      if (dict[dict_off+i] >= 'a'.charCodeAt(0) && dict[dict_off+i] <= 'z'.charCodeAt(0)) {
        if ((dict[dict_off+i] ^ 32) != data[data_off+i]) return false;
      } else {
        if (dict[dict_off+i] != data[data_off+i]) return false;
      }
    }
    return true;
  }
}

public static function FindAllStaticDictionaryMatches(data:Vector<UInt>,data_off:Int,
                                    min_length:Int,
                                    matches:Vector<Int>,matches_off:Int):Bool {
  var found_match:Bool = false;
  var key:UInt = Hash_1(data,data_off);
  var bucket:UInt = kStaticDictionaryBuckets[key];
  if (bucket != 0) {
    var num:Int = bucket & 0xff;
    var offset:Int = bucket >> 8;
    for (i in 0...num) {
      var w:DictWord = kStaticDictionaryWords[offset + i];
      var l:Int = w.len;
      var n:Int = 1 << kBrotliDictionarySizeBitsByLength[l];
      var id:Int = w.idx;
      if (w.transform == 0) {
        var matchlen:Int = DictMatchLength(data, data_off, id, l);
        // Transform "" + kIdentity + ""
        if (matchlen == l) {
          AddMatch(id, l, l, matches);
          found_match = true;
        }
        // Transfroms "" + kOmitLast1 + "" and "" + kOmitLast1 + "ing "
        if (matchlen >= l - 1) {
          AddMatch(id + 12 * n, l - 1, l, matches);
          if (data[data_off+l - 1] == 'i'.charCodeAt(0) && data[data_off+l] == 'n'.charCodeAt(0) && data[data_off+l + 1] == 'g'.charCodeAt(0) &&
              data[data_off+l + 2] == ' '.charCodeAt(0)) {
            AddMatch(id + 49 * n, l + 3, l, matches);
          }
          found_match = true;
        }
        // Transform "" + kOmitLastN + "" (N = 2 .. 9)
        var minlen:Int = Std.int(Math.max(min_length, l - 9));
        var maxlen:Int = Std.int(Math.min(matchlen, l - 2));
        for (len in minlen...maxlen+1) {
          AddMatch(id + kOmitLastNTransforms[l - len] * n, len, l, matches);
          found_match = true;
        }
        if (matchlen < l) {
          continue;
        }
        var s:Vector<UInt> = data;
		var s_off:Int = data_off+l;
        // Transforms "" + kIdentity + <suffix>
        if (s[s_off+0] == ' '.charCodeAt(0)) {
          AddMatch(id + n, l + 1, l, matches);
          if (s[s_off+1] == 'a'.charCodeAt(0)) {
            if (s[s_off+2] == ' '.charCodeAt(0)) {
              AddMatch(id + 28 * n, l + 3, l, matches);
            } else if (s[s_off+2] == 's'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 46 * n, l + 4, l, matches);
            } else if (s[s_off+2] == 't'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 60 * n, l + 4, l, matches);
            } else if (s[s_off+2] == 'n'.charCodeAt(0)) {
              if (s[s_off+3] == 'd'.charCodeAt(0) && s[s_off+4] == ' '.charCodeAt(0)) {
                AddMatch(id + 10 * n, l + 5, l, matches);
              }
            }
          } else if (s[s_off+1] == 'b'.charCodeAt(0)) {
            if (s[s_off+2] == 'y'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
              AddMatch(id + 38 * n, l + 4, l, matches);
          }
          } else if (s[s_off+1] == 'i'.charCodeAt(0)) {
            if (s[s_off+2] == 'n'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 16 * n, l + 4, l, matches);
            } else if (s[s_off+2] == 's'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 47 * n, l + 4, l, matches);
            }
          } else if (s[s_off+1] == 'f'.charCodeAt(0)) {
            if (s[s_off+2] == 'o'.charCodeAt(0)) {
              if (s[s_off+3] == 'r'.charCodeAt(0) && s[s_off+4] == ' '.charCodeAt(0)) {
                AddMatch(id + 25 * n, l + 5, l, matches);
              }
            } else if (s[s_off+2] == 'r'.charCodeAt(0)) {
              if (s[s_off+3] == 'o'.charCodeAt(0) && s[s_off+4] == 'm'.charCodeAt(0) && s[s_off+5] == ' '.charCodeAt(0)) {
                AddMatch(id + 37 * n, l + 6, l, matches);
              }
            }
          } else if (s[s_off+1] == 'o'.charCodeAt(0)) {
            if (s[s_off+2] == 'f'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 8 * n, l + 4, l, matches);
            } else if (s[s_off+2] == 'n'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 45 * n, l + 4, l, matches);
            }
          } else if (s[s_off+1] == 'n'.charCodeAt(0)) {
            if (s[s_off+2] == 'o'.charCodeAt(0) && s[s_off+3] == 't'.charCodeAt(0) && s[s_off+4] == ' '.charCodeAt(0)) {
              AddMatch(id + 80 * n, l + 5, l, matches);
            }
          } else if (s[s_off+1] == 't'.charCodeAt(0)) {
            if (s[s_off+2] == 'h'.charCodeAt(0)) {
              if (s[s_off+3] == 'e'.charCodeAt(0)) {
                if (s[s_off+4] == ' '.charCodeAt(0)) AddMatch(id + 5 * n, l + 5, l, matches);
              } else if (s[s_off+3] == 'a'.charCodeAt(0)) {
                if (s[s_off+4] == 't'.charCodeAt(0) && s[s_off+5] == ' '.charCodeAt(0)) {
                  AddMatch(id + 29 * n, l + 6, l, matches);
                }
              }
            } else if (s[s_off+2] == 'o'.charCodeAt(0)) {
              if (s[s_off+3] == ' '.charCodeAt(0)) AddMatch(id + 17 * n, l + 4, l, matches);
            }
          } else if (s[s_off+1] == 'w'.charCodeAt(0)) {
            if (s[s_off+2] == 'i'.charCodeAt(0) && s[s_off+3] == 't'.charCodeAt(0) && s[s_off+4] == 'h'.charCodeAt(0) && s[s_off+5] == ' '.charCodeAt(0)) {
              AddMatch(id + 35 * n, l + 6, l, matches);
            }
          }
        } else if (s[s_off+0] == '"'.charCodeAt(0)) {
          AddMatch(id + 19 * n, l + 1, l, matches);
          if (s[s_off+1] == '>'.charCodeAt(0)) {
            AddMatch(id + 21 * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == '.'.charCodeAt(0)) {
          AddMatch(id + 20 * n, l + 1, l, matches);
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + 31 * n, l + 2, l, matches);
            if (s[s_off+2] == 'T'.charCodeAt(0) && s[s_off+3] == 'h'.charCodeAt(0)) {
              if (s[s_off+4] == 'e'.charCodeAt(0)) {
                if (s[s_off+5] == ' '.charCodeAt(0)) AddMatch(id + 43 * n, l + 6, l, matches);
              } else if (s[s_off+4] == 'i'.charCodeAt(0)) {
                if (s[s_off+5] == 's'.charCodeAt(0) && s[s_off+6] == ' '.charCodeAt(0)) {
                  AddMatch(id + 75 * n, l + 7, l, matches);
                }
              }
            }
          }
        } else if (s[s_off+0] == ','.charCodeAt(0)) {
          AddMatch(id + 76 * n, l + 1, l, matches);
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + 14 * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == '\n'.charCodeAt(0)) {
          AddMatch(id + 22 * n, l + 1, l, matches);
          if (s[s_off+1] == '\t'.charCodeAt(0)) {
            AddMatch(id + 50 * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == ']'.charCodeAt(0)) {
          AddMatch(id + 24 * n, l + 1, l, matches);
        } else if (s[s_off+0] == '\''.charCodeAt(0)) {
          AddMatch(id + 36 * n, l + 1, l, matches);
        } else if (s[s_off+0] == ':'.charCodeAt(0)) {
          AddMatch(id + 51 * n, l + 1, l, matches);
        } else if (s[s_off+0] == '('.charCodeAt(0)) {
          AddMatch(id + 57 * n, l + 1, l, matches);
        } else if (s[s_off+0] == '='.charCodeAt(0)) {
          if (s[s_off+1] == '"'.charCodeAt(0)) {
            AddMatch(id + 70 * n, l + 2, l, matches);
          } else if (s[s_off+1] == '\''.charCodeAt(0)) {
            AddMatch(id + 86 * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == 'a'.charCodeAt(0)) {
          if (s[s_off+1] == 'l'.charCodeAt(0) && s[s_off+2] == ' '.charCodeAt(0)) {
            AddMatch(id + 84 * n, l + 3, l, matches);
          }
        } else if (s[s_off+0] == 'e'.charCodeAt(0)) {
          if (s[s_off+1] == 'd'.charCodeAt(0)) {
            if (s[s_off+2] == ' '.charCodeAt(0)) AddMatch(id + 53 * n, l + 3, l, matches);
          } else if (s[s_off+1] == 'r'.charCodeAt(0)) {
            if (s[s_off+2] == ' '.charCodeAt(0)) AddMatch(id + 82 * n, l + 3, l, matches);
          } else if (s[s_off+1] == 's'.charCodeAt(0)) {
            if (s[s_off+2] == 't'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
              AddMatch(id + 95 * n, l + 4, l, matches);
            }
          }
        } else if (s[s_off+0] == 'f'.charCodeAt(0)) {
          if (s[s_off+1] == 'u'.charCodeAt(0) && s[s_off+2] == 'l'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
            AddMatch(id + 90 * n, l + 4, l, matches);
          }
        } else if (s[s_off+0] == 'i'.charCodeAt(0)) {
          if (s[s_off+1] == 'v'.charCodeAt(0)) {
            if (s[s_off+2] == 'e'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
            AddMatch(id + 92 * n, l + 4, l, matches);
            }
          } else if (s[s_off+1] == 'z'.charCodeAt(0)) {
            if (s[s_off+2] == 'e'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
              AddMatch(id + 100 * n, l + 4, l, matches);
            }
          }
        } else if (s[s_off+0] == 'l'.charCodeAt(0)) {
          if (s[s_off+1] == 'e'.charCodeAt(0)) {
            if (s[s_off+2] == 's'.charCodeAt(0) && s[s_off+3] == 's'.charCodeAt(0) && s[s_off+4] == ' '.charCodeAt(0)) {
              AddMatch(id + 93 * n, l + 5, l, matches);
            }
          } else if (s[s_off+1] == 'y'.charCodeAt(0)) {
            if (s[s_off+2] == ' '.charCodeAt(0)) AddMatch(id + 61 * n, l + 3, l, matches);
          }
        } else if (s[s_off+0] == 'o'.charCodeAt(0)) {
          if (s[s_off+1] == 'u'.charCodeAt(0) && s[s_off+2] == 's'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
            AddMatch(id + 106 * n, l + 4, l, matches);
          }
        }
      } else {
        // Set t=0 for kUppercaseFirst and t=1 for kUppercaseAll transform.
        var t:Int = w.transform - 10;
        if (!IsMatch(w, data, data_off)) {
          continue;
        }
        // Transform "" + kUppercase{First,All} + ""
        AddMatch(id + (t>0 ? 44 : 9) * n, l, l, matches);
        found_match = true;
        // Transforms "" + kUppercase{First,All} + <suffix>
        var s:Vector<UInt> = data;
		var s_off:Int = data_off+l;
        if (s[s_off+0] == ' '.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 68 : 4) * n, l + 1, l, matches);
        } else if (s[s_off+0] == '"'.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 87 : 66) * n, l + 1, l, matches);
          if (s[s_off+1] == '>'.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 97 : 69) * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == '.'.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 101 : 79) * n, l + 1, l, matches);
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 114 : 88) * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == ','.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 112 : 99) * n, l + 1, l, matches);
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 107 : 58) * n, l + 2, l, matches);
          }
        } else if (s[s_off+0] == '\''.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 94 : 74) * n, l + 1, l, matches);
        } else if (s[s_off+0] == '('.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 113 : 78) * n, l + 1, l, matches);
        } else if (s[s_off+0] == '='.charCodeAt(0)) {
          if (s[s_off+1] == '"'.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 105 : 104) * n, l + 2, l, matches);
          } else if (s[s_off+1] == '\''.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 116 : 108) * n, l + 2, l, matches);
          }
        }
      }
    }
  }
  // Transforms with prefixes " " and "."
  if (data[data_off+0] == ' '.charCodeAt(0) || data[data_off+0] == '.'.charCodeAt(0)) {
    var is_space:Bool = (data[data_off+0] == ' '.charCodeAt(0));
    key = Hash_1(data,data_off+1);
    bucket = kStaticDictionaryBuckets[key];
    var num:Int = bucket & 0xff;
    var offset:Int = bucket >> 8;
    for (i in 0...num) {
      var w:DictWord = kStaticDictionaryWords[offset + i];
      var l:Int = w.len;
      var n:Int = 1 << kBrotliDictionarySizeBitsByLength[l];
      var id:Int = w.idx;
      if (w.transform == 0) {
        if (!IsMatch(w, data,data_off+1)) {
          continue;
        }
        // Transforms " " + kIdentity + "" and "." + kIdentity + ""
        AddMatch(id + (is_space ? 6 : 32) * n, l + 1, l, matches);
        found_match = true;
        // Transforms " " + kIdentity + <suffix> and "." + kIdentity + <suffix>
        var s:Vector<UInt> = data;
		var s_off:Int = data_off+l + 1;
        if (s[s_off+0] == ' '.charCodeAt(0)) {
          AddMatch(id + (is_space ? 2 : 77) * n, l + 2, l, matches);
        } else if (s[s_off+0] == '('.charCodeAt(0)) {
          AddMatch(id + (is_space ? 89 : 67) * n, l + 2, l, matches);
        } else if (is_space) {
          if (s[s_off+0] == ','.charCodeAt(0)) {
            AddMatch(id + 103 * n, l + 2, l, matches);
            if (s[s_off+1] == ' '.charCodeAt(0)) {
              AddMatch(id + 33 * n, l + 3, l, matches);
            }
          } else if (s[s_off+0] == '.'.charCodeAt(0)) {
            AddMatch(id + 71 * n, l + 2, l, matches);
            if (s[s_off+1] == ' '.charCodeAt(0)) {
              AddMatch(id + 52 * n, l + 3, l, matches);
            }
          } else if (s[s_off+0] == '='.charCodeAt(0)) {
            if (s[s_off+1] == '"'.charCodeAt(0)) {
              AddMatch(id + 81 * n, l + 3, l, matches);
            } else if (s[s_off+1] == '\''.charCodeAt(0)) {
              AddMatch(id + 98 * n, l + 3, l, matches);
            }
          }
        }
      } else if (is_space) {
        // Set t=0 for kUppercaseFirst and t=1 for kUppercaseAll transform.
        var t:Int = w.transform - 10;
        if (!IsMatch(w, data,data_off+1)) {
          continue;
        }
        // Transforms " " + kUppercase{First,All} + ""
        AddMatch(id + (t>0 ? 85 : 30) * n, l + 1, l, matches);
        found_match = true;
        // Transforms " " + kUppercase{First,All} + <suffix>
        var s:Vector<UInt> = data;
		var s_off:Int = data_off+l + 1;
        if (s[s_off+0] == ' '.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 83 : 15) * n, l + 2, l, matches);
        } else if (s[s_off+0] == ','.charCodeAt(0)) {
          if (t == 0) {
            AddMatch(id + 109 * n, l + 2, l, matches);
        }
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 111 : 65) * n, l + 3, l, matches);
          }
        } else if (s[s_off+0] == '.'.charCodeAt(0)) {
          AddMatch(id + (t>0 ? 115 : 96) * n, l + 2, l, matches);
          if (s[s_off+1] == ' '.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 117 : 91) * n, l + 3, l, matches);
          }
        } else if (s[s_off+0] == '='.charCodeAt(0)) {
          if (s[s_off+1] == '"'.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 110 : 118) * n, l + 3, l, matches);
          } else if (s[s_off+1] == '\''.charCodeAt(0)) {
            AddMatch(id + (t>0 ? 119 : 120) * n, l + 3, l, matches);
          }
        }
      }
    }
  }
  // Transforms with prefixes "e ", "s ", ", " and "\xc2\xa0"
  if ((data[data_off+1] == ' '.charCodeAt(0) &&
       (data[data_off+0] == 'e'.charCodeAt(0) || data[data_off+0] == 's'.charCodeAt(0) || data[data_off+0] == ','.charCodeAt(0))) ||
      (data[data_off+0] == 0xc2 && data[data_off+1] == 0xa0)) {
    key = Hash_1(data,data_off+2);
    bucket = kStaticDictionaryBuckets[key];
    var num:Int = bucket & 0xff;
    var offset:Int = bucket >> 8;
    for (i in 0...num) {
      var w:DictWord = kStaticDictionaryWords[offset + i];
      var l:Int = w.len;
      var n:Int = 1 << kBrotliDictionarySizeBitsByLength[l];
      var id:Int = w.idx;
      if (w.transform == 0 && IsMatch(w, data,data_off+2)) {
        if (data[data_off+0] == 0xc2) {
          AddMatch(id + 102 * n, l + 2, l, matches);
          found_match = true;
        } else if (data[data_off+l + 2] == ' '.charCodeAt(0)) {
          var t:Int = data[data_off+0] == 'e'.charCodeAt(0) ? 18 : (data[data_off+0] == 's'.charCodeAt(0) ? 7 : 13);
          AddMatch(id + t * n, l + 3, l, matches);
          found_match = true;
        }
      }
    }
  }
  // Transforms with prefixes " the " and ".com/"
  if ((data[data_off+0] == ' '.charCodeAt(0) && data[data_off+1] == 't'.charCodeAt(0) && data[data_off+2] == 'h'.charCodeAt(0) &&
       data[data_off+3] == 'e'.charCodeAt(0) && data[data_off+4] == ' '.charCodeAt(0)) ||
      (data[data_off+0] == '.'.charCodeAt(0) && data[data_off+1] == 'c'.charCodeAt(0) && data[data_off+2] == 'o'.charCodeAt(0) &&
       data[data_off+3] == 'm'.charCodeAt(0) && data[data_off+4] == '/'.charCodeAt(0))) {
    key = Hash_1(data,data_off+5);
    bucket = kStaticDictionaryBuckets[key];
    var num:Int = bucket & 0xff;
    var offset:Int = bucket >> 8;
    for (i in 0...num) {
      var w:DictWord = kStaticDictionaryWords[offset + i];
      var l:Int = w.len;
      var n:Int = 1 << kBrotliDictionarySizeBitsByLength[l];
      var id:Int = w.idx;
      if (w.transform == 0 && IsMatch(w, data,data_off+5)) {
        AddMatch(id + (data[data_off+0] == ' '.charCodeAt(0) ? 41 : 72) * n, l + 5, l, matches);
        found_match = true;
        var s:Vector<UInt> = data;
		var s_off:Int = data_off+l + 5;
        if (data[data_off+0] == ' '.charCodeAt(0)) {
          if (s[s_off+0] == ' '.charCodeAt(0) && s[s_off+1] == 'o'.charCodeAt(0) && s[s_off+2] == 'f'.charCodeAt(0) && s[s_off+3] == ' '.charCodeAt(0)) {
            AddMatch(id + 62 * n, l + 9, l, matches);
            if (s[s_off+4] == 't'.charCodeAt(0) && s[s_off+5] == 'h'.charCodeAt(0) && s[s_off+6] == 'e'.charCodeAt(0) && s[s_off+7] == ' '.charCodeAt(0)) {
              AddMatch(id + 73 * n, l + 13, l, matches);
            }
          }
        }
      }
    }
  }
  return found_match;
}
	public function new() 
	{
		
	}
	
}
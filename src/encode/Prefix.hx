package encode;
import haxe.ds.Vector;
import encode.Fast_log.*;
import encode.prefix.PrefixCodeRange;

/**
 * ...
 * @author 
 */
class Prefix
{

static public inline var kNumInsertLenPrefixes:Int = 24;
static public inline var kNumCopyLenPrefixes:Int = 24;
static public inline var kNumCommandPrefixes:Int = 704;
static public inline var kNumBlockLenPrefixes:Int = 26;
static public inline var kNumDistanceShortCodes:Int = 16;
static public inline var kNumDistancePrefixes:Int = 520;

static public var kBlockLengthPrefixCode:Array<PrefixCodeRange> = [//[kNumBlockLenPrefixes]
  new PrefixCodeRange(   1,  2), new PrefixCodeRange(    5,  2), new PrefixCodeRange(  9,   2), new PrefixCodeRange(  13,  2),
  new PrefixCodeRange(  17,  3), new PrefixCodeRange(   25,  3), new PrefixCodeRange(  33,  3), new PrefixCodeRange(  41,  3),
  new PrefixCodeRange(  49,  4), new PrefixCodeRange(   65,  4), new PrefixCodeRange(  81,  4), new PrefixCodeRange(  97,  4),
  new PrefixCodeRange( 113,  5), new PrefixCodeRange(  145,  5), new PrefixCodeRange( 177,  5), new PrefixCodeRange( 209,  5),
  new PrefixCodeRange( 241,  6), new PrefixCodeRange(  305,  6), new PrefixCodeRange( 369,  7), new PrefixCodeRange( 497,  8),
  new PrefixCodeRange( 753,  9), new PrefixCodeRange( 1265, 10), new PrefixCodeRange(2289, 11), new PrefixCodeRange(4337, 12),
  new PrefixCodeRange(8433, 13), new PrefixCodeRange(16625, 24)
];

static public function GetBlockLengthPrefixCode(len:Int,// inline
                                     code:Vector<Int>, code_off:Int, n_extra:Vector<Int>, n_extra_off:Int, extra:Vector<Int>, extra_off:Int) {
  code[code_off+0] = 0;
  while (code[code_off] < 25 && len >= kBlockLengthPrefixCode[code[code_off] + 1].offset) {
    code[code_off]+=1;
  }
  n_extra[n_extra_off] = kBlockLengthPrefixCode[code[code_off]].nbits;
  extra[extra_off] = len - kBlockLengthPrefixCode[code[code_off]].offset;
}

static public function PrefixEncodeCopyDistance(distance_code:Int,// inline
                                     num_direct_codes:Int,
                                     postfix_bits:Int,
                                     code:Array<UInt>,
                                     extra_bits:Array<UInt>) {
  if (distance_code < kNumDistanceShortCodes + num_direct_codes) {
    code[0] = distance_code;
    extra_bits[0] = 0;
    return;
  }
  distance_code -= kNumDistanceShortCodes + num_direct_codes;
  distance_code += (1 << (postfix_bits + 2));
  var bucket:Int = Log2Floor(distance_code) - 1;
  var postfix_mask:Int = (1 << postfix_bits) - 1;
  var postfix:Int = distance_code & postfix_mask;
  var prefix:Int = (distance_code >> bucket) & 1;
  var offset:Int = (2 + prefix) << bucket;
  var nbits:Int = bucket - postfix_bits;
  code[0] = kNumDistanceShortCodes + num_direct_codes +
      ((2 * (nbits - 1) + prefix) << postfix_bits) + postfix;
  extra_bits[0] = (nbits << 24) | ((distance_code - offset) >> postfix_bits);
}

	public function new() 
	{
		
	}
	
}
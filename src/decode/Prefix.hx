package decode;
import decode.prefix.PrefixCodeRange;

/**
 * ...
 * @author 
 */
class Prefix
{

	public static var kBlockLengthPrefixCode:Array<PrefixCodeRange> = [
	  new PrefixCodeRange(   1,  2), new PrefixCodeRange(    5,  2), new PrefixCodeRange(  9,   2), new PrefixCodeRange(  13,  2),
	  new PrefixCodeRange(  17,  3), new PrefixCodeRange(   25,  3), new PrefixCodeRange(  33,  3), new PrefixCodeRange(  41,  3),
	  new PrefixCodeRange(  49,  4), new PrefixCodeRange(   65,  4), new PrefixCodeRange(  81,  4), new PrefixCodeRange(  97,  4),
	  new PrefixCodeRange( 113,  5), new PrefixCodeRange(  145,  5), new PrefixCodeRange( 177,  5), new PrefixCodeRange( 209,  5),
	  new PrefixCodeRange( 241,  6), new PrefixCodeRange(  305,  6), new PrefixCodeRange( 369,  7), new PrefixCodeRange( 497,  8),
	  new PrefixCodeRange( 753,  9), new PrefixCodeRange( 1265, 10), new PrefixCodeRange(2289, 11), new PrefixCodeRange(4337, 12),
	  new PrefixCodeRange(8433, 13), new PrefixCodeRange(16625, 24)
	];

public static var kInsertLengthPrefixCode:Array<PrefixCodeRange> = [
  new PrefixCodeRange(   0,  0), new PrefixCodeRange(   1,  0), new PrefixCodeRange(  2,   0), new PrefixCodeRange(    3,  0),
  new PrefixCodeRange(   4,  0), new PrefixCodeRange(   5,  0), new PrefixCodeRange(  6,   1), new PrefixCodeRange(    8,  1),
  new PrefixCodeRange(  10,  2), new PrefixCodeRange(  14,  2), new PrefixCodeRange( 18,   3), new PrefixCodeRange(   26,  3),
  new PrefixCodeRange(  34,  4), new PrefixCodeRange(  50,  4), new PrefixCodeRange( 66,   5), new PrefixCodeRange(   98,  5),
  new PrefixCodeRange( 130,  6), new PrefixCodeRange( 194,  7), new PrefixCodeRange( 322,  8), new PrefixCodeRange(  578,  9),
  new PrefixCodeRange(1090, 10), new PrefixCodeRange(2114, 12), new PrefixCodeRange(6210, 14), new PrefixCodeRange(22594, 24)
];

public static var kCopyLengthPrefixCode:Array<PrefixCodeRange> = [
  new PrefixCodeRange(  2, 0), new PrefixCodeRange(   3,  0), new PrefixCodeRange(   4,  0), new PrefixCodeRange(   5,  0),
  new PrefixCodeRange(  6, 0), new PrefixCodeRange(   7,  0), new PrefixCodeRange(   8,  0), new PrefixCodeRange(   9,  0),
  new PrefixCodeRange( 10, 1), new PrefixCodeRange(  12,  1), new PrefixCodeRange(  14,  2), new PrefixCodeRange(  18,  2),
  new PrefixCodeRange( 22, 3), new PrefixCodeRange(  30,  3), new PrefixCodeRange(  38,  4), new PrefixCodeRange(  54,  4),
  new PrefixCodeRange( 70, 5), new PrefixCodeRange( 102,  5), new PrefixCodeRange( 134,  6), new PrefixCodeRange( 198,  7),
  new PrefixCodeRange(326, 8), new PrefixCodeRange( 582,  9), new PrefixCodeRange(1094, 10), new PrefixCodeRange(2118, 24)
];

public static var kInsertRangeLut:Array<Int> = [
  0, 0, 8, 8, 0, 16, 8, 16, 16
];

public static var kCopyRangeLut:Array<Int> = [
  0, 8, 0, 8, 16, 0, 16, 8, 16
];

	public function new() 
	{
		
	}
	
}
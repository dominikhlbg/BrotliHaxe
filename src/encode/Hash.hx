package encode;
import haxe.ds.Vector;
import encode.Port.*;
import encode.Fast_log.*;

/**
 * ...
 * @author 
 */
class Hash
{
public static var kDistanceCacheIndex:Array<Int> = [
  0, 1, 2, 3, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
];
public static var kDistanceCacheOffset:Array<Int> = [
  0, 0, 0, 0, -1, 1, -2, 2, -3, 3, -1, 1, -2, 2, -3, 3
];

// kHashMul32 multiplier has these properties:
// * The multiplier must be odd. Otherwise we may lose the highest bit.
// * No long streaks of 1s or 0s.
// * There is no effort to ensure that it is a prime, the oddity is enough
//   for this use.
// * The number has been tuned heuristically against compression benchmarks.
static var kHashMul32 = 0x1e35a7bd;

public static function Hash_(kShiftBits:Int, data:Vector<UInt>, data_off:Int):UInt {
#if !php
  var h:UInt = (BROTLI_UNALIGNED_LOAD32(data, data_off) * kHashMul32) & 0xffffffff;
#else  
  var h:UInt = (BROTLI_UNALIGNED_LOAD32(data, data_off) * kHashMul32) >>>32;
#end
  // The higher bits contain more mixture from the multiplication,
  // so we take our results from there.
  return h >>> (32 - kShiftBits);
}

// Usually, we always choose the longest backward reference. This function
// allows for the exception of that rule.
//
// If we choose a backward reference that is further away, it will
// usually be coded with more bits. We approximate this by assuming
// log2(distance). If the distance can be expressed in terms of the
// last four distances, we use some heuristic constants to estimate
// the bits cost. For the first up to four literals we use the bit
// cost of the literals from the literal cost model, after that we
// use the average bit cost of the cost model.
//
// This function is used to sometimes discard a longer backward reference
// when it is not much longer and the bit cost for encoding it is more
// than the saved literals.
public static function BackwardReferenceScore(copy_length:Int,// inline
                                     backward_reference_offset:Int):Float {
  return 5.4 * copy_length - 1.20 * Log2Floor(backward_reference_offset);
}

public static function BackwardReferenceScoreUsingLastDistance(copy_length:Int,// inline
                                                      distance_short_code:Int):Float {
  var kDistanceShortCodeBitCost:Array<Float> = [
    -0.6, 0.95, 1.17, 1.27,
    0.93, 0.93, 0.96, 0.96, 0.99, 0.99,
    1.05, 1.05, 1.15, 1.15, 1.25, 1.25
  ];
  return 5.4 * copy_length - kDistanceShortCodeBitCost[distance_short_code];
}

// The maximum length for which the zopflification uses distinct distances.
static public inline var kMaxZopfliLen:Int = 325;


	public function new() 
	{
		
	}
	
}
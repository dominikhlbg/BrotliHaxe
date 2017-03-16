package encode;
import haxe.ds.Vector;
import encode.Port.*;

/**
 * ...
 * @author 
 */
class Find_match_length
{
	public static function FindMatchLengthWithLimit(s1:Vector<UInt>,s1_off:Int,// inline
                                           s2:Vector<UInt>,s2_off:Int,
                                           limit:Int):Int {
  var matched:Int = 0;
  var s2_limit:Vector<UInt> = s2;var s2_limit_off:Int =s2_off + limit;
  var s2_ptr:Vector<UInt> = s2;var s2_ptr_off:Int = s2_off;
  // Find out how long the match is. We loop over the data 32 bits at a
  // time until we find a 32-bit block that doesn't match; then we find
  // the first non-matching bit and use that to calculate the total
  // length of the match.
  while (s2_ptr_off <= s2_limit_off - 4 &&
         BROTLI_UNALIGNED_LOAD32(s2_ptr,s2_ptr_off) ==
         BROTLI_UNALIGNED_LOAD32(s1,s1_off + matched)) {
    s2_ptr_off += 4;
    matched += 4;
  }
  while ((s2_ptr_off < s2_limit_off) && (s1[s1_off+matched] == s2_ptr[s2_ptr_off])) {
    ++s2_ptr_off;
    ++matched;
  }
  return matched;
}

	public function new() 
	{
		
	}
	
}
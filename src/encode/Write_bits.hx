package encode;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class Write_bits
{

// This function writes bits into bytes in increasing addresses, and within
// a byte least-significant-bit first.
//
// The function can write up to 56 bits in one go with WriteBits
// Example: let's assume that 3 bits (Rs below) have been written already:
//
// BYTE-0     BYTE+1       BYTE+2
//
// 0000 0RRR    0000 0000    0000 0000
//
// Now, we could write 5 or less bits in MSB by just sifting by 3
// and OR'ing to BYTE-0.
//
// For n bits, we take the last 5 bits, OR that with high bits in BYTE-0,
// and locate the rest in BYTE+1, BYTE+2, etc.
static public function WriteBits(n_bits:Int,// inline
                      bits:UInt,
                      pos:Array<Int>,
                      array:Vector<UInt>) {
  //assert(bits < 1ULL << n_bits);
  // implicit & 0xff is assumed for uint8_t arithmetics
  var array_pos:Vector<UInt> = array;
  var array_pos_off:Int = pos[0] >> 3;
  var bits_reserved_in_first_byte:Int = (pos[0] & 7);
  bits <<= bits_reserved_in_first_byte;
  array_pos[array_pos_off++] |= bits&0xff;
  var bits_left_to_write = n_bits - 8 + bits_reserved_in_first_byte;
  while (bits_left_to_write >= 1) {
    bits >>= 8;
    array_pos[array_pos_off++] = bits&0xff;
	bits_left_to_write -= 8;
  }
  array_pos[array_pos_off] = 0;
  pos[0] += n_bits;
}

static public function WriteBitsPrepareStorage(pos:Int, array:Vector<UInt>) {// inline
  array[pos >> 3] = 0;
}
	public function new() 
	{
		
	}
	
}
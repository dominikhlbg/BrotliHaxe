package decode;
import FunctionMalloc;
import decode.huffman.HuffmanCode;
import decode.huffman.HuffmanTreeGroup;
import haxe.ds.Vector;
import decode.huffman.*;
import FunctionMalloc.*;
import decode.Port.*;

/**
 * ...
 * @author ...
 */
class Huffman
{
public static inline var BROTLI_HUFFMAN_MAX_TABLE_SIZE = 1080;

public static inline var MAX_LENGTH = 15;

/* For current format this constant equals to kNumInsertAndCopyCodes */
public static inline var MAX_CODE_LENGTHS_SIZE = 704;

/* Returns reverse(reverse(key, len) + 1, len), where reverse(key, len) is the
   bit-wise reversal of the len least significant bits of key. */
public static function GetNextKey(key:Int, len:Int):Int {
  var step:Int = 1 << (len - 1);
  while ((key & step)>0) {
    step >>= 1;
  }
  return (key & (step - 1)) + step;
}

//44
/* Stores code in table[0], table[step], table[2*step], ..., table[end] */
/* Assumes that end is an integer multiple of step */
public static function ReplicateValue(table:Vector<HuffmanCode>,
                                         table_off:Int,
                                         step:Int, end:Int,
                                         code:HuffmanCode) {
  do {
    end -= step;
    table[table_off+end] = new HuffmanCode(code.bits,code.value);//TODO:
  } while (end > 0);
}

/* Returns the table width of the next 2nd level table. count is the histogram
   of bit lengths for the remaining symbols, len is the code length of the next
   processed symbol */
public static function NextTableBitSize(count:Vector<Int>,
                                          len:Int, root_bits:Int) {
  var left:Int = 1 << (len - root_bits);
  while (len < MAX_LENGTH) {
    left -= count[len];
    if (left <= 0) break;
    ++len;
    left <<= 1;
  }
  return len - root_bits;
}

//70
public static function BrotliBuildHuffmanTable(root_table:Vector<HuffmanCode>,
							root_table_off:Int,
                            root_bits:Int,
                            code_lengths:Vector<UInt>,//const uint8_t* const 
                            code_lengths_size:Int):Int {
  var code:HuffmanCode=new HuffmanCode(0,0);    /* current table entry */
  var table:Vector<HuffmanCode>;//*  /* next available space in table */
  var table_off:Int;//  /* next available space in table */
  var len:Int;             /* current code length */
  var symbol:Int;          /* symbol index in original or sorted table */
  var key:Int;             /* reversed prefix code */
  var step:Int;            /* step size to replicate values in current table */
  var low:Int;             /* low bits for current root entry */
  var mask:Int;            /* mask for low bits */
  var table_bits:Int;      /* key length of current table */
  var table_size:Int;      /* size of current table */
  var total_size:Int;      /* sum of root table size and 2nd level table sizes */
  var sorted:Vector<Int>=mallocInt(MAX_CODE_LENGTHS_SIZE);  /* symbols sorted by code length */
  var count:Vector<Int>=mallocInt(MAX_LENGTH + 1);// = { 0 };  /* number of codes of each length */
  var offset:Vector<Int>=mallocInt(MAX_LENGTH + 1);  /* offsets in sorted table for each length */

  if (PREDICT_FALSE(code_lengths_size > MAX_CODE_LENGTHS_SIZE)) {
    return 0;
  }

  /* build histogram of code lengths */
  for (symbol in 0...code_lengths_size) {
    count[code_lengths[symbol]]+=1;
  }

  /* generate offsets into sorted symbol table by code length */
  offset[1] = 0;
  for (len in 1...MAX_LENGTH) {
    offset[len + 1] = offset[len] + count[len];
  }

  /* sort symbols by length, by symbol order within each length */
  for (symbol in 0...code_lengths_size) {
    if (code_lengths[symbol] != 0) {
      sorted[offset[code_lengths[symbol]]] = symbol;
	  offset[code_lengths[symbol]] += 1;//WORKS?
    }
  }

  table = root_table;
  table_off = root_table_off;
  table_bits = root_bits;
  table_size = 1 << table_bits;
  total_size = table_size;

  /* special case code with only one value */
  if (offset[MAX_LENGTH] == 1) {
    code.bits = 0;
    code.value = sorted[0];
    for (key in 0...total_size) {
      table[table_off+key] = code;
    }
    return total_size;
  }

  /* fill in root table */
  key = 0;
  symbol = 0;
  step = 2; 
  for (len in 1...(root_bits+1)) {
    while (count[len] > 0) {//TODO:LOOP WORKS?
      code.bits = (len);
      code.value = sorted[symbol++];
      ReplicateValue(table,table_off+(key), step, table_size, code);
      key = GetNextKey(key, len);
	  count[len]-=1;
    }
	step <<= 1;
  }

  /* fill in 2nd level tables and add pointers to root table */
  mask = total_size - 1;
  low = -1;
  step = 2;
  for (len in (root_bits + 1)...(MAX_LENGTH+1)) {
    while (count[len] > 0) {
      if ((key & mask) != low) {
        table_off += table_size;
        table_bits = NextTableBitSize(count, len, root_bits);
        table_size = 1 << table_bits;
        total_size += table_size;
        low = key & mask;
        root_table[root_table_off+low].bits = (table_bits + root_bits);
        root_table[root_table_off+low].value = ((table_off - root_table_off) - low);
      }
      code.bits = (len - root_bits);
      code.value = sorted[symbol++];
      ReplicateValue(table,table_off+(key >> root_bits), step, table_size, code);
      key = GetNextKey(key, len);
	  count[len]-=1;
    }
	step <<= 1;
  }

  return total_size;
}

//162
static public function BrotliHuffmanTreeGroupInit(group:HuffmanTreeGroup, alphabet_size:Int,
                                ntrees:Int) {
  group.alphabet_size = alphabet_size;
  group.num_htrees = ntrees;
  group.codes = malloc2(HuffmanCode,
      (ntrees * BROTLI_HUFFMAN_MAX_TABLE_SIZE));//sizeof(HuffmanCode) * (size_t)
  group.htrees = new Array<Vector<HuffmanCode>>();//malloc2(HuffmanCode, ntrees);//(HuffmanCode**)sizeof(HuffmanCode*) * (size_t)
  group.htrees_off = new Array<Int>();//malloc2(HuffmanCode, ntrees);//(HuffmanCode**)sizeof(HuffmanCode*) * (size_t)
}

static public function BrotliHuffmanTreeGroupRelease(group:HuffmanTreeGroup) {
  if (group.codes!=null) {
    //free(group.codes);
  }
  if (group.htrees!=null) {
    //free(group.htrees);
  }
}

	public function new() 
	{
		
	}
	
}
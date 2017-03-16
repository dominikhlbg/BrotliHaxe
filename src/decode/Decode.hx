package decode;
import decode.BitReader;
import decode.Context;
import decode.huffman.HuffmanCode;
import decode.huffman.HuffmanTreeGroup;
import DefaultFunctions;
import haxe.ds.Vector;
import decode.streams.BrotliInput;
import decode.streams.BrotliOutput;
import decode.state.BrotliState;
import decode.State.BrotliStateInit;
import decode.bit_reader.BrotliBitReader;
import decode.BitReader.*;
import FunctionMalloc.*;
import huffman.*;
import decode.Huffman.*;
import DefaultFunctions.*;
import decode.Dictionary.*;
import decode.Streams.*;
import decode.Port.*;
import decode.Prefix.*;
import decode.Context.*;
import decode.Transforms.*;


/**
 * ...
 * @author 
 */
@:enum
abstract BrotliResult(Int) {
	/* Decoding error, e.g. corrupt input or no memory */
	var BROTLI_RESULT_ERROR = 0;
	/* Successfully completely done */
	var BROTLI_RESULT_SUCCESS = 1;
	/* Partially done, but must be called again with more input */
	var BROTLI_RESULT_NEEDS_MORE_INPUT = 2;
	/* Partially done, but must be called again with more output */
	var BROTLI_RESULT_NEEDS_MORE_OUTPUT = 3;
}
class Decode
{
	static inline function BROTLI_FAILURE() {
		return BROTLI_RESULT_ERROR;
	}
	//46
	static inline function BROTLI_LOG_UINT(x) {
		//trace(x);
	}
	static inline function BROTLI_LOG_ARRAY_INDEX(array_name, idx) {
		
	}
	//48
	static inline function BROTLI_LOG(x) {
		trace(x);
	}
	static inline function BROTLI_LOG_UCHAR_VECTOR(v, len) {
		
	}
static public inline var kDefaultCodeLength = 8;
static public inline var kCodeLengthRepeatCode = 16;
static public inline var kNumLiteralCodes = 256;
static public inline var kNumInsertAndCopyCodes = 704;
static public inline var kNumBlockLengthCodes = 26;
static public inline var kLiteralContextBits = 6;
static public inline var kDistanceContextBits = 2;
static public inline var HUFFMAN_TABLE_BITS = 8;
static public inline var HUFFMAN_TABLE_MASK = 0xff;
//64
static public inline var CODE_LENGTH_CODES = 18;
static var kCodeLengthCodeOrder = [//const uint8_t [CODE_LENGTH_CODES]
  1, 2, 3, 4, 0, 5, 17, 6, 16, 7, 8, 9, 10, 11, 12, 13, 14, 15
];
static public inline var NUM_DISTANCE_SHORT_CODES = 16;
static var kDistanceShortCodeIndexOffset:Array<Int> = [//[NUM_DISTANCE_SHORT_CODES]
  3, 2, 1, 0, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2
];

static var kDistanceShortCodeValueOffset:Array<Int> = [//[NUM_DISTANCE_SHORT_CODES]
  0, 0, 0, 0, -1, 1, -2, 2, -3, 3, -1, 1, -2, 2, -3, 3
];

	//77
static function DecodeWindowBits(br:BrotliBitReader):Int {
  var n:Int;
  if (BrotliReadBits(br, 1) == 0) {
    return 16;
  }
  n = BrotliReadBits(br, 3);
  if (n > 0) {
    return 17 + n;
  }
  n = BrotliReadBits(br, 3);
  if (n > 0) {
    return 8 + n;
  }
  return 17;
}
//93
/* Decodes a number in the range [0..255], by reading 1 - 11 bits. */
static function DecodeVarLenUint8(br:BrotliBitReader):Int {
  if (BrotliReadBits(br, 1)==1) {
    var nbits:Int = BrotliReadBits(br, 3);
    if (nbits == 0) {
      return 1;
    } else {
      return BrotliReadBits(br, nbits) + (1 << nbits);
    }
  }
  return 0;
}

//106
/* Advances the bit reader position to the next byte boundary and verifies
   that any skipped bits are set to zero. */
static function JumpToByteBoundary(br:BrotliBitReader):Bool {
  var new_bit_pos:UInt = (br.bit_pos_ + 7) & ~7;// (uint32_t)(~7UL);
  var pad_bits:UInt = BrotliReadBits(br, (new_bit_pos - br.bit_pos_));
  return pad_bits == 0;
}
//114
static function DecodeMetaBlockLength(br:BrotliBitReader,
                                 meta_block_length:Array<Int>,//int* 
                                 input_end:Array<Int>,//int* 
                                 is_metadata:Array<Int>,//int* 
                                 is_uncompressed:Array<Int>//int* 
								 ):Bool {
  var size_nibbles:Int;
  var size_bytes:Int;
  var i:Int;
  input_end[0] = BrotliReadBits(br, 1);
  meta_block_length[0] = 0;
  is_uncompressed[0] = 0;
  is_metadata[0] = 0;
  if (input_end[0]==1 && BrotliReadBits(br, 1)==1) {
    return true;
  }
  size_nibbles = BrotliReadBits(br, 2) + 4;
  if (size_nibbles == 7) {
    is_metadata[0] = 1;
    /* Verify reserved bit. */
    if (BrotliReadBits(br, 1) != 0) {
      return false;
    }
    size_bytes = BrotliReadBits(br, 2);
    if (size_bytes == 0) {
      return true;
    }
    for (i in 0...size_bytes) {
      var next_byte:Int = BrotliReadBits(br, 8);
      if (i + 1 == size_bytes && size_bytes > 1 && next_byte == 0) {
        return false;
      }
      meta_block_length[0] |= next_byte << (i * 8);
    }
  } else {
    for (i in 0...size_nibbles) {
      var next_nibble:Int = BrotliReadBits(br, 4);
      if (i + 1 == size_nibbles && size_nibbles > 4 && next_nibble == 0) {
        return false;
      }
      meta_block_length[0] |= next_nibble << (i * 4);
    }
  }
  ++meta_block_length[0];
  if (!(input_end[0]==1) && !(is_metadata[0]==1)) {
    is_uncompressed[0] = BrotliReadBits(br, 1);
  }
  return true;
}

//163
/* Decodes the next Huffman code from bit-stream. */
static function ReadSymbol(table:Vector<HuffmanCode>,
                                    table_off:Int,
                                    br:BrotliBitReader):Int {
  var nbits:Int;
  BrotliFillBitWindow(br);
  table_off += (br.val_ >> br.bit_pos_) & HUFFMAN_TABLE_MASK;
  if (PREDICT_FALSE(table[table_off].bits > HUFFMAN_TABLE_BITS)) {
    br.bit_pos_ += HUFFMAN_TABLE_BITS;
    nbits = table[table_off].bits - HUFFMAN_TABLE_BITS;
    table_off += table[table_off].value;
    table_off += (br.val_ >> br.bit_pos_) & ((1 << nbits) - 1);
  }
  br.bit_pos_ += table[table_off].bits;
  return table[table_off].value;
}

//195
static function ReadHuffmanCodeLengths(
    code_length_code_lengths:Vector<UInt>,//const uint8_t* 
    num_symbols:Int, code_lengths:Vector<UInt>,//uint8_t* 
    s:BrotliState) {
  var br:BrotliBitReader = s.br;
  //switch (s.sub_state[1]) {
    if(s.sub_state[1]== BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN) {
      s.symbol = 0;
      s.prev_code_len = kDefaultCodeLength;
      s.repeat = 0;
      s.repeat_code_len = 0;
      s.space = 32768;

      if (!(BrotliBuildHuffmanTable(s.table, 0, 5,
                                   code_length_code_lengths,
                                   CODE_LENGTH_CODES)>1)) {
        BROTLI_LOG((
            "[ReadHuffmanCodeLengths] Building code length tree failed: "));
        BROTLI_LOG_UCHAR_VECTOR(code_length_code_lengths, CODE_LENGTH_CODES);
        return BROTLI_FAILURE();
      }
      s.sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS;
	}
      /* No break, continue to next state. */
    if(s.sub_state[1]== BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS) {
      while (s.symbol < num_symbols && s.space > 0) {
        var p:Vector<HuffmanCode> = s.table;//const
        var p_off:Int = 0;//const
        var code_len:UInt;
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        BrotliFillBitWindow(br);
        p_off += (br.val_ >> br.bit_pos_) & 31;
        br.bit_pos_ += p[p_off].bits;
        code_len = p[p_off].value;
        /* We predict that branch will be taken and write value now.
           Even if branch is mispredicted - it works as prefetch. */
        code_lengths[s.symbol] = code_len;
        if (code_len < kCodeLengthRepeatCode) {
          s.repeat = 0;
          if (code_len != 0) {
            s.prev_code_len = code_len;
            s.space -= 32768 >> code_len;
          }
          s.symbol++;
        } else {
          var extra_bits:Int = code_len - 14;//const
          var old_repeat:Int;
          var repeat_delta:Int;
          var new_len:UInt = 0;
          if (code_len == kCodeLengthRepeatCode) {
            new_len =  s.prev_code_len;
          }
          if (s.repeat_code_len != new_len) {
            s.repeat = 0;
            s.repeat_code_len = new_len;
          }
          old_repeat = s.repeat;
          if (s.repeat > 0) {
            s.repeat -= 2;
            s.repeat <<= extra_bits;
          }
          s.repeat += BrotliReadBits(br, extra_bits) + 3;
          repeat_delta = s.repeat - old_repeat;
          if (s.symbol + repeat_delta > num_symbols) {
            return BROTLI_FAILURE();
          }
		  //	&
          memset(code_lengths,(s.symbol), s.repeat_code_len,
                 repeat_delta);
          s.symbol += repeat_delta;
          if (s.repeat_code_len != 0) {
            s.space -= repeat_delta << (15 - s.repeat_code_len);
          }
        }
      }
      if (s.space != 0) {
        BROTLI_LOG(("[ReadHuffmanCodeLengths] s.space = "+s.space+"\n"));
        return BROTLI_FAILURE();
      }
	  //	&
      memset(code_lengths,(s.symbol), 0, (num_symbols - s.symbol));
      s.sub_state[1] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
	}
    //default:
    //  return BROTLI_FAILURE();
  //}
  return BROTLI_FAILURE();
}

//282
static public function ReadHuffmanCode(alphabet_size:Int,
                                    table:Vector<HuffmanCode>,
									table_off:Int,
                                    opt_table_size,//:Array<Int>//int* 
                                    s:BrotliState) {
  var br:BrotliBitReader = s.br;
  var result:BrotliResult = BROTLI_RESULT_SUCCESS;
  var table_size:Int = 0;
  /* State machine */
  while (true) {
    //switch(s.sub_state[1]) {
      if(s.sub_state[1]== BROTLI_STATE_SUB_NONE){
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        /*TODO:s.code_lengths =
            (uint8_t*)BrotliSafeMalloc((uint64_t)alphabet_size,
                                       sizeof( * s.code_lengths));*/
		s.code_lengths = new Vector<UInt>(alphabet_size);
        if (s.code_lengths == null) {
          return BROTLI_FAILURE();
        }
        /* simple_code_or_skip is used as follows:
           1 for simple code;
           0 for no skipping, 2 skips 2 code lengths, 3 skips 3 code lengths */
        s.simple_code_or_skip = BrotliReadBits(br, 2);
        BROTLI_LOG_UINT(s.simple_code_or_skip);
        if (s.simple_code_or_skip == 1) {
          /* Read symbols, codes & code lengths directly. */
          var i:Int;
          var max_bits_counter:Int = alphabet_size - 1;
          var max_bits:Int = 0;
          var symbols = [ 0,0,0,0 ];//[4]
          var num_symbols = BrotliReadBits(br, 2) + 1;//const
          while (max_bits_counter>0) {
            max_bits_counter >>= 1;
            ++max_bits;
          }
          memset(s.code_lengths, 0, 0, alphabet_size);
          for (i in 0...num_symbols) {
            symbols[i] = BrotliReadBits(br, max_bits);
            if (symbols[i] >= alphabet_size) {
              return BROTLI_FAILURE();
            }
            s.code_lengths[symbols[i]] = 2;
          }
          s.code_lengths[symbols[0]] = 1;
          switch (num_symbols) {
            case 1:
            case 3:
              if ((symbols[0] == symbols[1]) ||
                  (symbols[0] == symbols[2]) ||
                  (symbols[1] == symbols[2])) {
                return BROTLI_FAILURE();
              }
            case 2:
              if (symbols[0] == symbols[1]) {
                return BROTLI_FAILURE();
              }
              s.code_lengths[symbols[1]] = 1;
            case 4:
              if ((symbols[0] == symbols[1]) ||
                  (symbols[0] == symbols[2]) ||
                  (symbols[0] == symbols[3]) ||
                  (symbols[1] == symbols[2]) ||
                  (symbols[1] == symbols[3]) ||
                  (symbols[2] == symbols[3])) {
                return BROTLI_FAILURE();
              }
              if (BrotliReadBits(br, 1)==1) {
                s.code_lengths[symbols[2]] = 3;
                s.code_lengths[symbols[3]] = 3;
              } else {
                s.code_lengths[symbols[0]] = 2;
              }
          }
          BROTLI_LOG_UINT(num_symbols);
          s.sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_DONE;
          continue;
        } else {  /* Decode Huffman-coded code lengths. */
          var i:Int;
          var space:Int = 32;
          var num_codes:Int = 0;
          /* Static Huffman code for the code length code lengths */
          var huff:Array<HuffmanCode> = [// [16]
            new HuffmanCode(2, 0), new HuffmanCode(2, 4), new HuffmanCode(2, 3), new HuffmanCode(3, 2), new HuffmanCode(2, 0), new HuffmanCode(2, 4), new HuffmanCode(2, 3), new HuffmanCode(4, 1),
            new HuffmanCode(2, 0), new HuffmanCode(2, 4), new HuffmanCode(2, 3), new HuffmanCode(3, 2), new HuffmanCode(2, 0), new HuffmanCode(2, 4), new HuffmanCode(2, 3), new HuffmanCode(4, 5)
          ];
          for (i in 0...CODE_LENGTH_CODES) {
            s.code_length_code_lengths[i] = 0;
          }
          for (i in s.simple_code_or_skip...CODE_LENGTH_CODES) {
			  if (!(space > 0)) break;//FIX
            var code_len_idx:Int = kCodeLengthCodeOrder[i];//const
            var p = huff;//const
            var p_off:Int = 0;
            var v:UInt;
            BrotliFillBitWindow(br);
            p_off += (br.val_ >> br.bit_pos_) & 15;
            br.bit_pos_ += p[p_off].bits;
            v = p[p_off].value;
            s.code_length_code_lengths[code_len_idx] = v;
            BROTLI_LOG_ARRAY_INDEX(s.code_length_code_lengths, code_len_idx);
            if (v != 0) {
              space -= (32 >> v);
              ++num_codes;
            }
          }
          if (!(num_codes == 1 || space == 0)) {
            return BROTLI_FAILURE();
          }
          s.sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN;
        }
	  }
        /* No break, go to next state */
      if(s.sub_state[1]== BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN || s.sub_state[1]==BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS){
        result = ReadHuffmanCodeLengths(s.code_length_code_lengths,
                                        alphabet_size, s.code_lengths, s);
        if (result != BROTLI_RESULT_SUCCESS) return result;
        s.sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_DONE;
	  }
        /* No break, go to next state */
      if(s.sub_state[1]== BROTLI_STATE_SUB_HUFFMAN_DONE){
        table_size = BrotliBuildHuffmanTable(table, table_off, HUFFMAN_TABLE_BITS,
                                             s.code_lengths, alphabet_size);
        if (table_size == 0) {
          BROTLI_LOG(("[ReadHuffmanCode] BuildHuffmanTable failed: "));
          BROTLI_LOG_UCHAR_VECTOR(s.code_lengths, alphabet_size);
          return BROTLI_FAILURE();
        }
        //TODO:free(s.code_lengths);
        s.code_lengths = null;
        if (opt_table_size!=null) {//TODO:
          opt_table_size[0] = table_size;
        }
        s.sub_state[1] = BROTLI_STATE_SUB_NONE;
        return result;
	  }
      //default:
      //  return BROTLI_FAILURE();  /* unknown state */
    //}
  }

  return BROTLI_FAILURE();
}

//427
static function ReadBlockLength(table:Vector<HuffmanCode>,
                                         table_off:Int,
                                         br:BrotliBitReader):Int {
  var code:Int;
  var nbits:Int;
  code = ReadSymbol(table, table_off, br);
  nbits = kBlockLengthPrefixCode[code].nbits;
  return kBlockLengthPrefixCode[code].offset + BrotliReadBits(br, nbits);
}

//435
static function TranslateShortCodes(code:Int, ringbuffer:Vector<Int>, index:Int):Int {
  var val:Int;
  if (code < NUM_DISTANCE_SHORT_CODES) {
    index += kDistanceShortCodeIndexOffset[code];
    index &= 3;
    val = ringbuffer[index] + kDistanceShortCodeValueOffset[code];
  } else {
    val = code - NUM_DISTANCE_SHORT_CODES + 1;
  }
  return val;
}

//448
static function InverseMoveToFrontTransform(v:Vector<UInt>, v_len:Int) {//uint8_t* 
  var mtf:Vector<UInt>=new Vector<UInt>(256);
  var i:Int;
  for (i in 0...256) {
    mtf[i] = i;
  }
  for (i in 0...v_len) {
    var index:UInt = v[i];
    var value:UInt = mtf[index];
    v[i] = value;
    while (index>0) {//TODO:WORKS?
      mtf[index] = mtf[index - 1];
	  --index;
    }
    mtf[0] = value;
  }
}

//465
static function HuffmanTreeGroupDecode(group:HuffmanTreeGroup,
                                           s:BrotliState) {
  //switch (s.sub_state[0]) {
    if(s.sub_state[0]== BROTLI_STATE_SUB_NONE) {
      s.next = group.codes;
      s.htree_index = 0;
      s.sub_state[0] = BROTLI_STATE_SUB_TREE_GROUP;
      /* No break, continue to next state. */
	}
    if(s.sub_state[0]== BROTLI_STATE_SUB_TREE_GROUP) {
	  var next_off:Int = 0;
      while (s.htree_index < group.num_htrees) {
        var table_size:Array<Int>=[];
		//														  &
        var result:BrotliResult =
            ReadHuffmanCode(group.alphabet_size, s.next,next_off, table_size, s);
        if (result != BROTLI_RESULT_SUCCESS) return result;
        group.htrees[s.htree_index] = s.next;
		group.htrees_off[s.htree_index] = next_off;//TODO:COPY?
        next_off += table_size[0];
        if (table_size[0] == 0) {
          return BROTLI_FAILURE();
        }
        ++s.htree_index;
      }
      s.sub_state[0] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
	}
    //default:
    //  return BROTLI_FAILURE();  /* unknown state */
  //}

  return BROTLI_FAILURE();
}

//495
static function DecodeContextMap(context_map_size:Int,
                                 num_htrees:Array<Int>,
                                 context_map:Array<Vector<UInt>>,//uint8_t**
								 //context_map_off:Int,//uint8_t** 
                                 s:BrotliState) {
  var br:BrotliBitReader = s.br;
  var result:BrotliResult = BROTLI_RESULT_SUCCESS;
  var use_rle_for_zeros:Int;

  //switch(s.sub_state[0]) {
    if(s.sub_state[0]== BROTLI_STATE_SUB_NONE) {
      if (!BrotliReadMoreInput(br)) {
        return BROTLI_RESULT_NEEDS_MORE_INPUT;
      }
      num_htrees[0] = DecodeVarLenUint8(br) + 1;

      s.context_index = 0;

      BROTLI_LOG_UINT(context_map_size);
      BROTLI_LOG_UINT(num_htrees[0]);

      context_map[0] = mallocUInt(context_map_size);
      if (context_map[0].length == 0) {
        return BROTLI_FAILURE();
      }
      if (num_htrees[0] <= 1) {
        memset(context_map[0], 0, 0, context_map_size);
        return BROTLI_RESULT_SUCCESS;
      }

      use_rle_for_zeros = BrotliReadBits(br, 1);
      if (use_rle_for_zeros==1) {
        s.max_run_length_prefix = BrotliReadBits(br, 4) + 1;
      } else {
        s.max_run_length_prefix = 0;
      }
      s.context_map_table = malloc2(HuffmanCode,
          BROTLI_HUFFMAN_MAX_TABLE_SIZE);//TODO:malloc * sizeof(*s.context_map_table)
      if (s.context_map_table == null) {
        return BROTLI_FAILURE();
      }
      s.sub_state[0] = BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN;
	}
      /* No break, continue to next state. */
    if(s.sub_state[0]== BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN) {
      result = ReadHuffmanCode(num_htrees[0] + s.max_run_length_prefix,
                               s.context_map_table, 0, null, s);
      if (result != BROTLI_RESULT_SUCCESS) return result;
      s.sub_state[0] = BROTLI_STATE_SUB_CONTEXT_MAPS;
	}
      /* No break, continue to next state. */
    if(s.sub_state[0]== BROTLI_STATE_SUB_CONTEXT_MAPS) {
      while (s.context_index < context_map_size) {
        var code:Int;
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        code = ReadSymbol(s.context_map_table, 0, br);
        if (code == 0) {
          (context_map[0])[s.context_index] = 0;
          ++s.context_index;
        } else if (code <= s.max_run_length_prefix) {
          var reps:Int = 1 + (1 << code) + BrotliReadBits(br, code);
          while (--reps>0) {//TODO:>=
            if (s.context_index >= context_map_size) {
              return BROTLI_FAILURE();
            }
            (context_map[0])[s.context_index] = 0;
            ++s.context_index;
          }
        } else {
          (context_map[0])[s.context_index] =
              (code - s.max_run_length_prefix);
          ++s.context_index;
        }
      }
      if (BrotliReadBits(br, 1)==1) {
        InverseMoveToFrontTransform(context_map[0], context_map_size);
      }
      //free(s.context_map_table);
      s.context_map_table = null;
      s.sub_state[0] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
	}
    //default:
    //  return BROTLI_FAILURE();  /* unknown state */
  //}

  return BROTLI_FAILURE();
}

static function DecodeBlockType(max_block_type:Int,
                                          trees:Vector<HuffmanCode>,//*
                                          tree_type:Int,
                                          block_types:Vector<Int>,
                                          ringbuffers:Vector<Int>,
                                          indexes:Vector<Int>,
                                          br:BrotliBitReader) {
  var ringbuffer:Vector<Int> = ringbuffers;
  var ringbuffer_off:Int = tree_type * 2;//+ 
  var index:Vector<Int> = indexes;
  var index_off:Int = tree_type;//+
  var type_code:Int =
      ReadSymbol(trees,(tree_type * BROTLI_HUFFMAN_MAX_TABLE_SIZE), br);
  var block_type:Int;
  if (type_code == 0) {
    block_type = ringbuffer[ringbuffer_off+(index[index_off] & 1)];
  } else if (type_code == 1) {
    block_type = ringbuffer[ringbuffer_off+((index[index_off] - 1) & 1)] + 1;
  } else {
    block_type = type_code - 2;
  }
  if (block_type >= max_block_type) {
    block_type -= max_block_type;
  }
  block_types[tree_type] = block_type;
  ringbuffer[ringbuffer_off+((index[index_off]) & 1)] = block_type;
  index[index_off]+=1;
  
}

//609
/* Decodes the block type and updates the state for literal context. */
static function DecodeBlockTypeWithContext(s:BrotliState,
                                                     br:BrotliBitReader) {
  DecodeBlockType(s.num_block_types[0],
                  s.block_type_trees, 0,
                  s.block_type, s.block_type_rb,
                  s.block_type_rb_index, br);
  s.block_length[0] = ReadBlockLength(s.block_len_trees, 0, br);
  s.context_offset = s.block_type[0] << kLiteralContextBits;
  s.context_map_slice = s.context_map;
  s.context_map_slice_off = s.context_map_off + s.context_offset;
  s.literal_htree_index = s.context_map_slice[s.context_map_slice_off+0];
  s.context_mode = s.context_modes[s.block_type[0]];
  s.context_lookup_offset1 = kContextLookupOffsets[s.context_mode];
  s.context_lookup_offset2 = kContextLookupOffsets[s.context_mode + 1];
}

//675
static function CopyUncompressedBlockToOutput(output:BrotliOutput,
                                           pos:Int,
                                           s:BrotliState) {
  var rb_size:Int = s.ringbuffer_mask + 1;
  var ringbuffer_end = s.ringbuffer;//uint8_t*
  var ringbuffer_end_off = s.ringbuffer_off + rb_size;
  var rb_pos:Int = pos & s.ringbuffer_mask;
  var br_pos:Int = s.br.pos_ & BROTLI_IBUF_MASK;
  var remaining_bits:UInt;
  var num_read:Int;
  var num_written:Int;

  /* State machine */
  while (true) {
    //switch (s.sub_state[0]) {
      if(s.sub_state[0]== BROTLI_STATE_SUB_NONE){
        /* For short lengths copy byte-by-byte */
        if (s.meta_block_remaining_len < 8 || s.br.bit_pos_ +
            (s.meta_block_remaining_len << 3) < s.br.bit_end_pos_) {
          s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_SHORT;
          continue;
        }
        if (s.br.bit_end_pos_ < 64) {
          return BROTLI_FAILURE();
        }
        /*
         * Copy remaining 0-4 in 32-bit case or 0-8 bytes in the 64-bit case
         * from s.br.val_ to ringbuffer.
         */
        remaining_bits = 32;
        while (s.br.bit_pos_ < remaining_bits) {
          s.ringbuffer[s.ringbuffer_off+rb_pos] = (s.br.val_ >> s.br.bit_pos_)&255;
          s.br.bit_pos_ += 8;
          ++rb_pos;
          --s.meta_block_remaining_len;
        }

        /* Copy remaining bytes from s.br.buf_ to ringbuffer. */
        s.nbytes = (s.br.bit_end_pos_ - s.br.bit_pos_) >> 3;
        if (br_pos + s.nbytes > BROTLI_IBUF_MASK) {
          var tail:Int = BROTLI_IBUF_MASK + 1 - br_pos;
		  //	&						&
          memcpy(s.ringbuffer,s.ringbuffer_off+rb_pos, s.br.buf_,s.br.buf_off+br_pos, tail);
          s.nbytes -= tail;
          rb_pos += tail;
          s.meta_block_remaining_len -= tail;
          br_pos = 0;
        }
		//	&						&
        memcpy(s.ringbuffer,s.ringbuffer_off+rb_pos, s.br.buf_,s.br.buf_off+br_pos, s.nbytes);
        rb_pos += s.nbytes;
        s.meta_block_remaining_len -= s.nbytes;

        s.partially_written = 0;
        s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1;
	  }
        /* No break, continue to next state */
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1){
        /* If we wrote past the logical end of the ringbuffer, copy the tail of
           the ringbuffer to its beginning and flush the ringbuffer to the
           output. */
        if (rb_pos >= rb_size) {
          num_written = BrotliWrite(output,
                                    s.ringbuffer,s.ringbuffer_off + s.partially_written,
                                    (rb_size - s.partially_written));
          if (num_written < 0) {
            return BROTLI_FAILURE();
          }
          s.partially_written += num_written;
          if (s.partially_written < rb_size) {
            return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
          }
          rb_pos -= rb_size;
          s.meta_block_remaining_len += rb_size;
          memcpy(s.ringbuffer,s.ringbuffer_off, ringbuffer_end,ringbuffer_end_off, rb_pos);
        }
        s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_FILL;
        continue;
	  }
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_SHORT){
        while (s.meta_block_remaining_len > 0) {
          if (!BrotliReadMoreInput(s.br)) {
            return BROTLI_RESULT_NEEDS_MORE_INPUT;
          }
          s.ringbuffer[rb_pos++] = BrotliReadBits(s.br, 8);
          if (rb_pos == rb_size) {
            s.partially_written = 0;
            s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2;
            break;
          }
          s.meta_block_remaining_len--;
        }
        if (s.sub_state[0] == BROTLI_STATE_SUB_UNCOMPRESSED_SHORT) {
          s.sub_state[0] = BROTLI_STATE_SUB_NONE;
          return BROTLI_RESULT_SUCCESS;
        }
		s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2;//ADDED
	  }
        /* No break, if state is updated, continue to next state */
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2){
        num_written = BrotliWrite(output, s.ringbuffer,s.ringbuffer_off + s.partially_written,
                                  (rb_size - s.partially_written));
        if (num_written < 0) {
          return BROTLI_FAILURE();
        }
        s.partially_written += num_written;
        if (s.partially_written < rb_size) {
          return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
        }
        rb_pos = 0;
        s.meta_block_remaining_len--;
        s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_SHORT;
        continue;
	  }
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_FILL){
        /* If we have more to copy than the remaining size of the ringbuffer,
           then we first fill the ringbuffer from the input and then flush the
           ringbuffer to the output */
        if (rb_pos + s.meta_block_remaining_len >= rb_size) {
          s.nbytes = rb_size - rb_pos;
		  //							&
          if (BrotliRead(s.br.input_, s.ringbuffer,s.ringbuffer_off+rb_pos,
                         s.nbytes) < s.nbytes) {
            return BROTLI_RESULT_NEEDS_MORE_INPUT;
          }
          s.partially_written = 0;
          s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3;
        } else {
          s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_COPY;
          continue;
        }
	  }
        /* No break, continue to next state */
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3){
        num_written = BrotliWrite(output, s.ringbuffer, s.ringbuffer_off + s.partially_written,
                                  (rb_size - s.partially_written));
        if (num_written < 0) {
          return BROTLI_FAILURE();
        }
        s.partially_written += num_written;
        if (s.partially_written < rb_size) {
          return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
        }
        s.meta_block_remaining_len -= s.nbytes;
        rb_pos = 0;
        s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_FILL;
        continue;
	  }
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_COPY){
        /* Copy straight from the input onto the ringbuffer. The ringbuffer will
           be flushed to the output at a later time. */
		   //								&
        num_read = BrotliRead(s.br.input_, s.ringbuffer,s.ringbuffer_off+rb_pos,
                              s.meta_block_remaining_len);
        s.meta_block_remaining_len -= num_read;
        if (s.meta_block_remaining_len > 0) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }

        /* Restore the state of the bit reader. */
        BrotliInitBitReader(s.br, s.br.input_, s.br.finish_);
        s.sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP;
	  }
        /* No break, continue to next state */
      if(s.sub_state[0]== BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP){
        if (!BrotliWarmupBitReader(s.br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        s.sub_state[0] = BROTLI_STATE_SUB_NONE;
        return BROTLI_RESULT_SUCCESS;
        continue;
	  }
      //default:
      //  return BROTLI_FAILURE();  /* Unknown state */
    //}
  }
  return BROTLI_FAILURE();
}

//844
static function BrotliDecompressedSize(encoded_size:Int,
                                    encoded_buffer:Vector<UInt>,//const uint8_t*
									encoded_buffer_off:Int,
                                    decoded_size:Array<Int>//size_t * 
									):BrotliResult {
  var i:Int;
  var val:UInt = 0;
  var bit_pos:Int = 0;
  var is_last:Int;
  var is_uncompressed:Int = 0;
  var size_nibbles:Int;
  var meta_block_len:Int = 0;
  if (encoded_size == 0) {
    return BROTLI_FAILURE();
  }
  /* Look at the first 8 bytes, it is enough to decode the length of the first
     meta-block. */
  for (i in 0...4) {
	  if (i >= encoded_size) break;
    val |= encoded_buffer[i] << (8 * i);
  }
  /* Skip the window bits. */
  ++bit_pos;
  if ((val & 1)==1) {
    bit_pos += 3;
    if (((val >> 1) & 7) == 0) {
      bit_pos += 3;
    }
  }
  /* Decode the ISLAST bit. */
  is_last = (val >> bit_pos) & 1;
  ++bit_pos;
  if (is_last==1) {
    /* Decode the ISEMPTY bit, if it is set to 1, we are done. */
    if (((val >> bit_pos) & 1)==1) {
      decoded_size[0] = 0;
      return BROTLI_RESULT_SUCCESS;
    }
    ++bit_pos;
  }
  /* Decode the length of the first meta-block. */
  size_nibbles = ((val >> bit_pos) & 3) + 4;
  if (size_nibbles == 7) {
    /* First meta-block contains metadata, this case is not supported here. */
    return BROTLI_FAILURE();
  }
  bit_pos += 2;
  for (i in 0...size_nibbles) {
    meta_block_len |= ((val >> bit_pos) & 0xf) << (4 * i);
    bit_pos += 4;
  }
  ++meta_block_len;
  if (is_last==1) {
    /* If this meta-block is the only one, we are done. */
    decoded_size[0] = meta_block_len;
    return BROTLI_RESULT_SUCCESS;
  }
  is_uncompressed = (val >> bit_pos) & 1;
  ++bit_pos;
  if (is_uncompressed==1) {
    /* If the first meta-block is uncompressed, we skip it and look at the
       first two bits (ISLAST and ISEMPTY) of the next meta-block, and if
       both are set to 1, we have a stream with an uncompressed meta-block
       followed by an empty one, so the decompressed size is the size of the
       first meta-block. */
    var offset = ((bit_pos + 7) >> 3) + meta_block_len;
    if (offset < encoded_size && ((encoded_buffer[offset] & 3) == 3)) {
      decoded_size[0] = meta_block_len;
      return BROTLI_RESULT_SUCCESS;
    }
  }
  return BROTLI_FAILURE();
}



	static function BrotliDecompressStreaming(input:BrotliInput, output:BrotliOutput,
										   finish:Int, s:BrotliState):BrotliResult {
	  var context:UInt;//uint8_t
	  var pos:Int = s.pos;
	  var i = s.loop_counter;
	  var result:BrotliResult = BROTLI_RESULT_SUCCESS;
	  var br:BrotliBitReader = s.br;
	  var initial_remaining_len:Int;
	  var bytes_copied:Int;
	  var num_written:Int;

	  /* We need the slack region for the following reasons:
		   - always doing two 8-byte copies for fast backward copying
		   - transforms
		   - flushing the input s->ringbuffer when decoding uncompressed blocks */
	  var kRingBufferWriteAheadSlack:Int = 128 + BROTLI_READ_SIZE;//static const

	  s.br.input_ = input;
	  s.br.finish_ = finish;

	  /* State machine */
	  while (true) {
//untyped __php__("print memory_get_usage().\"<br>\n\";");
		if (result != BROTLI_RESULT_SUCCESS) {
		  if (result == BROTLI_RESULT_NEEDS_MORE_INPUT && finish==1) {
			BROTLI_LOG("Unexpected end of input. State: "+ s.state+"\n");
			result = BROTLI_FAILURE();
		  }
		  break;  /* Fail, or partial data. */
		}

		//switch (s.state) {
		  if(s.state== BROTLI_STATE_UNINITED){
			pos = 0;
			s.input_end = 0;
			s.window_bits = 0;
			s.max_distance = 0;
			s.dist_rb[0] = 16;
			s.dist_rb[1] = 15;
			s.dist_rb[2] = 11;
			s.dist_rb[3] = 4;
			s.dist_rb_idx = 0;
			s.prev_byte1 = 0;
			s.prev_byte2 = 0;
			s.block_type_trees = null;
			s.block_len_trees = null;

			BrotliInitBitReader(br, input, finish);

			s.state = BROTLI_STATE_BITREADER_WARMUP;
		  }
			/* No break, continue to next state */
		  if(s.state== BROTLI_STATE_BITREADER_WARMUP){
			if (!BrotliWarmupBitReader(br)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			/* Decode window size. */
			s.window_bits = DecodeWindowBits(br);
			if (s.window_bits == 9) {
			  /* Value 9 is reserved for future use. */
			  result = BROTLI_FAILURE();
			  continue;
			}
			s.max_backward_distance = (1 << s.window_bits) - 16;

			s.block_type_trees = malloc2(HuffmanCode,
				3 * BROTLI_HUFFMAN_MAX_TABLE_SIZE);
			s.block_len_trees = malloc2(HuffmanCode,
				3 * BROTLI_HUFFMAN_MAX_TABLE_SIZE);
			if (s.block_type_trees == null || s.block_len_trees == null) {
			  result = BROTLI_FAILURE();
			  continue;
			}

			s.state = BROTLI_STATE_METABLOCK_BEGIN;
		  }
			/* No break, continue to next state */
		  if(s.state== BROTLI_STATE_METABLOCK_BEGIN){
			if (s.input_end!=0) {
			  s.partially_written = 0;
			  s.state = BROTLI_STATE_DONE;
			  continue;
			}
			s.meta_block_remaining_len = 0;
			s.block_length[0] = 1 << 28;
			s.block_length[1] = 1 << 28;
			s.block_length[2] = 1 << 28;
			s.block_type[0] = 0;
			s.num_block_types[0] = 1;
			s.num_block_types[1] = 1;
			s.num_block_types[2] = 1;
			s.block_type_rb[0] = 0;
			s.block_type_rb[1] = 1;
			s.block_type_rb[2] = 0;
			s.block_type_rb[3] = 1;
			s.block_type_rb[4] = 0;
			s.block_type_rb[5] = 1;
			s.block_type_rb_index[0] = 0;
			s.context_map = null;
			s.context_modes = null;
			s.dist_context_map = null;
			s.context_offset = 0;
			s.context_map_slice = null;
			s.context_map_slice_off = 0;
			s.literal_htree_index = 0;
			s.dist_context_offset = 0;
			s.dist_context_map_slice = null;
			s.dist_context_map_slice_off = 0;
			s.dist_htree_index = 0;
			s.context_lookup_offset1 = 0;
			s.context_lookup_offset2 = 0;
			for (i in 0...3) {
			  s.hgroup[i].codes = null;
			  s.hgroup[i].htrees = null;
			}
			s.state = BROTLI_STATE_METABLOCK_HEADER_1;
		  }
			/* No break, continue to next state */
		  if(s.state== BROTLI_STATE_METABLOCK_HEADER_1){
			if (!BrotliReadMoreInput(br)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			BROTLI_LOG_UINT(pos);
			var meta_block_remaining_len:Array<Int> = [s.meta_block_remaining_len];
			var input_end:Array<Int> = [s.input_end];
			var is_metadata:Array<Int> = [s.is_metadata];
			var is_uncompressed:Array<Int> = [s.is_uncompressed];
			if (!DecodeMetaBlockLength(br,
									   meta_block_remaining_len,//&
									   input_end,//&
									   is_metadata,//&
									   is_uncompressed)) {//&
			  result = BROTLI_FAILURE();
			  continue;
			}
			s.meta_block_remaining_len = meta_block_remaining_len[0];
			s.input_end = input_end[0];
			s.is_metadata = is_metadata[0];
			s.is_uncompressed = is_uncompressed[0];
			BROTLI_LOG_UINT(s.meta_block_remaining_len);
			/* If it is the first metablock, allocate the ringbuffer */
			if (s.ringbuffer == null) {
			  var known_size:Array<Int> = [0];//size_t
			  s.ringbuffer_size = 1 << s.window_bits;

			  /* If we know the data size is small, do not allocate more ringbuffer
				 size than needed to reduce memory usage. Since this happens after
				 the first BrotliReadMoreInput call, we can read the bitreader
				 buffer at position 0. */							//&
			  if (BrotliDecompressedSize(BROTLI_READ_SIZE, br.buf_, br.buf_off, known_size)
				  == BROTLI_RESULT_SUCCESS) {
				while (s.ringbuffer_size >= known_size[0] * 2
					&& s.ringbuffer_size > 1) {
				  s.ringbuffer_size = Std.int(s.ringbuffer_size/2);
				}
			  }

			  /* But make it fit the custom dictionary if there is one. */
			  while (s.ringbuffer_size < s.custom_dict_size) {
				s.ringbuffer_size *= 2;
			  }

			  s.ringbuffer_mask = s.ringbuffer_size - 1;
			  /* = TODO:malloc(UInt,(s.ringbuffer_size +
													 kRingBufferWriteAheadSlack +
													 kMaxDictionaryWordLength));
				memset(s.ringbuffer, 0, 0, s.ringbuffer_size +
													 kRingBufferWriteAheadSlack +
													 kMaxDictionaryWordLength);*/	
				s.ringbuffer = new Vector<UInt>(s.ringbuffer_size +
													 kRingBufferWriteAheadSlack +
													 kMaxDictionaryWordLength); 
			  s.ringbuffer_off = 0;
			  if (!(s.ringbuffer.length!=0)) {
				result = BROTLI_FAILURE();
				continue;
			  }
			  s.ringbuffer_end = s.ringbuffer;
			  s.ringbuffer_end_off = s.ringbuffer_off + s.ringbuffer_size;

			  if (s.custom_dict_off!=-1) {
				memcpy(s.ringbuffer,s.ringbuffer_off+((-s.custom_dict_size) & s.ringbuffer_mask),
									  s.custom_dict, s.custom_dict_off, s.custom_dict_size);
				if (s.custom_dict_size > 0) {
				  s.prev_byte1 = s.custom_dict[s.custom_dict_size - 1];
				}
				if (s.custom_dict_size > 1) {
				  s.prev_byte2 = s.custom_dict[s.custom_dict_size - 2];
				}
			  }
			}

			if (s.is_metadata==1) {
			  if (!JumpToByteBoundary(s.br)) {
				result = BROTLI_FAILURE();
				continue;
			  }
			  s.state = BROTLI_STATE_METADATA;
			  continue;
			}
			if (s.meta_block_remaining_len == 0) {
			  s.state = BROTLI_STATE_METABLOCK_DONE;
			  continue;
			}
			if (s.is_uncompressed==1) {
			  if (!JumpToByteBoundary(s.br)) {
				result = BROTLI_FAILURE();
				continue;
			  }
			  s.state = BROTLI_STATE_UNCOMPRESSED;
			  continue;
			}
			i = 0;
			s.state = BROTLI_STATE_HUFFMAN_CODE_0;
			continue;
		  }
		  if(s.state== BROTLI_STATE_UNCOMPRESSED){
			initial_remaining_len = s.meta_block_remaining_len;
			/* pos is given as argument since s.pos is only updated at the end. */
			result = CopyUncompressedBlockToOutput(output, pos, s);
			if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
			  continue;
			}
			bytes_copied = initial_remaining_len - s.meta_block_remaining_len;
			pos += bytes_copied;
			if (bytes_copied > 0) {
			  s.prev_byte2 = bytes_copied == 1 ? s.prev_byte1 :
				  s.ringbuffer[(pos - 2) & s.ringbuffer_mask];
			  s.prev_byte1 = s.ringbuffer[(pos - 1) & s.ringbuffer_mask];
			}
			if (result != BROTLI_RESULT_SUCCESS) continue;
			s.state = BROTLI_STATE_METABLOCK_DONE;
			continue;
		  }
		  if(s.state== BROTLI_STATE_METADATA){
			while (s.meta_block_remaining_len > 0) {
			  if (!BrotliReadMoreInput(s.br)) {
				result = BROTLI_RESULT_NEEDS_MORE_INPUT;
				continue;
			  }
			  /* Read one byte and ignore it. */
			  BrotliReadBits( s.br, 8);
			  --s.meta_block_remaining_len;
			}
			s.state = BROTLI_STATE_METABLOCK_DONE;
			continue;
		  }
		  if(s.state== BROTLI_STATE_HUFFMAN_CODE_0){
			if (i >= 3) {
			  BROTLI_LOG_UINT(s.num_block_types[0]);
			  BROTLI_LOG_UINT(s.num_block_types[1]);
			  BROTLI_LOG_UINT(s.num_block_types[2]);
			  BROTLI_LOG_UINT(s.block_length[0]);
			  BROTLI_LOG_UINT(s.block_length[1]);
			  BROTLI_LOG_UINT(s.block_length[2]);

			  s.state = BROTLI_STATE_METABLOCK_HEADER_2;
			  continue;
			}
			s.num_block_types[i] = DecodeVarLenUint8(br) + 1;
			s.state = BROTLI_STATE_HUFFMAN_CODE_1;
			/* No break, continue to next state */
		  }
		  if(s.state== BROTLI_STATE_HUFFMAN_CODE_1){
			if (s.num_block_types[i] >= 2) {
			  result = ReadHuffmanCode(s.num_block_types[i] + 2,
				  s.block_type_trees,(i * BROTLI_HUFFMAN_MAX_TABLE_SIZE),
				  null, s);
			  if (result != BROTLI_RESULT_SUCCESS) continue;
			  s.state = BROTLI_STATE_HUFFMAN_CODE_2;
			} else {
			  i++;
			  s.state = BROTLI_STATE_HUFFMAN_CODE_0;
			  continue;
			}
			/* No break, continue to next state */
		  }
		  if(s.state== BROTLI_STATE_HUFFMAN_CODE_2){
			result = ReadHuffmanCode(kNumBlockLengthCodes,
				s.block_len_trees,(i * BROTLI_HUFFMAN_MAX_TABLE_SIZE),
				null, s);
			if (result != BROTLI_RESULT_SUCCESS) break;
			s.block_length[i] = ReadBlockLength(
				s.block_len_trees,(i * BROTLI_HUFFMAN_MAX_TABLE_SIZE), br);
			s.block_type_rb_index[i] = 1;
			i++;
			s.state = BROTLI_STATE_HUFFMAN_CODE_0;
			continue;
		  }
		  if(s.state== BROTLI_STATE_METABLOCK_HEADER_2){
			/* We need up to 256 * 2 + 6 bits, this fits in 128 bytes. */
			if (!BrotliReadInputAmount(br, 128)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			s.distance_postfix_bits = BrotliReadBits(br, 2);
			s.num_direct_distance_codes = NUM_DISTANCE_SHORT_CODES +
				(BrotliReadBits(br, 4) << s.distance_postfix_bits);
			s.distance_postfix_mask = (1 << s.distance_postfix_bits) - 1;
			s.num_distance_codes = (s.num_direct_distance_codes +
								  (48 << s.distance_postfix_bits));
			s.context_modes = mallocUInt(s.num_block_types[0]);
			if (s.context_modes.length == 0) {
			  result = BROTLI_FAILURE();
			  continue;
			}
			for (i in 0...s.num_block_types[0]) {
			  s.context_modes[i] = (BrotliReadBits(br, 2) << 1);
			  BROTLI_LOG_ARRAY_INDEX(s.context_modes, i);
			}
			BROTLI_LOG_UINT(s.num_direct_distance_codes);
			BROTLI_LOG_UINT(s.distance_postfix_bits);
			s.state = BROTLI_STATE_CONTEXT_MAP_1;
			/* No break, continue to next state */
		  }
		  if(s.state== BROTLI_STATE_CONTEXT_MAP_1){
			  var num_literal_htrees = [s.num_literal_htrees]; var context_map = [s.context_map];
			result = DecodeContextMap(s.num_block_types[0] << kLiteralContextBits,
									  num_literal_htrees, context_map, s);
			s.num_literal_htrees = num_literal_htrees[0]; s.context_map = context_map[0];s.context_map_off = 0;

			s.trivial_literal_context = 1;
			for (i in 0...(s.num_block_types[0] << kLiteralContextBits)) {
			  if (s.context_map[i] != i >> kLiteralContextBits) {
				s.trivial_literal_context = 0;
				continue;
			  }
			}

			if (result != BROTLI_RESULT_SUCCESS) continue;
			s.state = BROTLI_STATE_CONTEXT_MAP_2;
			/* No break, continue to next state */
		  }
		  if(s.state== BROTLI_STATE_CONTEXT_MAP_2){
			  var num_dist_htrees = [s.num_dist_htrees]; var dist_context_map = [s.dist_context_map];
			result = DecodeContextMap(s.num_block_types[2] << kDistanceContextBits,
									  num_dist_htrees, dist_context_map, s);
			s.num_dist_htrees = num_dist_htrees[0]; s.dist_context_map = dist_context_map[0];s.dist_context_map_off = 0;//TODO:
			if (result != BROTLI_RESULT_SUCCESS) continue;

			BrotliHuffmanTreeGroupInit(s.hgroup[0], kNumLiteralCodes,
									   s.num_literal_htrees);
			BrotliHuffmanTreeGroupInit(s.hgroup[1], kNumInsertAndCopyCodes,
									   s.num_block_types[1]);
			BrotliHuffmanTreeGroupInit(s.hgroup[2], s.num_distance_codes,
									   s.num_dist_htrees);
			i = 0;
			s.state = BROTLI_STATE_TREE_GROUP;
			/* No break, continue to next state */
		  }
		  if(s.state== BROTLI_STATE_TREE_GROUP){
			result = HuffmanTreeGroupDecode(s.hgroup[i], s);
			if (result != BROTLI_RESULT_SUCCESS) continue;
			i++;

			if (i >= 3) {
			  s.context_map_slice = s.context_map;
			  s.context_map_slice_off = s.context_map_off;
			  s.dist_context_map_slice = s.dist_context_map;
			  s.dist_context_map_slice_off = s.dist_context_map_off;
			  s.context_mode = s.context_modes[s.block_type[0]];
			  s.context_lookup_offset1 = kContextLookupOffsets[s.context_mode];
			  s.context_lookup_offset2 =
				  kContextLookupOffsets[s.context_mode + 1];
			  s.htree_command = s.hgroup[1].htrees[0];//TODO:OFFSET?
			  s.htree_command_off = s.hgroup[1].htrees_off[0];

			  s.state = BROTLI_STATE_BLOCK_BEGIN;
			  continue;
			}

			continue;
		  }
		  if(s.state== BROTLI_STATE_BLOCK_BEGIN){
	 /* Block decoding is the inner loop, jumping with goto makes it 3% faster */
	 //BlockBegin:
			if (!BrotliReadMoreInput(br)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			if (s.meta_block_remaining_len <= 0) {
			  /* Protect pos from overflow, wrap it around at every GB of input. */
			  pos &= 0x3fffffff;

			  /* Next metablock, if any */
			  s.state = BROTLI_STATE_METABLOCK_DONE;
			  continue;
			}

			if (s.block_length[1] == 0) {
			  DecodeBlockType(s.num_block_types[1],
							  s.block_type_trees, 1,
							  s.block_type, s.block_type_rb,
							  s.block_type_rb_index, br);
			  s.block_length[1] = ReadBlockLength(
			  //&
				  s.block_len_trees,(BROTLI_HUFFMAN_MAX_TABLE_SIZE), br);
			  s.htree_command = s.hgroup[1].htrees[s.block_type[1]];
			  s.htree_command_off = s.hgroup[1].htrees_off[s.block_type[1]];
			}
			s.block_length[1]-=1;
			s.cmd_code = ReadSymbol(s.htree_command,s.htree_command_off, br);
			s.range_idx = s.cmd_code >> 6;
			if (s.range_idx >= 2) {
			  s.range_idx -= 2;
			  s.distance_code = -1;
			} else {
			  s.distance_code = 0;
			}
			s.insert_code =
				kInsertRangeLut[s.range_idx] + ((s.cmd_code >> 3) & 7);
			s.copy_code = kCopyRangeLut[s.range_idx] + (s.cmd_code & 7);
			s.insert_length = kInsertLengthPrefixCode[s.insert_code].offset +
				BrotliReadBits(br,
									kInsertLengthPrefixCode[s.insert_code].nbits);
			s.copy_length = kCopyLengthPrefixCode[s.copy_code].offset +
				BrotliReadBits(br, kCopyLengthPrefixCode[s.copy_code].nbits);
			BROTLI_LOG_UINT(s.insert_length);
			BROTLI_LOG_UINT(s.copy_length);
			BROTLI_LOG_UINT(s.distance_code);

			i = 0;
			s.state = BROTLI_STATE_BLOCK_INNER;
			/* No break, go to next state */
		  }
		  if(s.state== BROTLI_STATE_BLOCK_INNER){
			if (s.trivial_literal_context==1) {
			  while (i < s.insert_length) {
				if (!BrotliReadMoreInput(br)) {
				  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
				  break;
				}
				if (s.block_length[0] == 0) {
				  DecodeBlockTypeWithContext(s, br);
				}

				s.ringbuffer[pos & s.ringbuffer_mask] = ReadSymbol(
					s.hgroup[0].htrees[s.literal_htree_index],s.hgroup[0].htrees_off[s.literal_htree_index], br);

				s.block_length[0]-=1;
				BROTLI_LOG_UINT(s.literal_htree_index);
				BROTLI_LOG_ARRAY_INDEX(s.ringbuffer, pos & s.ringbuffer_mask);
				if ((pos & s.ringbuffer_mask) == s.ringbuffer_mask) {
				  s.partially_written = 0;
				  s.state = BROTLI_STATE_BLOCK_INNER_WRITE;
				  break;
				}
				/* Modifications to this code shold be reflected in
				BROTLI_STATE_BLOCK_INNER_WRITE case */
				++pos;
				++i;
			  }
			} else {
			  var p1:UInt = s.prev_byte1;//uint8_t
			  var p2:UInt = s.prev_byte2;//uint8_t
			  while (i < s.insert_length) {
				if (!BrotliReadMoreInput(br)) {
				  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
				  break;
				}
				if (s.block_length[0] == 0) {
				  DecodeBlockTypeWithContext(s, br);
				}

				context =
					(kContextLookup[s.context_lookup_offset1 + p1] |
					 kContextLookup[s.context_lookup_offset2 + p2]);
				BROTLI_LOG_UINT(context);
				s.literal_htree_index = s.context_map_slice[s.context_map_slice_off+context];
				s.block_length[0]-=1;
				p2 = p1;
				p1 = ReadSymbol(
					s.hgroup[0].htrees[s.literal_htree_index],s.hgroup[0].htrees_off[s.literal_htree_index], br);
				s.ringbuffer[pos & s.ringbuffer_mask] = p1;
				BROTLI_LOG_UINT(s.literal_htree_index);
				BROTLI_LOG_ARRAY_INDEX(s.ringbuffer, pos & s.ringbuffer_mask);
				if ((pos & s.ringbuffer_mask) == s.ringbuffer_mask) {
				  s.partially_written = 0;
				  s.state = BROTLI_STATE_BLOCK_INNER_WRITE;
				  break;
				}
				/* Modifications to this code should be reflected in
				BROTLI_STATE_BLOCK_INNER_WRITE case */
				++pos;
				++i;
			  }
			  s.prev_byte1 = p1;
			  s.prev_byte2 = p2;
			}
			if (result != BROTLI_RESULT_SUCCESS ||
				s.state == BROTLI_STATE_BLOCK_INNER_WRITE) continue;

			s.meta_block_remaining_len -= s.insert_length;
			if (s.meta_block_remaining_len <= 0) {
			  s.state = BROTLI_STATE_METABLOCK_DONE;
			  continue;
			} else if (s.distance_code < 0) {
			  s.state = BROTLI_STATE_BLOCK_DISTANCE;
			} else {
			  s.state = BROTLI_STATE_BLOCK_POST;
			  continue;
			}
		  }
			/* No break, go to next state */
		  if(s.state== BROTLI_STATE_BLOCK_DISTANCE){
			if (!BrotliReadMoreInput(br)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			BROTLI_DCHECK(s.distance_code < 0);

			if (s.block_length[2] == 0) {
			  DecodeBlockType(s.num_block_types[2],
							  s.block_type_trees, 2,
							  s.block_type, s.block_type_rb,
							  s.block_type_rb_index, br);
			  s.block_length[2] = ReadBlockLength(
			  //&
				  s.block_len_trees,(2 * BROTLI_HUFFMAN_MAX_TABLE_SIZE), br);
			  s.dist_context_offset = s.block_type[2] << kDistanceContextBits;
			  s.dist_context_map_slice =
				  s.dist_context_map;
			  s.dist_context_map_slice_off =
				  s.dist_context_map_off + s.dist_context_offset;
			}
			s.block_length[2]-=1;
			context = (s.copy_length > 4 ? 3 : s.copy_length - 2);
			s.dist_htree_index = s.dist_context_map_slice[s.dist_context_map_slice_off+context];
			s.distance_code =
				ReadSymbol(s.hgroup[2].htrees[s.dist_htree_index],s.hgroup[2].htrees_off[s.dist_htree_index], br);
			if (s.distance_code >= s.num_direct_distance_codes) {
			  var nbits:Int;
			  var postfix:Int;
			  var offset:Int;
			  s.distance_code -= s.num_direct_distance_codes;
			  postfix = s.distance_code & s.distance_postfix_mask;
			  s.distance_code >>= s.distance_postfix_bits;
			  nbits = (s.distance_code >> 1) + 1;
			  offset = ((2 + (s.distance_code & 1)) << nbits) - 4;
			  s.distance_code = s.num_direct_distance_codes +
				  ((offset + BrotliReadBits(br, nbits)) <<
				   s.distance_postfix_bits) + postfix;
			}
			s.state = BROTLI_STATE_BLOCK_POST;
		  }
			/* No break, go to next state */
		  if(s.state== BROTLI_STATE_BLOCK_POST){
			if (!BrotliReadMoreInput(br)) {
			  result = BROTLI_RESULT_NEEDS_MORE_INPUT;
			  continue;
			}
			/* Convert the distance code to the actual distance by possibly */
			/* looking up past distnaces from the s.ringbuffer. */
			s.distance =
				TranslateShortCodes(s.distance_code, s.dist_rb, s.dist_rb_idx);
			if (s.distance < 0) {
			  result = BROTLI_FAILURE();
			  continue;
			}
			BROTLI_LOG_UINT(s.distance);

			if (pos + s.custom_dict_size < s.max_backward_distance &&
				s.max_distance != s.max_backward_distance) {
			  s.max_distance = pos + s.custom_dict_size;
			} else {
			  s.max_distance = s.max_backward_distance;
			}

			s.copy_dst = s.ringbuffer;
			s.copy_dst_off = s.ringbuffer_off+(pos & s.ringbuffer_mask);

			if (s.distance > s.max_distance) {
			  if (s.copy_length >= kMinDictionaryWordLength &&
				  s.copy_length <= kMaxDictionaryWordLength) {
				var offset:Int = kBrotliDictionaryOffsetsByLength[s.copy_length];
				var word_id:Int = s.distance - s.max_distance - 1;
				var shift:Int = kBrotliDictionarySizeBitsByLength[s.copy_length];
				var mask:Int = (1 << shift) - 1;
				var word_idx:Int = word_id & mask;
				var transform_idx:Int = word_id >> shift;
				offset += word_idx * s.copy_length;
				if (transform_idx < kNumTransforms) {
				  var word = kBrotliDictionary;//const uint8_t*
				  var word_off = offset;
				  var len:Int = TransformDictionaryWord(
					  s.copy_dst, s.copy_dst_off, word, word_off, s.copy_length, transform_idx);
				  s.copy_dst_off += len;
				  pos += len;
				  s.meta_block_remaining_len -= len;
				  if (s.copy_dst_off >= s.ringbuffer_end_off) {
					s.partially_written = 0;
					num_written = BrotliWrite(output, s.ringbuffer,s.ringbuffer_off,
											  s.ringbuffer_size);
					if (num_written < 0) {
					  result = BROTLI_FAILURE();
					  continue;
					}
					s.partially_written += num_written;
					if (s.partially_written < s.ringbuffer_size) {
					  result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
					  s.state = BROTLI_STATE_BLOCK_POST_WRITE_1;
					  continue;
					}
					/* Modifications to this code shold be reflected in
					BROTLI_STATE_BLOCK_POST_WRITE_1 case */
					memcpy(s.ringbuffer, s.ringbuffer_off, s.ringbuffer_end, s.ringbuffer_end_off,
						   (s.copy_dst_off - s.ringbuffer_end_off));
				  }
				} else {
				  BROTLI_LOG(("Invalid backward reference. pos: "+pos+" distance: "+s.distance+" "+
						 "len: "+s.copy_length+" bytes left: "+s.meta_block_remaining_len+"\n"
					  ));
				  result = BROTLI_FAILURE();
				  continue;
				}
			  } else {
				BROTLI_LOG(("Invalid backward reference. pos: "+pos+" distance: "+s.distance+" "+
					   "len: "+s.copy_length+" bytes left: "+s.meta_block_remaining_len+"\n"
					   ));
				result = BROTLI_FAILURE();
				continue;
			  }
			} else {
			  if (s.distance_code > 0) {
				s.dist_rb[s.dist_rb_idx & 3] = s.distance;
				++s.dist_rb_idx;
			  }

			  if (s.copy_length > s.meta_block_remaining_len) {
				BROTLI_LOG(("Invalid backward reference. pos: "+pos+" distance: "+s.distance+" "+
					   "len: "+s.copy_length+" bytes left: "+s.meta_block_remaining_len+"\n"
					   ));
				result = BROTLI_FAILURE();
				continue;
			  }

			  s.copy_src =
				  s.ringbuffer;
			  s.copy_src_off =
				  s.ringbuffer_off+
				  ((pos - s.distance) & s.ringbuffer_mask);

			  /* Modifications to this loop should be reflected in
			  BROTLI_STATE_BLOCK_POST_WRITE_2 case */
			  for (i in 0...s.copy_length) {
				s.ringbuffer[pos & s.ringbuffer_mask] =
					s.ringbuffer[(pos - s.distance) & s.ringbuffer_mask];
				if ((pos & s.ringbuffer_mask) == s.ringbuffer_mask) {
				  s.partially_written = 0;
				  num_written = BrotliWrite(output, s.ringbuffer,s.ringbuffer_off,
								  s.ringbuffer_size);
				  if (num_written < 0) {
					result = BROTLI_FAILURE();
					continue;
				  }
				  s.partially_written += num_written;
				  if (s.partially_written < s.ringbuffer_size) {
					result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
					s.state = BROTLI_STATE_BLOCK_POST_WRITE_2;
					continue;
				  }
				}
				++pos;
				--s.meta_block_remaining_len;
			  }
			  if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
				continue;
			  }
			}
			s.state = BROTLI_STATE_BLOCK_POST_CONTINUE;//ADDED
		  }
			/* No break, continue to next state */
		  if(s.state== BROTLI_STATE_BLOCK_POST_CONTINUE){
			/* When we get here, we must have inserted at least one literal and */
			/* made a copy of at least length two, therefore accessing the last 2 */
			/* bytes is valid. */
			s.prev_byte1 = s.ringbuffer[(pos - 1) & s.ringbuffer_mask];
			s.prev_byte2 = s.ringbuffer[(pos - 2) & s.ringbuffer_mask];
			s.state = BROTLI_STATE_BLOCK_BEGIN;
		  }
			//goto BlockBegin;
		  if(s.state== BROTLI_STATE_BLOCK_INNER_WRITE||
		  s.state== BROTLI_STATE_BLOCK_POST_WRITE_1||
		  s.state== BROTLI_STATE_BLOCK_POST_WRITE_2){
			num_written = BrotliWrite(
				output, s.ringbuffer,s.ringbuffer_off + s.partially_written,
				(s.ringbuffer_size - s.partially_written));
			if (num_written < 0) {
			  result = BROTLI_FAILURE();
			  continue;
			}
			s.partially_written += num_written;
			if (s.partially_written < s.ringbuffer_size) {
			  result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
			  continue;
			}
			if (s.state == BROTLI_STATE_BLOCK_POST_WRITE_1) {
			  memcpy(s.ringbuffer, s.ringbuffer_off, s.ringbuffer_end, s.ringbuffer_end_off,
					 (s.copy_dst_off - s.ringbuffer_end_off));
			  s.state = BROTLI_STATE_BLOCK_POST_CONTINUE;
			} else if (s.state == BROTLI_STATE_BLOCK_POST_WRITE_2) {
			  /* The tail of "i < s.copy_length" loop. */
			  ++pos;
			  --s.meta_block_remaining_len;
			  ++i;
			  /* Reenter the loop. */
			  while (i < s.copy_length) {
				s.ringbuffer[pos & s.ringbuffer_mask] =
					s.ringbuffer[(pos - s.distance) & s.ringbuffer_mask];
				if ((pos & s.ringbuffer_mask) == s.ringbuffer_mask) {
				  s.partially_written = 0;
				  num_written = BrotliWrite(output, s.ringbuffer, s.ringbuffer_off,
											s.ringbuffer_size);
				  if (num_written < 0) {
					result = BROTLI_FAILURE();
					continue;
				  }
				  s.partially_written += num_written;
				  if (s.partially_written < s.ringbuffer_size) {
					result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
					continue;
				  }
				}
				++pos;
				--s.meta_block_remaining_len;
				++i;
			  }
			  if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
				continue;
			  }
			  s.state = BROTLI_STATE_BLOCK_POST_CONTINUE;
			} else {  /* BROTLI_STATE_BLOCK_INNER_WRITE */
			  /* The tail of "i < s.insert_length" loop. */
			  ++pos;
			  ++i;
			  s.state = BROTLI_STATE_BLOCK_INNER;
			}
			continue;
		  }
		  if(s.state== BROTLI_STATE_METABLOCK_DONE){
			if (s.context_modes != null) {
			  //free(s.context_modes);
			  s.context_modes = null;
			}
			if (s.context_map != null) {
			  //free(s.context_map);
			  s.context_map = null;
			}
			if (s.dist_context_map != null) {
			  //free(s.dist_context_map);
			  s.dist_context_map = null;
			}
			for (i in 0...3) {
			  BrotliHuffmanTreeGroupRelease(s.hgroup[i]);//&
			  s.hgroup[i].codes = null;
			  s.hgroup[i].htrees = null;
			}
			s.state = BROTLI_STATE_METABLOCK_BEGIN;
			continue;
		  }
		  if(s.state== BROTLI_STATE_DONE){
			if (s.ringbuffer.length != 0) {
			  num_written = BrotliWrite(
				  output, s.ringbuffer,s.ringbuffer_off + s.partially_written,
				  ((pos & s.ringbuffer_mask) - s.partially_written));
			  if (num_written < 0) {
				return BROTLI_FAILURE();
			  }
			  s.partially_written += num_written;
			  if (s.partially_written < (pos & s.ringbuffer_mask)) {
				result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
				break;
			  }
			}
			if (!JumpToByteBoundary(s.br)) {
			  result = BROTLI_FAILURE();
			}
			return result;
		  }
		  //default:
		//	BROTLI_LOG(("Unknown state "+s.state+"\n"));
		//	result = BROTLI_FAILURE();
		//}
	  }

	  s.pos = pos;
	  s.loop_counter = i;
	  return result;
	}
	
	
	static public function BrotliDecompress(input, output):Int {
		var s = new BrotliState();
		var result:BrotliResult;
		BrotliStateInit(s);
		result = BrotliDecompressStreaming(input, output, 1, s);
		return 1;
	}
	
}
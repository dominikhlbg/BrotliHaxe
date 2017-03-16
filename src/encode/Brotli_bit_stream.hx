package encode;
import haxe.ds.Vector;
import encode.Write_bits.*;
import encode.Fast_log.*;
import encode.Histogram_functions.*;
import encode.Prefix.*;
import encode.Entropy_encode.*;
import DefaultFunctions.*;
import encode.command.Command;
import encode.metablock.MetaBlockSplit;
import encode.brotli_bit_stream.BlockEncoder;
import encode.brotli_bit_stream.BlockSplitCode;
import encode.Context.*;

/**
 * ...
 * @author 
 */
class Brotli_bit_stream
{

// returns false if fail
// nibblesbits represents the 2 bits to encode MNIBBLES (0-3)
static public function EncodeMlen(length:Int, bits:Array<Int>, numbits:Array<Int>, nibblesbits:Array<Int>):Bool {
  length--;  // MLEN - 1 is encoded
  var lg:Int = length == 0 ? 1 : Log2Floor(length) + 1;
  if (lg > 24) return false;
  var mnibbles:Int = Std.int((lg < 16 ? 16 : (lg + 3)) / 4);
  nibblesbits[0] = mnibbles - 4;
  numbits[0] = mnibbles * 4;
  bits[0] = length;
  return true;
}

static public function StoreVarLenUint8(n:Int, storage_ix:Array<Int>, storage:Vector<UInt>) {
  if (n == 0) {
    WriteBits(1, 0, storage_ix, storage);
  } else {
    WriteBits(1, 1, storage_ix, storage);
    var nbits:Int = Log2Floor(n);
    WriteBits(3, nbits, storage_ix, storage);
    WriteBits(nbits, n - (1 << nbits), storage_ix, storage);
  }
}

static public function StoreCompressedMetaBlockHeader(final_block:Bool,
                                    length:Int,
                                    storage_ix:Array<Int>,
                                    storage:Vector<UInt>) {
  // Write ISLAST bit.
  WriteBits(1, final_block?1:0, storage_ix, storage);
  // Write ISEMPTY bit.
  if (final_block) {
    WriteBits(1, length == 0?1:0, storage_ix, storage);
    if (length == 0) {
      return true;
    }
  }

  if (length == 0) {
    // Only the last meta-block can be empty.
    return false;
  }

  var lenbits:Array<Int>=new Array();
  var nlenbits:Array<Int>=new Array();
  var nibblesbits:Array<Int>=new Array();
  if (!EncodeMlen(length, lenbits, nlenbits, nibblesbits)) {
    return false;
  }

  WriteBits(2, nibblesbits[0], storage_ix, storage);
  WriteBits(nlenbits[0], lenbits[0], storage_ix, storage);

  if (!final_block) {
    // Write ISUNCOMPRESSED bit.
    WriteBits(1, 0, storage_ix, storage);
  }
  return true;
}

static public function StoreUncompressedMetaBlockHeader(length:Int,
                                      storage_ix:Array<Int>,
                                      storage:Vector<UInt>) {
  // Write ISLAST bit. Uncompressed block cannot be the last one, so set to 0.
  WriteBits(1, 0, storage_ix, storage);
  var lenbits:Array<Int>=new Array();
  var nlenbits:Array<Int>=new Array();
  var nibblesbits:Array<Int>=new Array();
  if (!EncodeMlen(length, lenbits, nlenbits, nibblesbits)) {
    return false;
  }
  WriteBits(2, nibblesbits[0], storage_ix, storage);
  WriteBits(nlenbits[0], lenbits[0], storage_ix, storage);
  // Write ISUNCOMPRESSED bit.
  WriteBits(1, 1, storage_ix, storage);
  return true;
}

static public function StoreHuffmanTreeOfHuffmanTreeToBitMask(
    num_codes:Int,
    code_length_bitdepth:Vector<UInt>,
    storage_ix:Array<Int>,
    storage:Vector<UInt>) {
  var kStorageOrder:Array<UInt> = [//[kCodeLengthCodes]
    1, 2, 3, 4, 0, 5, 17, 6, 16, 7, 8, 9, 10, 11, 12, 13, 14, 15
  ];
  // The bit lengths of the Huffman code over the code length alphabet
  // are compressed with the following static Huffman code:
  //   Symbol   Code
  //   ------   ----
  //   0          00
  //   1        1110
  //   2         110
  //   3          01
  //   4          10
  //   5        1111
  var kHuffmanBitLengthHuffmanCodeSymbols:Array<UInt> = [//[6]
     0, 7, 3, 2, 1, 15
  ];
  var kHuffmanBitLengthHuffmanCodeBitLengths:Array<UInt> = [//[6]
    2, 4, 3, 2, 2, 4
  ];

  // Throw away trailing zeros:
  var codes_to_store:Int = kCodeLengthCodes;
  if (num_codes > 1) {
    while (codes_to_store > 0) {
      if (code_length_bitdepth[kStorageOrder[codes_to_store - 1]] != 0) {
        break;
      }
	  --codes_to_store;
    }
  }
  var skip_some:Int = 0;  // skips none.
  if (code_length_bitdepth[kStorageOrder[0]] == 0 &&
      code_length_bitdepth[kStorageOrder[1]] == 0) {
    skip_some = 2;  // skips two.
    if (code_length_bitdepth[kStorageOrder[2]] == 0) {
      skip_some = 3;  // skips three.
    }
  }
  WriteBits(2, skip_some, storage_ix, storage);
  for (i in skip_some...codes_to_store) {
    var l:UInt = code_length_bitdepth[kStorageOrder[i]];
    WriteBits(kHuffmanBitLengthHuffmanCodeBitLengths[l],
              kHuffmanBitLengthHuffmanCodeSymbols[l], storage_ix, storage);
  }
}

static public function StoreHuffmanTreeToBitMask(
    huffman_tree:Array<UInt>,
    huffman_tree_extra_bits:Array<UInt>,
    code_length_bitdepth:Vector<UInt>,
    code_length_bitdepth_off:Int,
    code_length_bitdepth_symbols:Vector<UInt>,
    storage_ix:Array<Int>,
    storage:Vector<UInt>) {
  for (i in 0...huffman_tree.length) {
    var ix:Int = huffman_tree[i];
    WriteBits(code_length_bitdepth[ix], code_length_bitdepth_symbols[ix],
              storage_ix, storage);
    // Extra bits
    switch (ix) {
      case 16:
        WriteBits(2, huffman_tree_extra_bits[i], storage_ix, storage);
      case 17:
        WriteBits(3, huffman_tree_extra_bits[i], storage_ix, storage);
    }
  }
}

static public function StoreSimpleHuffmanTree(depths:Vector<UInt>,depths_off:Int,
                            symbols:Array<Int>,//[4]
                            num_symbols:Int,
                            max_bits:Int,
                            storage_ix:Array<Int>, storage:Vector<UInt>) {
  // value of 1 indicates a simple Huffman code
  WriteBits(2, 1, storage_ix, storage);
  WriteBits(2, num_symbols - 1, storage_ix, storage);  // NSYM - 1

  // Sort
  for (i in 0...num_symbols) {
    for (j in i + 1...num_symbols) {
      if (depths[depths_off+symbols[j]] < depths[depths_off+symbols[i]]) {
        var t = symbols[j];
        symbols[j] = symbols[i];
        symbols[i] = t;
      }
    }
  }

  if (num_symbols == 2) {
    WriteBits(max_bits, symbols[0], storage_ix, storage);
    WriteBits(max_bits, symbols[1], storage_ix, storage);
  } else if (num_symbols == 3) {
    WriteBits(max_bits, symbols[0], storage_ix, storage);
    WriteBits(max_bits, symbols[1], storage_ix, storage);
    WriteBits(max_bits, symbols[2], storage_ix, storage);
  } else {
    WriteBits(max_bits, symbols[0], storage_ix, storage);
    WriteBits(max_bits, symbols[1], storage_ix, storage);
    WriteBits(max_bits, symbols[2], storage_ix, storage);
    WriteBits(max_bits, symbols[3], storage_ix, storage);
    // tree-select
    WriteBits(1, depths[depths_off+symbols[0]] == 1 ? 1 : 0, storage_ix, storage);
  }
}

// num = alphabet size
// depths = symbol depths
static public function StoreHuffmanTree(depths:Vector<UInt>, depths_off:Int, num:Int,
                      storage_ix:Array<Int>, storage:Vector<UInt>) {
  // Write the Huffman tree into the brotli-representation.
  var huffman_tree:Array<UInt>=new Array();
  var huffman_tree_extra_bits:Array<UInt>=new Array();
  // TODO: Consider allocating these from stack.
  //huffman_tree.reserve(256);
  //huffman_tree_extra_bits.reserve(256);
  WriteHuffmanTree(depths, depths_off, num, huffman_tree, huffman_tree_extra_bits);

  // Calculate the statistics of the Huffman tree in brotli-representation.
  var huffman_tree_histogram = FunctionMalloc.mallocInt(kCodeLengthCodes);
  for (i in 0...huffman_tree.length) {
    huffman_tree_histogram[huffman_tree[i]]+=1;
  }

  var num_codes:Int = 0;
  var code:Int = 0;
  for (i in 0...kCodeLengthCodes) {
    if (huffman_tree_histogram[i]>0) {
      if (num_codes == 0) {
        code = i;
        num_codes = 1;
      } else if (num_codes == 1) {
        num_codes = 2;
        break;
      }
    }
  }

  // Calculate another Huffman tree to use for compressing both the
  // earlier Huffman tree with.
  // TODO: Consider allocating these from stack.
  var code_length_bitdepth = FunctionMalloc.mallocUInt(kCodeLengthCodes);
  var code_length_bitdepth_symbols=FunctionMalloc.mallocUInt(kCodeLengthCodes);
  CreateHuffmanTree(huffman_tree_histogram,0, kCodeLengthCodes,
                    5, code_length_bitdepth,0);
  ConvertBitDepthsToSymbols(code_length_bitdepth,0, kCodeLengthCodes,
                            code_length_bitdepth_symbols,0);

  // Now, we have all the data, let's start storing it
  StoreHuffmanTreeOfHuffmanTreeToBitMask(num_codes, code_length_bitdepth,
                                         storage_ix, storage);

  if (num_codes == 1) {
    code_length_bitdepth[code] = 0;
  }

  // Store the real huffman tree now.
  StoreHuffmanTreeToBitMask(huffman_tree,
                            huffman_tree_extra_bits,
                            code_length_bitdepth,0,
                            code_length_bitdepth_symbols,
                            storage_ix, storage);
}

static public function BuildAndStoreHuffmanTree(histogram:Vector<Int>,
                              length:Int,
                              depth:Vector<UInt>,
                              depth_off:Int,
                              bits:Vector<UInt>,
                              bits_off:Int,
                              storage_ix:Array<Int>,
                              storage:Vector<UInt>) {
  var count:Int = 0;
  var s4:Array<Int> = [ 0,0,0,0 ];//[4]
  for (i in 0...length) {
    if (histogram[i]>0) {
      if (count < 4) {
        s4[count] = i;
      } else if (count > 4) {
        break;
      }
      count++;
    }
  }

  var max_bits_counter:Int = length - 1;
  var max_bits:Int = 0;
  while (max_bits_counter>0) {
    max_bits_counter >>= 1;
    ++max_bits;
  }

  if (count <= 1) {
    WriteBits(4, 1, storage_ix, storage);
    WriteBits(max_bits, s4[0], storage_ix, storage);
    return;
  }

  CreateHuffmanTree(histogram,0, length, 15, depth,depth_off+0);
  ConvertBitDepthsToSymbols(depth,depth_off, length, bits,bits_off);

  if (count <= 4) {
    StoreSimpleHuffmanTree(depth,depth_off, s4, count, max_bits, storage_ix, storage);
  } else {
    StoreHuffmanTree(depth,depth_off, length, storage_ix, storage);
  }
}

static public function IndexOf(v:Vector<Int>, value:Int):Int {
  for (i in 0...v.length) {
    if (v[i] == value) return i;
  }
  return -1;
}

static public function MoveToFront(v:Vector<Int>, index:Int) {
  var value:Int = v[index];
  var i = index;
  while (i > 0) {
    v[i] = v[i - 1];
	--i;
  }
  v[0] = value;
}

static public function MoveToFrontTransform(v:Vector<Int>):Vector<Int> {
  if (v.length==0) return v;
  //TODO:std::vector<int> mtf(*std::max_element(v.begin(), v.end()) + 1);
  var max_element = 0;
  for (i in 0...v.length)
  if(max_element<v[i])
  max_element = v[i];
  var mtf = new Vector<Int>(max_element+1);
  for (i in 0...mtf.length) mtf[i] = i;
  var result = new Vector<Int>(v.length);
  for (i in 0...v.length) {
    var index:Int = IndexOf(mtf, v[i]);
    result[i] = index;
    MoveToFront(mtf, index);
  }
  return result;
}

static public function RunLengthCodeZeros(v_in:Vector<Int>,
                        max_run_length_prefix:Array<Int>,
                        v_out:Array<Int>,
                        extra_bits:Array<Int>) {
  var max_reps:Int = 0;
  var i = 0;
  while (i < v_in.length) {
    while (i < v_in.length && v_in[i] != 0) {++i;};
    var reps:Int = 0;
    while (i < v_in.length && v_in[i] == 0) {
      ++reps;
	  ++i;
    }
    max_reps = Std.int(Math.max(reps, max_reps));
  }
  var max_prefix:Int = max_reps > 0 ? Log2Floor(max_reps) : 0;
  max_run_length_prefix[0] = Std.int(Math.min(max_prefix, max_run_length_prefix[0]));
  var i = 0;
  while (i < v_in.length) {
    if (v_in[i] != 0) {
      v_out.push(v_in[i] + max_run_length_prefix[0]);
      extra_bits.push(0);
      ++i;
    } else {
      var reps:Int = 1;
	  var k = i + 1;
      while (k < v_in.length && v_in[k] == 0) {
        ++reps;
		++k;
      }
      i += reps;
      while (reps>0) {
        if (reps < (2 << max_run_length_prefix[0])) {
          var run_length_prefix:Int = Log2Floor(reps);
          v_out.push(run_length_prefix);
          extra_bits.push(reps - (1 << run_length_prefix));
          break;
        } else {
          v_out.push(max_run_length_prefix[0]);
          extra_bits.push((1 << max_run_length_prefix[0]) - 1);
          reps -= (2 << max_run_length_prefix[0]) - 1;
        }
      }
    }
  }
}

static public function EncodeContextMap(context_map:Vector<Int>,
                      num_clusters:Int,
                      storage_ix:Array<Int>, storage:Vector<UInt>) {
  StoreVarLenUint8(num_clusters - 1, storage_ix, storage);

  if (num_clusters == 1) {
    return;
  }

  var transformed_symbols:Vector<Int> = MoveToFrontTransform(context_map);
  var rle_symbols=new Array();
  var extra_bits=new Array();
  var max_run_length_prefix:Array<Int> = [6];
  RunLengthCodeZeros(transformed_symbols, max_run_length_prefix,
                     rle_symbols, extra_bits);
  var symbol_histogram=HistogramContextMap();
  for (i in 0...rle_symbols.length) {
    symbol_histogram.Add1(rle_symbols[i]);
  }
  var use_rle:Bool = max_run_length_prefix[0] > 0;
  WriteBits(1, use_rle?1:0, storage_ix, storage);
  if (use_rle) {
    WriteBits(4, max_run_length_prefix[0] - 1, storage_ix, storage);
  }
  var symbol_code=EntropyCodeContextMap();
  memset(symbol_code.depth_,0, 0, symbol_code.depth_.length);
  memset(symbol_code.bits_,0, 0, symbol_code.bits_.length);
  BuildAndStoreHuffmanTree(symbol_histogram.data_,
                           num_clusters + max_run_length_prefix[0],
                           symbol_code.depth_,0, symbol_code.bits_,0,
                           storage_ix, storage);
  for (i in 0...rle_symbols.length) {
    WriteBits(symbol_code.depth_[rle_symbols[i]],
              symbol_code.bits_[rle_symbols[i]],
              storage_ix, storage);
    if (rle_symbols[i] > 0 && rle_symbols[i] <= max_run_length_prefix[0]) {
      WriteBits(rle_symbols[i], extra_bits[i], storage_ix, storage);
    }
  }
  WriteBits(1, 1, storage_ix, storage);  // use move-to-front
}

static public function StoreBlockSwitch(code:BlockSplitCode,
                      block_ix:Int,
                      storage_ix:Array<Int>,
                      storage:Vector<UInt>) {
  if (block_ix > 0) {
    var typecode:Int = code.type_code[block_ix];
    WriteBits(code.type_depths[typecode], code.type_bits[typecode],
              storage_ix, storage);
  }
  var lencode:Int = code.length_prefix[block_ix];
  WriteBits(code.length_depths[lencode], code.length_bits[lencode],
            storage_ix, storage);
  WriteBits(code.length_nextra[block_ix], code.length_extra[block_ix],
            storage_ix, storage);
}

static public function BuildAndStoreBlockSplitCode(types:Array<Int>,
                                 lengths:Array<Int>,
                                 num_types:Int,
                                 code:BlockSplitCode,
                                 storage_ix:Array<Int>,
                                 storage:Vector<UInt>) {
  var num_blocks:Int = types.length;
  var type_histo=FunctionMalloc.mallocInt(num_types + 2);
  var length_histo=FunctionMalloc.mallocInt(26);
  var last_type:Int = 1;
  var second_last_type:Int = 0;
  code.type_code=FunctionMalloc.mallocInt(num_blocks);
  code.length_prefix=FunctionMalloc.mallocInt(num_blocks);
  code.length_nextra=FunctionMalloc.mallocInt(num_blocks);
  code.length_extra=FunctionMalloc.mallocInt(num_blocks);
  code.type_depths=FunctionMalloc.mallocUInt(num_types + 2);
  code.type_bits=FunctionMalloc.mallocUInt(num_types + 2);
  code.length_depths=FunctionMalloc.mallocUInt(26);
  code.length_bits=FunctionMalloc.mallocUInt(26);
  for (i in 0...num_blocks) {
    var type:Int = types[i];
    var type_code:Int = (type == last_type + 1 ? 1 :
                     type == second_last_type ? 0 :
                     type + 2);
    second_last_type = last_type;
    last_type = type;
    code.type_code[i] = type_code;
    if (i > 0) type_histo[type_code]+=1;
    GetBlockLengthPrefixCode(lengths[i],
                             code.length_prefix,i,
                             code.length_nextra,i,
                             code.length_extra,i);
    length_histo[code.length_prefix[i]]+=1;
  }
  StoreVarLenUint8(num_types - 1, storage_ix, storage);
  if (num_types > 1) {
    BuildAndStoreHuffmanTree(type_histo, num_types + 2,
                             code.type_depths,0, code.type_bits,0,
                             storage_ix, storage);
    BuildAndStoreHuffmanTree(length_histo, 26,
                             code.length_depths,0, code.length_bits,0,
                             storage_ix, storage);
    StoreBlockSwitch(code, 0, storage_ix, storage);
  }
}

static public function StoreTrivialContextMap(num_types:Int,
                            context_bits:Int,
                            storage_ix:Array<Int>,
                            storage:Vector<UInt>) {
  StoreVarLenUint8(num_types - 1, storage_ix, storage);
  if (num_types > 1) {
    var repeat_code:Int = context_bits - 1;
    var repeat_bits:Int = (1 << repeat_code) - 1;
    var alphabet_size:Int = num_types + repeat_code;
    var histogram=FunctionMalloc.mallocInt(alphabet_size);
    var depths=FunctionMalloc.mallocUInt(alphabet_size);
    var bits=FunctionMalloc.mallocUInt(alphabet_size);
    // Write RLEMAX.
    WriteBits(1, 1, storage_ix, storage);
    WriteBits(4, repeat_code - 1, storage_ix, storage);
    histogram[repeat_code] = num_types;
    histogram[0] = 1;
    for (i in context_bits...alphabet_size) {
      histogram[i] = 1;
    }
    BuildAndStoreHuffmanTree(histogram, alphabet_size,
                             depths,0, bits,0,
                             storage_ix, storage);
    for (i in 0...num_types) {
      var code:Int = (i == 0 ? 0 : i + context_bits - 1);
      WriteBits(depths[code], bits[code], storage_ix, storage);
      WriteBits(depths[repeat_code], bits[repeat_code], storage_ix, storage);
      WriteBits(repeat_code, repeat_bits, storage_ix, storage);
    }
    // Write IMTF (inverse-move-to-front) bit.
    WriteBits(1, 1, storage_ix, storage);
  }
}

static public function JumpToByteBoundary(storage_ix:Array<Int>, storage:Vector<UInt>) {
  storage_ix[0] = (storage_ix[0] + 7) & ~7;
  storage[storage_ix[0] >> 3] = 0;
}

static public function StoreMetaBlock(input:Vector<UInt>,
                    start_pos:Int,
                    length:Int,
                    mask:Int,
                    prev_byte:UInt,
                    prev_byte2:UInt,
                    is_last:Bool,
                    num_direct_distance_codes:Int,
                    distance_postfix_bits:Int,
                    literal_context_mode:Int,
                    commands:Array<Command>,
                    n_commands:Int,
                    mb:MetaBlockSplit,
                    storage_ix:Array<Int>,
                    storage:Vector<UInt>) {
  if (!StoreCompressedMetaBlockHeader(is_last, length, storage_ix, storage)) {
    return false;
  }

  if (length == 0) {
    // Only the last meta-block can be empty, so jump to next byte.
    JumpToByteBoundary(storage_ix, storage);
    return true;
  }

  var num_distance_codes:Int =
      kNumDistanceShortCodes + num_direct_distance_codes +
      (48 << distance_postfix_bits);

  var literal_enc=new BlockEncoder(256,
                           mb.literal_split.num_types,
                           mb.literal_split.types,
                           mb.literal_split.lengths);
  var command_enc=new BlockEncoder(kNumCommandPrefixes,
                           mb.command_split.num_types,
                           mb.command_split.types,
                           mb.command_split.lengths);
  var distance_enc=new BlockEncoder(num_distance_codes,
                            mb.distance_split.num_types,
                            mb.distance_split.types,
                            mb.distance_split.lengths);

  literal_enc.BuildAndStoreBlockSwitchEntropyCodes(storage_ix, storage);
  command_enc.BuildAndStoreBlockSwitchEntropyCodes(storage_ix, storage);
  distance_enc.BuildAndStoreBlockSwitchEntropyCodes(storage_ix, storage);

  WriteBits(2, distance_postfix_bits, storage_ix, storage);
  WriteBits(4, num_direct_distance_codes >> distance_postfix_bits,
            storage_ix, storage);
  for (i in 0...mb.literal_split.num_types) {
    WriteBits(2, literal_context_mode, storage_ix, storage);
  }

  if (mb.literal_context_map.length==0) {
    StoreTrivialContextMap(mb.literal_histograms.length, kLiteralContextBits,
                           storage_ix, storage);
  } else {
    EncodeContextMap(mb.literal_context_map, mb.literal_histograms.length,
                     storage_ix, storage);
  }

  if (mb.distance_context_map.length==0) {
    StoreTrivialContextMap(mb.distance_histograms.length, kDistanceContextBits,
                           storage_ix, storage);
  } else {
    EncodeContextMap(mb.distance_context_map, mb.distance_histograms.length,
                     storage_ix, storage);
  }

  literal_enc.BuildAndStoreEntropyCodes(mb.literal_histograms,
                                        storage_ix, storage);
  command_enc.BuildAndStoreEntropyCodes(mb.command_histograms,
                                        storage_ix, storage);
  distance_enc.BuildAndStoreEntropyCodes(mb.distance_histograms,
                                         storage_ix, storage);

  var pos:Int = start_pos;
  for (i in 0...n_commands) {
    var cmd:Command = commands[i];
    var cmd_code:Int = cmd.cmd_prefix_[0];
    var lennumextra:Int = cmd.cmd_extra_[0] >> 16;
    var lenextra:Array<UInt> = cmd.cmd_extra_;//[0] & 0xfffffff;
    command_enc.StoreSymbol(cmd_code, storage_ix, storage);
	if(lennumextra>=32)
    WriteBits(lennumextra-32, lenextra[0], storage_ix, storage);
    WriteBits(lennumextra<32?lennumextra:32, lenextra[1], storage_ix, storage);
    if (mb.literal_context_map.length==0) {
      for (j in 0...cmd.insert_len_) {
        literal_enc.StoreSymbol(input[pos & mask], storage_ix, storage);
        ++pos;
      }
    } else {
      for (j in 0...cmd.insert_len_) {
        var context:Int = ContextFunction(prev_byte, prev_byte2,
                              literal_context_mode);
        var literal:Int = input[pos & mask];
        literal_enc.StoreSymbolWithContext(kLiteralContextBits,
            literal, context, mb.literal_context_map, storage_ix, storage);
        prev_byte2 = prev_byte;
        prev_byte = literal;
        ++pos;
      }
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0) {
      prev_byte2 = input[(pos - 2) & mask];
      prev_byte = input[(pos - 1) & mask];
      if (cmd.cmd_prefix_[0] >= 128) {
        var dist_code:Int = cmd.dist_prefix_[0];
        var distnumextra:Int = cmd.dist_extra_[0] >> 24;
        var distextra:Int = cmd.dist_extra_[0] & 0xffffff;
        if (mb.distance_context_map.length==0) {
        distance_enc.StoreSymbol(dist_code, storage_ix, storage);
        } else {
          var context:Int = cmd.DistanceContext();
          distance_enc.StoreSymbolWithContext(kDistanceContextBits,
              dist_code, context, mb.distance_context_map, storage_ix, storage);
        }
        WriteBits(distnumextra, distextra, storage_ix, storage);
      }
    }
  }
  if (is_last) {
    JumpToByteBoundary(storage_ix, storage);
  }
  return true;
}

static public function StoreMetaBlockTrivial(input:Vector<UInt>,
                           start_pos:Int,
                           length:Int,
                           mask:Int,
                           is_last:Bool,
                           commands:Array<Command>,
                           n_commands:Int,
                           storage_ix:Array<Int>,
                           storage:Vector<UInt>,
                           storage_off:Int) {
  if (!StoreCompressedMetaBlockHeader(is_last, length, storage_ix, storage)) {//,0
    return false;
  }

  if (length == 0) {
    // Only the last meta-block can be empty, so jump to next byte.
    JumpToByteBoundary(storage_ix, storage);
    return true;
  }

  var lit_histo=HistogramLiteral();
  var cmd_histo=HistogramCommand();
  var dist_histo=HistogramDistance();

  var pos:Int = start_pos;
  for (i in 0...n_commands) {
    var  cmd:Command = commands[i];
    cmd_histo.Add1(cmd.cmd_prefix_[0]);
    for (j in 0...cmd.insert_len_) {
      lit_histo.Add1(input[pos & mask]);
      ++pos;
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0 && cmd.cmd_prefix_[0] >= 128) {
      dist_histo.Add1(cmd.dist_prefix_[0]);
    }
  }

  WriteBits(13, 0, storage_ix, storage);

  var lit_depth=FunctionMalloc.mallocUInt(256);
  var lit_bits=FunctionMalloc.mallocUInt(256);
  var cmd_depth=FunctionMalloc.mallocUInt(kNumCommandPrefixes);
  var cmd_bits=FunctionMalloc.mallocUInt(kNumCommandPrefixes);
  var dist_depth=FunctionMalloc.mallocUInt(64);
  var dist_bits=FunctionMalloc.mallocUInt(64);

  BuildAndStoreHuffmanTree(lit_histo.data_, 256,
                           lit_depth,0, lit_bits,0,
                           storage_ix, storage);
  BuildAndStoreHuffmanTree(cmd_histo.data_, kNumCommandPrefixes,
                           cmd_depth,0, cmd_bits,0,
                           storage_ix, storage);
  BuildAndStoreHuffmanTree(dist_histo.data_, 64,
                           dist_depth,0, dist_bits,0,
                           storage_ix, storage);

  pos = start_pos;
  for (i in 0...n_commands) {
    var cmd:Command = commands[i];
    var cmd_code:Int = cmd.cmd_prefix_[0];
    var lennumextra:Int = cmd.cmd_extra_[0] >> 16;
    var lenextra:Array<UInt> = cmd.cmd_extra_;//[0] & 0xffffffff;
    WriteBits(cmd_depth[cmd_code], cmd_bits[cmd_code], storage_ix, storage);
	if(lennumextra>=32)
    WriteBits(lennumextra-32, lenextra[0], storage_ix, storage);
    WriteBits(lennumextra<32?lennumextra:32, lenextra[1], storage_ix, storage);
    for (j in 0...cmd.insert_len_) {
      var literal:UInt = input[pos & mask];
      WriteBits(lit_depth[literal], lit_bits[literal], storage_ix, storage);
      ++pos;
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0 && cmd.cmd_prefix_[0] >= 128) {
      var dist_code:Int = cmd.dist_prefix_[0];
      var distnumextra:Int = cmd.dist_extra_[0] >> 24;
      var distextra:Int = cmd.dist_extra_[0] & 0xffffff;
      WriteBits(dist_depth[dist_code], dist_bits[dist_code],
                storage_ix, storage);
      WriteBits(distnumextra, distextra, storage_ix, storage);
    }
  }
  if (is_last) {
    JumpToByteBoundary(storage_ix, storage);
  }
  return true;
}

// This is for storing uncompressed blocks (simple raw storage of
// bytes-as-bytes).
static public function StoreUncompressedMetaBlock(final_block:Bool,
                                input:Vector<UInt>,
                                position:Int, mask:Int,
                                len:Int,
                                storage_ix:Array<Int>,
                                storage:Vector<UInt>,
                                storage_off:Int) {
  if (!StoreUncompressedMetaBlockHeader(len, storage_ix, storage)) {
    return false;
  }
  JumpToByteBoundary(storage_ix, storage);

  var masked_pos:Int = position & mask;
  if (masked_pos + len > mask + 1) {
    var len1:Int = mask + 1 - masked_pos;
    memcpy(storage,storage_ix[0] >> 3, input,masked_pos, len1);
    storage_ix[0] += len1 << 3;
    len -= len1;
    masked_pos = 0;
  }
  memcpy(storage,storage_ix[0] >> 3, input,masked_pos, len);
  storage_ix[0] += len << 3;

  // We need to clear the next 4 bytes to continue to be
  // compatible with WriteBits.
  WriteBitsPrepareStorage(storage_ix[0], storage);

  // Since the uncomressed block itself may not be the final block, add an empty
  // one after this.
  if (final_block) {
    WriteBits(1, 1, storage_ix, storage);  // islast
    WriteBits(1, 1, storage_ix, storage);  // isempty
    JumpToByteBoundary(storage_ix, storage);
  }
  return true;
}

	public function new() 
	{
		
	}
	
}
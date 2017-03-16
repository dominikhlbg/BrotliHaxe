package encode;
import haxe.ds.Vector;
import encode.entropy_encode.HuffmanTree;
import DefaultFunctions.*;
import encode.entropy_encode.EntropyCode;
import encode.Prefix.*;

/**
 * ...
 * @author 
 */
class Entropy_encode
{
	public static inline var kCodeLengthCodes:Int = 18;

// Literal entropy code.
public static function EntropyCodeLiteral() { return new EntropyCode(256); };
// Prefix entropy codes.
public static function EntropyCodeCommand() { return new EntropyCode(kNumCommandPrefixes); };
public static function EntropyCodeDistance() { return new EntropyCode(kNumDistancePrefixes); };
public static function EntropyCodeBlockLength() { return new EntropyCode(kNumBlockLenPrefixes); };
// Context map entropy code, 256 Huffman tree indexes + 16 run length codes.
public static function EntropyCodeContextMap() { return new EntropyCode(272); };
// Block type entropy code, 256 block types + 2 special symbols.
public static function EntropyCodeBlockType() { return new EntropyCode(258); };

public static function SortHuffmanTree(v0:HuffmanTree, v1:HuffmanTree):Int {
  if (v0.total_count_ == v1.total_count_)
    return v1.index_right_or_value_ - v0.index_right_or_value_;
  if (v0.total_count_ < v1.total_count_)
    return -1;
  return 1;
}

public static function SetDepth(p:HuffmanTree,
               pool:Array<HuffmanTree>,
			   pool_off:Int,
              depth:Vector<UInt>,
              depth_off:Int,
              level:Int) {
  if (p.index_left_ >= 0) {
    ++level;
    SetDepth(pool[pool_off+p.index_left_], pool,pool_off, depth, depth_off, level);
    SetDepth(pool[pool_off+p.index_right_or_value_], pool,pool_off, depth, depth_off, level);
  } else {
    depth[depth_off+p.index_right_or_value_] = level;
  }
}

public static function CreateHuffmanTree(data:Vector<Int>,
                       data_off:Int,
                       length:Int,
                       tree_limit:Int,
                       depth:Vector<UInt>,
                       depth_off:Int) {
  // For block sizes below 64 kB, we never need to do a second iteration
  // of this loop. Probably all of our block sizes will be smaller than
  // that, so this loop is mostly of academic interest. If we actually
  // would need this, we would be better off with the Katajainen algorithm.
  var count_limit = 1;
  while (true) {
    var tree:Array<HuffmanTree>;
    tree = new Array<HuffmanTree>();// (2 * length + 1);
	var tree_off:Int = 0;

    var i = length - 1;
	while (i >= 0) {
      if (data[i]>0) {
        var count:Int = Std.int(Math.max(data[i], count_limit));
        var huffmantree = new HuffmanTree();
        huffmantree.HuffmanTree3(count, -1, i);
        tree[tree_off++]=huffmantree;
      }
	  --i;
    }

    var n:Int = tree.length;
    if (n == 1) {
      depth[depth_off+tree[0].index_right_or_value_] = 1;      // Only one element.
      break;
    }

    tree.sort(SortHuffmanTree);

    // The nodes are:
    // [0, n): the sorted leaf nodes that we start with.
    // [n]: we add a sentinel here.
    // [n + 1, 2n): new parent nodes are added here, starting from
    //              (n+1). These are naturally in ascending order.
    // [2n]: we add a sentinel at the end as well.
    // There will be (2n+1) elements at the end.
	var huffmantree = new HuffmanTree();
	huffmantree.HuffmanTree3(0x7fffffff, -1, -1);
    var sentinel=huffmantree;
    tree[tree_off++]=sentinel;
	var huffmantree = new HuffmanTree();
	huffmantree.HuffmanTree3(0x7fffffff, -1, -1);
    var sentinel=huffmantree;
    tree[tree_off++]=sentinel;

    var i:Int = 0;      // Points to the next leaf node.
    var j:Int = n + 1;  // Points to the next non-leaf node.
	var k = n - 1;
    while (k > 0) {
      var left:Int, right:Int;
      if (tree[i].total_count_ <= tree[j].total_count_) {
        left = i;
        ++i;
      } else {
        left = j;
        ++j;
      }
      if (tree[i].total_count_ <= tree[j].total_count_) {
        right = i;
        ++i;
      } else {
        right = j;
        ++j;
      }

      // The sentinel node becomes the parent node.
      var j_end:Int = tree.length - 1;
      tree[j_end].total_count_ =
          tree[left].total_count_ + tree[right].total_count_;
      tree[j_end].index_left_ = left;
      tree[j_end].index_right_or_value_ = right;

      // Add back the last sentinel node.
      var huffmantree = new HuffmanTree();
      huffmantree.HuffmanTree3(0x7fffffff, -1, -1);
      var sentinel=huffmantree;
      tree[tree_off++]=sentinel;
	  --k;
    }
    SetDepth(tree[2 * n - 1], tree,0, depth, depth_off,0);

    // We need to pack the Huffman tree in tree_limit bits.
    // If this was not successful, add fake entities to the lowest values
    // and retry.
	var max_element = 0;
	for (i in depth_off+0...depth_off+length)
	if (depth[i] > max_element)
	max_element = depth[i];
    if (max_element <= tree_limit) {
      break;
    }
	count_limit *= 2;
  }
}

public static function Reverse(v:Array<UInt>, start:Int, end:Int) {
  --end;
  while (start < end) {
    var tmp:Int = v[start];
    v[start] = v[end];
    v[end] = tmp;
    ++start;
    --end;
  }
}

public static function WriteHuffmanTreeRepetitions(
    previous_value:Int,
    value:Int,
    repetitions:Int,
    tree:Array<UInt>,
    extra_bits_data:Array<UInt>) {
  if (previous_value != value) {
    tree.push(value);
    extra_bits_data.push(0);
    --repetitions;
  }
  if (repetitions == 7) {
    tree.push(value);
    extra_bits_data.push(0);
    --repetitions;
  }
  if (repetitions < 3) {
    for (i in 0...repetitions) {
      tree.push(value);
      extra_bits_data.push(0);
    }
  } else {
    repetitions -= 3;
    var start:Int = tree.length;
    while (repetitions >= 0) {
      tree.push(16);
      extra_bits_data.push(repetitions & 0x3);
      repetitions >>= 2;
      --repetitions;
    }
    Reverse(tree, start, tree.length);
    Reverse(extra_bits_data, start, tree.length);
  }
}

public static function WriteHuffmanTreeRepetitionsZeros(
    repetitions:Int,
    tree:Array<UInt>,
    extra_bits_data:Array<UInt>) {
  if (repetitions == 11) {
    tree.push(0);
    extra_bits_data.push(0);
    --repetitions;
  }
  if (repetitions < 3) {
    for (i in 0...repetitions) {
      tree.push(0);
      extra_bits_data.push(0);
    }
  } else {
    repetitions -= 3;
    var start:Int = tree.length;
    while (repetitions >= 0) {
      tree.push(17);
      extra_bits_data.push(repetitions & 0x7);
      repetitions >>= 3;
      --repetitions;
    }
    Reverse(tree, start, tree.length);
    Reverse(extra_bits_data, start, tree.length);
  }
}

public static function OptimizeHuffmanCountsForRle(length:Int, counts:Vector<Int>):Int {
  var nonzero_count:Int = 0;
  var stride:Int;
  var limit:Int;
  var sum:Int;
  var good_for_rle:Vector<UInt>;
  // Let's make the Huffman code more compatible with rle encoding.
  var i:Int;
  for (i in 0...length) {
    if (counts[i]>0) {
      ++nonzero_count;
    }
  }
  if (nonzero_count < 16) {
    return 1;
  }
  while (length >= 0) {
    if (length == 0) {
      return 1;  // All zeros.
    }
    if (counts[length - 1] != 0) {
      // Now counts[0..length - 1] does not have trailing zeros.
      break;
    }
	--length;
  }
  {
    var nonzeros:Int = 0;
    var smallest_nonzero:Int = 1 << 30;
    for (i in 0...length) {
      if (counts[i] != 0) {
        ++nonzeros;
        if (smallest_nonzero > counts[i]) {
          smallest_nonzero = counts[i];
        }
      }
    }
    if (nonzeros < 5) {
      // Small histogram will model it well.
      return 1;
    }
    var zeros:Int = length - nonzeros;
    if (smallest_nonzero < 4) {
      if (zeros < 6) {
        for (i in 1...length - 1) {
          if (counts[i - 1] != 0 && counts[i] == 0 && counts[i + 1] != 0) {
            counts[i] = 1;
          }
        }
      }
    }
    if (nonzeros < 28) {
      return 1;
    }
  }
  // 2) Let's mark all population counts that already can be encoded
  // with an rle code.
  good_for_rle = FunctionMalloc.mallocUInt(length);//TODO:, 1
  if (good_for_rle == null) {
    return 0;
  }
  {
    // Let's not spoil any of the existing good rle codes.
    // Mark any seq of 0's that is longer as 5 as a good_for_rle.
    // Mark any seq of non-0's that is longer as 7 as a good_for_rle.
    var symbol:Int = counts[0];
    var stride:Int = 0;
    for (i in 0...length + 1) {
      if (i == length || counts[i] != symbol) {
        if ((symbol == 0 && stride >= 5) ||
            (symbol != 0 && stride >= 7)) {
          var k:Int;
          for (k in 0...stride) {
            good_for_rle[i - k - 1] = 1;
          }
        }
        stride = 1;
        if (i != length) {
          symbol = counts[i];
        }
      } else {
        ++stride;
      }
    }
  }
  // 3) Let's replace those population counts that lead to more rle codes.
  // Math here is in 24.8 fixed point representation.
  var streak_limit:Int = 1240;
  stride = 0;
  limit = Std.int(256 * (counts[0] + counts[1] + counts[2]) / 3) + 420;
  sum = 0;
  for (i in 0...length + 1) {
    if (i == length || good_for_rle[i]>0 ||
        (i != 0 && good_for_rle[i - 1]>0) ||
        Math.abs(256 * counts[i] - limit) >= streak_limit) {
      if (stride >= 4 || (stride >= 3 && sum == 0)) {
        var k:Int;
        // The stride must end, collapse what we have, if we have enough (4).
        var count:Int = Std.int((sum + Std.int(stride / 2)) / stride);
        if (count < 1) {
          count = 1;
        }
        if (sum == 0) {
          // Don't make an all zeros stride to be upgraded to ones.
          count = 0;
        }
        for (k in 0...stride) {
          // We don't want to change value at counts[i],
          // that is already belonging to the next stride. Thus - 1.
          counts[i - k - 1] = count;
        }
      }
      stride = 0;
      sum = 0;
      if (i < length - 2) {
        // All interesting strides have a count of at least 4,
        // at least when non-zeros.
        limit = Std.int(256 * (counts[i] + counts[i + 1] + counts[i + 2]) / 3) + 420;
      } else if (i < length) {
        limit = 256 * counts[i];
      } else {
        limit = 0;
      }
    }
    ++stride;
    if (i != length) {
      sum += counts[i];
      if (stride >= 4) {
        limit = Std.int((256 * sum + Std.int(stride / 2)) / stride);
      }
      if (stride == 4) {
        limit += 120;
      }
    }
  }
  //TODO:free(good_for_rle);
  return 1;
}

public static function DecideOverRleUse(depth:Vector<UInt>, depth_off:Int, length:Int,
                             use_rle_for_non_zero:Array<Bool>,
                             use_rle_for_zero:Array<Bool>) {
  var total_reps_zero:Int = 0;
  var total_reps_non_zero:Int = 0;
  var count_reps_zero:Int = 0;
  var count_reps_non_zero:Int = 0;
  var i = 0;
  while (i < length) {
    var value:Int = depth[depth_off+i];
    var reps:Int = 1;
	var k = i + 1;
    while (k < length && depth[depth_off+k] == value) {
      ++reps;
      ++k;
    }
    if (reps >= 3 && value == 0) {
      total_reps_zero += reps;
      ++count_reps_zero;
    }
    if (reps >= 4 && value != 0) {
      total_reps_non_zero += reps;
      ++count_reps_non_zero;
    }
    i += reps;
  }
  total_reps_non_zero -= count_reps_non_zero * 2;
  total_reps_zero -= count_reps_zero * 2;
  use_rle_for_non_zero[0] = total_reps_non_zero > 2;
  use_rle_for_zero[0] = total_reps_zero > 2;
}

public static function WriteHuffmanTree(depth:Vector<UInt>,depth_off:Int,
                      length:UInt,
                      tree:Array<UInt>,
                      extra_bits_data:Array<UInt>) {
  var previous_value:Int = 8;

  // Throw away trailing zeros.
  var new_length:Int = length;
  for (i in 0...length) {
    if (depth[depth_off+length - i - 1] == 0) {
      --new_length;
    } else {
      break;
    }
  }

  // First gather statistics on if it is a good idea to do rle.
  var use_rle_for_non_zero:Array<Bool> = [false];
  var use_rle_for_zero:Array<Bool> = [false];
  if (length > 50) {
    // Find rle coding for longer codes.
    // Shorter codes seem not to benefit from rle.
    DecideOverRleUse(depth,depth_off, new_length,
                     use_rle_for_non_zero, use_rle_for_zero);
  }

  // Actual rle coding.
  var i = 0;
  while (i < new_length) {
    var value:Int = depth[depth_off+i];
    var reps:Int = 1;
    if ((value != 0 && use_rle_for_non_zero[0]) ||
        (value == 0 && use_rle_for_zero[0])) {
      var k = i + 1;
      while (k < new_length && depth[depth_off+k] == value) {
        ++reps;
		++k;
      }
    }
    if (value == 0) {
      WriteHuffmanTreeRepetitionsZeros(reps, tree, extra_bits_data);
    } else {
      WriteHuffmanTreeRepetitions(previous_value,
                                  value, reps, tree, extra_bits_data);
      previous_value = value;
    }
    i += reps;
  }
}

public static function ReverseBits(num_bits:Int, bits:UInt):UInt {
  var kLut:Array<Int> = [  // Pre-reversed 4-bit values.
    0x0, 0x8, 0x4, 0xc, 0x2, 0xa, 0x6, 0xe,
    0x1, 0x9, 0x5, 0xd, 0x3, 0xb, 0x7, 0xf
  ];
  var retval:Int = kLut[bits & 0xf];
  var i = 4;
  while (i < num_bits) {
    retval <<= 4;
    bits >>= 4;
    retval |= kLut[bits & 0xf];
	i += 4;
  }
  retval >>= (-num_bits & 0x3);
  return retval;
}

public static function ConvertBitDepthsToSymbols(depth:Vector<UInt>, depth_off:Int, len:Int, bits:Vector<UInt>, bits_off:Int) {
  // In Brotli, all bit depths are [1..15]
  // 0 bit depth means that the symbol does not exist.
  var kMaxBits:Int = 16;  // 0..15 are values for bits
  var bl_count = FunctionMalloc.mallocUInt(kMaxBits);// { 0 };
  {
    for (i in 0...len) {
      bl_count[depth[depth_off+i]]+=1;
    }
    bl_count[0] = 0;
  }
  var next_code:Vector<UInt>=new Vector<UInt>(kMaxBits);
  next_code[0] = 0;
  {
    var code:Int = 0;
    for (_bits in 1...kMaxBits) {
      code = (code + bl_count[_bits - 1]) << 1;
      next_code[_bits] = code;
    }
  }
  for (i in 0...len) {
    if (depth[depth_off+i]>0) {
      bits[bits_off+i] = ReverseBits(depth[depth_off+i], next_code[depth[depth_off+i]]);
	  next_code[depth[depth_off + i]] += 1;
    }
  }
}

	public function new() 
	{
		
	}
	
}
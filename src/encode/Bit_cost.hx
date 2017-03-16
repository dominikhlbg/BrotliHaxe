package encode;
import encode.histogram.Histogram;
import haxe.ds.Vector;
import encode.Fast_log.*;
import encode.Entropy_encode.*;

/**
 * ...
 * @author 
 */
class Bit_cost
{

public static function BitsEntropy(population:Vector<Int>, population_off:Int, size:Int):Float {// inline
  var sum:Int = 0;
  var retval:Float = 0;
  var population_end:Vector<Int> = population;
  var population_end_off:Int = population_off+ size;
  var p:Int;
  if ((size & 1)>0) {
    p = population[population_off++];
    sum += p;
    retval -= p * FastLog2(p);
  }
  while (population_off < population_end_off) {
    p = population[population_off++];
    sum += p;
    retval -= p * FastLog2(p);
    p = population[population_off++];
    sum += p;
    retval -= p * FastLog2(p);
  }
  if (sum>0) retval += sum * FastLog2(sum);
  if (retval < sum) {
    // At least one bit per literal is needed.
    retval = sum;
  }
  return retval;
}

public static function PopulationCost(histogram:Histogram):Float {
	var kSize:Int = histogram.data_.length;//TODO:
  if (histogram.total_count_ == 0) {
    return 12;
  }
  var count:Int = 0;
  for (i in 0...kSize) {
    if (histogram.data_[i] > 0) {
      ++count;
    }
  }
  if (count == 1) {
    return 12;
  }
  if (count == 2) {
    return 20 + histogram.total_count_;
  }
  var bits:Float = 0;
  var depth = FunctionMalloc.mallocUInt(kSize);// { 0 };
  if (count <= 4) {
    // For very low symbol count we build the Huffman tree.
    CreateHuffmanTree(histogram.data_,0, kSize, 15, depth,0);
    for (i in 0...kSize) {
      bits += histogram.data_[i] * depth[i];
    }
    return count == 3 ? bits + 28 : bits + 37;
  }

  // In this loop we compute the entropy of the histogram and simultaneously
  // build a simplified histogram of the code length codes where we use the
  // zero repeat code 17, but we don't use the non-zero repeat code 16.
  var max_depth:Int = 1;
  var depth_histo = FunctionMalloc.mallocInt(kCodeLengthCodes);// { 0 };
  var log2total:Float = FastLog2(histogram.total_count_);
  var i = 0;
  while (i < kSize) {
    if (histogram.data_[i] > 0) {
      // Compute -log2(P(symbol)) = -log2(count(symbol)/total_count) =
      //                          =  log2(total_count) - log2(count(symbol))
      var log2p:Float = log2total - FastLog2(histogram.data_[i]);
      // Approximate the bit depth by round(-log2(P(symbol)))
      var depth:Int = Std.int(log2p + 0.5);
      bits += histogram.data_[i] * log2p;
      if (depth > 15) {
        depth = 15;
      }
      if (depth > max_depth) {
        max_depth = depth;
      }
      depth_histo[depth]+=1;
      ++i;
    } else {
      // Compute the run length of zeros and add the appropiate number of 0 and
      // 17 code length codes to the code length code histogram.
      var reps:Int = 1;
	  var k = i + 1;
      while (k < kSize && histogram.data_[k] == 0) {
        ++reps;
		++k;
      }
      i += reps;
      if (i == kSize) {
        // Don't add any cost for the last zero run, since these are encoded
        // only implicitly.
        break;
      }
      if (reps < 3) {
        depth_histo[0] += reps;
      } else {
        reps -= 2;
        while (reps > 0) {
          depth_histo[17]+=1;
          // Add the 3 extra bits for the 17 code length code.
          bits += 3;
          reps >>= 3;
        }
      }
    }
  }
  // Add the estimated encoding cost of the code length code histogram.
  bits += 18 + 2 * max_depth;
  // Add the entropy of the code length code histogram.
  bits += BitsEntropy(depth_histo,0, kCodeLengthCodes);
  return bits;
}

	public function new() 
	{
		
	}
	
}
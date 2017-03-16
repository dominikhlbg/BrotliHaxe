package encode.hash;
import haxe.ds.Vector;
import encode.Hash.*;
import encode.Find_match_length.*;
import encode.Port.*;
import encode.Dictionary_hash.*;
import encode.Dictionary.*;
import DefaultFunctions.*;

/**
 * ...
 * @author 
 */
class HashLongestMatchQuickly
{
	public function Reset() {
    // It is not strictly necessary to fill this buffer here, but
    // not filling will make the results of the compression stochastic
    // (but correct). This is because random data would cause the
    // system to find accidentally good backward references here and there.
	memset(buckets_, 0, 0, buckets_.length);
    num_dict_lookups_ = 0;
    num_dict_matches_ = 0;
  }
  // Look at 4 bytes at data.
  // Compute a hash from these, and store the value somewhere within
  // [ix .. ix+3].
	public function Store(data:Vector<UInt>,data_off:Int, ix:Int) {// inline
    var key:UInt = Hash_(kBucketBits,data,data_off);
    // Wiggle the value with the bucket sweep range.
    var off = (ix >> 3) % kBucketSweep;
    buckets_[key + off] = ix;
  }

  // Find a longest backward match of &ring_buffer[cur_ix & ring_buffer_mask]
  // up to the length of max_length.
  //
  // Does not look for matches longer than max_length.
  // Does not look for matches further away than max_backward.
  // Writes the best found match length into best_len_out.
  // Writes the index (&data[index]) of the start of the best match into
  // best_distance_out.
  public function FindLongestMatch(ring_buffer:Vector<UInt>,
                               ring_buffer_mask:Int,
                               distance_cache:Vector<Int>,
                               cur_ix:Int,
                               max_length:Int,
                               max_backward:Int,
                               best_len_out:Array<Int>,
                               best_len_code_out:Array<Int>,
                               best_distance_out:Array<Int>,
                               best_score_out:Array<Float>):Bool {
    var best_len_in:Int = best_len_out[0];
    var cur_ix_masked:Int = cur_ix & ring_buffer_mask;
    var compare_char:Int = ring_buffer[cur_ix_masked + best_len_in];
    var best_score:Float = best_score_out[0];
    var best_len:Int = best_len_in;
    var backward:Int = distance_cache[0];
    var prev_ix:UInt = cur_ix - backward;
    var match_found:Bool = false;
    if (prev_ix < cur_ix) {
      prev_ix &= ring_buffer_mask;
      if (compare_char == ring_buffer[prev_ix + best_len]) {
        var len:Int = FindMatchLengthWithLimit(ring_buffer,prev_ix,
                                           ring_buffer,cur_ix_masked,
                                           max_length);
        if (len >= 4) {
          best_score = BackwardReferenceScoreUsingLastDistance(len, 0);
          best_len = len;
          best_len_out[0] = len;
          best_len_code_out[0] = len;
          best_distance_out[0] = backward;
          best_score_out[0] = best_score;
          compare_char = ring_buffer[cur_ix_masked + best_len];
          if (kBucketSweep == 1) {
            return true;
          } else {
            match_found = true;
          }
        }
      }
    }
    var key:UInt = Hash_(kBucketBits,ring_buffer,cur_ix_masked);
    if (kBucketSweep == 1) {
      // Only one to look for, don't bother to prepare for a loop.
      prev_ix = buckets_[key];
      backward = cur_ix - prev_ix;
      prev_ix &= ring_buffer_mask;
      if (compare_char != ring_buffer[prev_ix + best_len_in]) {
        return false;
      }
      if (PREDICT_FALSE(backward == 0 || backward > max_backward)) {
        return false;
      }
      var len:Int = FindMatchLengthWithLimit(ring_buffer,prev_ix,
                                               ring_buffer,cur_ix_masked,
                                               max_length);
      if (len >= 4) {
        best_len_out[0] = len;
        best_len_code_out[0] = len;
        best_distance_out[0] = backward;
        best_score_out[0] = BackwardReferenceScore(len, backward);
        return true;
      }
    } else {
      var bucket:Vector<UInt> = buckets_;
	  var bucket_off:Int = 0+ key;
      //prev_ix = bucket[bucket_off++];//TODO:
      for (i in 0...kBucketSweep) {
		prev_ix = bucket[bucket_off++];
        var backward:Int = cur_ix - prev_ix;
        prev_ix &= ring_buffer_mask;
        if (compare_char != ring_buffer[prev_ix + best_len]) {
          continue;
        }
        if (PREDICT_FALSE(backward == 0 || backward > max_backward)) {
          continue;
        }
        var len:Int =
            FindMatchLengthWithLimit(ring_buffer,prev_ix,
                                     ring_buffer,cur_ix_masked,
                                     max_length);
        if (len >= 4) {
          var score:Float = BackwardReferenceScore(len, backward);
          if (best_score < score) {
            best_score = score;
            best_len = len;
            best_len_out[0] = best_len;
            best_len_code_out[0] = best_len;
            best_distance_out[0] = backward;
            best_score_out[0] = score;
            compare_char = ring_buffer[cur_ix_masked + best_len];
            match_found = true;
          }
        }
      }
    }
    if (kUseDictionary && !match_found &&
        num_dict_matches_ >= (num_dict_lookups_ >> 7)) {
      ++num_dict_lookups_;
      var key:UInt = Hash_(14,ring_buffer,cur_ix_masked) << 1;
      var v:UInt = kStaticDictionaryHash[key];
      if (v > 0) {
        var len:Int = v & 31;
        var dist:Int = v >> 5;
        var offset:Int = kBrotliDictionaryOffsetsByLength[len] + len * dist;
        if (len <= max_length) {
          var matchlen:Int =
              FindMatchLengthWithLimit(ring_buffer,cur_ix_masked,
                                       kBrotliDictionary,offset, len);
          if (matchlen == len) {
            var backward:Int = max_backward + dist + 1;
            var score:Float = BackwardReferenceScore(len, backward);
            if (best_score < score) {
              ++num_dict_matches_;
              best_score = score;
              best_len = len;
              best_len_out[0] = best_len;
              best_len_code_out[0] = best_len;
              best_distance_out[0] = backward;
              best_score_out[0] = best_score;
              return true;
            }
          }
        }
      }
    }
    return match_found;
  }

	public function new(kBucketBits:Int, kBucketSweep:Int, kUseDictionary:Bool) 
	{
		this.kBucketBits = kBucketBits;
		this.kBucketSweep = kBucketSweep;
		this.kUseDictionary = kUseDictionary;
	kBucketSize = 1 << kBucketBits;
	buckets_=new Vector<UInt>(kBucketSize + kBucketSweep);
    Reset();
	}
	public var kBucketBits:Int; public var kBucketSweep:Int; public var kUseDictionary:Bool;
	
	var kBucketSize:UInt;
	var buckets_:Vector<UInt>;
	var num_dict_lookups_:Int;
	var num_dict_matches_:Int;
}
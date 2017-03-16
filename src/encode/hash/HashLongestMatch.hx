package encode.hash;
import haxe.ds.Vector;
import encode.Hash.*;
import encode.Port.*;
import encode.Find_match_length.*;
import encode.Static_dict.*;
import encode.Dictionary.*;
import encode.Dictionary_hash.*;
import DefaultFunctions.*;

/**
 * ...
 * @author 
 */
class HashLongestMatch
{

  public function Reset() {// inline
	memset(num_, 0, 0, num_.length);
    num_dict_lookups_ = 0;
    num_dict_matches_ = 0;
  }

  // Look at 3 bytes at data.
  // Compute a hash from these, and store the value of ix at that position.
	public function Store(data:Vector<UInt>,data_off:Int, ix:Int) {// inline
    var key:UInt = Hash_(kBucketBits,data,data_off);
    var minor_ix:Int = num_[key] & kBlockMask;
	if (buckets_[key] == null) buckets_[key] = new Vector(kBlockSize);
    buckets_[key][minor_ix] = ix;
    num_[key]+=1;
  }

  // Find a longest backward match of &data[cur_ix] up to the length of
  // max_length.
  //
  // Does not look for matches longer than max_length.
  // Does not look for matches further away than max_backward.
  // Writes the best found match length into best_len_out.
  // Writes the index (&data[index]) offset from the start of the best match
  // into best_distance_out.
  // Write the score of the best match into best_score_out.
  public function FindLongestMatch(data:Vector<UInt>,
                        ring_buffer_mask:Int,
                        distance_cache:Vector<Int>,
                        cur_ix:UInt,
                        max_length:UInt,
                        max_backward:UInt,
                        best_len_out:Array<Int>,
                        best_len_code_out:Array<Int>,
                        best_distance_out:Array<Int>,
                        best_score_out:Array<Float>) {
    best_len_code_out[0] = 0;
    var cur_ix_masked:Int = cur_ix & ring_buffer_mask;
    var match_found:Bool = false;
    // Don't accept a short copy from far away.
    var best_score:Float = best_score_out[0];
    var best_len:Int = best_len_out[0];
    best_len_out[0] = 0;
    // Try last distance first.
    for (i in 0...kNumLastDistancesToCheck) {
      var idx:Int = kDistanceCacheIndex[i];
      var backward:Int = distance_cache[idx] + kDistanceCacheOffset[i];
      var prev_ix:UInt = cur_ix - backward;
      if (prev_ix >= cur_ix) {
        continue;
      }
      if (PREDICT_FALSE(backward > max_backward)) {
        continue;
      }
      prev_ix &= ring_buffer_mask;

      if (cur_ix_masked + best_len > ring_buffer_mask ||
          prev_ix + best_len > ring_buffer_mask ||
          data[cur_ix_masked + best_len] != data[prev_ix + best_len]) {
        continue;
      }
      var len:Int =
          FindMatchLengthWithLimit(data,prev_ix, data,cur_ix_masked,
                                   max_length);
      if (len >= 3 || (len == 2 && i < 2)) {
        // Comparing for >= 2 does not change the semantics, but just saves for
        // a few unnecessary binary logarithms in backward reference score,
        // since we are not interested in such short matches.
        var score:Float = BackwardReferenceScoreUsingLastDistance(len, i);
        if (best_score < score) {
          best_score = score;
          best_len = len;
          best_len_out[0] = best_len;
          best_len_code_out[0] = best_len;
          best_distance_out[0] = backward;
          best_score_out[0] = best_score;
          match_found = true;
        }
      }
    }
    var key:UInt = Hash_(kBucketBits,data,cur_ix_masked);
    var bucket:Vector<Int> = buckets_[key];
    var down:Int = (num_[key] > kBlockSize) ? (num_[key] - kBlockSize) : 0;
	var i:Int = num_[key] - 1;
    while (i >= down) {
      var prev_ix:Int = bucket[i & kBlockMask];
      if (prev_ix!=-1&&prev_ix >= 0) {
        var backward:Int = cur_ix - prev_ix;
        if (PREDICT_FALSE(backward > max_backward)) {
          break;
        }
        prev_ix &= ring_buffer_mask;
        if (cur_ix_masked + best_len > ring_buffer_mask ||
            prev_ix + best_len > ring_buffer_mask ||
            data[cur_ix_masked + best_len] != data[prev_ix + best_len]) {
          --i;
          continue;
        }
        var len:Int =
            FindMatchLengthWithLimit(data,prev_ix, data,cur_ix_masked,
                                     max_length);
        if (len >= 4) {
          // Comparing for >= 3 does not change the semantics, but just saves
          // for a few unnecessary binary logarithms in backward reference
          // score, since we are not interested in such short matches.
          var score:Float = BackwardReferenceScore(len, backward);
          if (best_score < score) {
            best_score = score;
            best_len = len;
            best_len_out[0] = best_len;
            best_len_code_out[0] = best_len;
            best_distance_out[0] = backward;
            best_score_out[0] = best_score;
            match_found = true;
          }
        }
      }
      --i;
    }
    if (!match_found && num_dict_matches_ >= (num_dict_lookups_ >> 7)) {
      var key:UInt = Hash_(14,data,cur_ix_masked) << 1;
      for (k in 0...2) {
        ++num_dict_lookups_;
        var v:UInt = kStaticDictionaryHash[key];
        if (v > 0) {
          var len:Int = v & 31;
          var dist:Int = v >> 5;
          var offset:Int = kBrotliDictionaryOffsetsByLength[len] + len * dist;
          if (len <= max_length) {
            var matchlen:Int =
                FindMatchLengthWithLimit(data,cur_ix_masked,
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
                match_found = true;
                break;
              }
            }
          }
        }
		++key;
      }
    }
    return match_found;
  }

  // Similar to FindLongestMatch(), but finds all matches.
  //
  // Sets *num_matches to the number of matches found, and stores the found
  // matches in matches[0] to matches[*num_matches - 1].
  //
  // If the longest match is longer than kMaxZopfliLen, returns only this
  // longest match.
  //
  // Requires that at least kMaxZopfliLen space is available in matches.
  public function FindAllMatches(data:Vector<UInt>,
                      ring_buffer_mask:Int,
                      cur_ix:UInt,
                      max_length:UInt,
                      max_backward:UInt,
                      num_matches:Vector<Int>,
					  num_matches_off:Int,
                      matches:Array<BackwardMatch>,
                      matches_off:Int) {
    var orig_matches:Array<BackwardMatch> = matches;
    var orig_matches_off:Int = matches_off+0;
    var cur_ix_masked:Int = cur_ix & ring_buffer_mask;
    var best_len:Int = 1;
    var stop:Int = (cur_ix) - 64;
    if (stop < 0) { stop = 0; }
	var i:Int = cur_ix - 1;
    while ( i > stop && best_len <= 2 ) {
      var prev_ix:Int = i;
      var backward:Int = cur_ix - prev_ix;
      if (PREDICT_FALSE(backward > max_backward)) {
        break;
      }
      prev_ix &= ring_buffer_mask;
      if (data[cur_ix_masked] != data[prev_ix] ||
          data[cur_ix_masked + 1] != data[prev_ix + 1]) {
		--i;
        continue;
      }
      var len:Int =
          FindMatchLengthWithLimit(data,prev_ix, data,cur_ix_masked,
                                   max_length);
      if (len > best_len) {
        best_len = len;
        if (len > kMaxZopfliLen) {
          matches = orig_matches;
        }
		var match = new BackwardMatch();
		match.BackwardMatch2(backward, len);
        matches[matches_off++] = match;
		//fprintf(stderr, "type:stop max_backward:%d dist:%d len:%d code:0\n", max_backward, backward, len);
      }
	  --i;
    }
    var key:UInt = Hash_(kBucketBits,data,cur_ix_masked);
    var bucket:Vector<Int> = buckets_[key];
    var down:Int = (num_[key] > kBlockSize) ? (num_[key] - kBlockSize) : 0;
	var i:Int = num_[key] - 1;
    while (i >= down) {
      var prev_ix:Int = bucket[i & kBlockMask];
      if (prev_ix >= 0) {
        var backward = cur_ix - prev_ix;
        if (PREDICT_FALSE(backward > max_backward)) {
          break;
        }
        prev_ix &= ring_buffer_mask;
        if (cur_ix_masked + best_len > ring_buffer_mask ||
            prev_ix + best_len > ring_buffer_mask ||
            data[cur_ix_masked + best_len] != data[prev_ix + best_len]) {
			--i;
          continue;
        }
        var len:Int =
            FindMatchLengthWithLimit(data,prev_ix, data,cur_ix_masked,
                                     max_length);
        if (len > best_len) {
          best_len = len;
          if (len > kMaxZopfliLen) {
            matches_off = orig_matches_off;
          }
		var match = new BackwardMatch();
		match.BackwardMatch2(backward, len);
          matches[matches_off++] = match;
		  //fprintf(stderr, "type:Hash max_backward:%d dist:%d len:%d code:0\n", max_backward, backward, len);
        }
      }
	  --i;
    }
    var dict_matches=FunctionMalloc.mallocInt(kMaxDictionaryMatchLen + 1);
	memset(dict_matches, 0, kInvalidMatch, dict_matches.length);
    var minlen:Int = Std.int(Math.max(4, best_len + 1));
    if (FindAllStaticDictionaryMatches(data,cur_ix_masked, minlen,
                                       dict_matches,0)) {
      var maxlen:Int = Std.int(Math.min(kMaxDictionaryMatchLen, max_length));
      for (l in minlen...maxlen) {
        var dict_id:Int = dict_matches[l];
        if (dict_id < kInvalidMatch) {
		var match = new BackwardMatch();
		match.BackwardMatch3(max_backward + (dict_id >> 5) + 1, l,
                                     dict_id & 31);
          matches[matches_off++] = match;
		  //fprintf(stderr, "type:dict max_backward:%d dist:%d len:%d code:%d\n", max_backward, max_backward + (dict_id >> 5) + 1 , l , dict_id & 31);
        }
      }
    }
    num_matches[num_matches_off] += matches_off - orig_matches_off;
	//if (matches - orig_matches>0)
	//	for (int i = 0; i < *num_matches;i++)
			
  }
	public function new(kBucketBits:Int,
          kBlockBits:Int,
          kNumLastDistancesToCheck:Int) 
	{
		this.kBucketBits = kBucketBits;
		this.kBlockBits = kBlockBits;
		this.kNumLastDistancesToCheck = kNumLastDistancesToCheck;
		
  kBucketSize = 1 << kBucketBits;
  kBlockSize = 1 << kBlockBits;
  kBlockMask = (1 << kBlockBits) - 1;
  num_=new Vector<UInt>(kBucketSize);
  buckets_ = new Vector<Vector<Int>>(kBucketSize);// [kBucketSize][kBlockSize];
  for (i in 0...kBucketSize)
  buckets_[i]= new Vector<Int>(kBlockSize);
		
    Reset();
	}
	var kBucketBits:Int;
	var kBlockBits:Int;
	var kNumLastDistancesToCheck:Int;
	
  // Number of hash buckets.
  var kBucketSize:UInt;

  // Only kBlockSize newest backward references are kept,
  // and the older are forgotten.
  var kBlockSize:UInt;

  // Mask for accessing entries in a block (in a ringbuffer manner).
  var kBlockMask:UInt;

  // Number of entries in a particular bucket.
  var num_:Vector<UInt>;

  // Buckets containing kBlockSize of backward references.
  var buckets_:Vector<Vector<Int>>;// [kBucketSize][kBlockSize];

  var num_dict_lookups_:Int;
  var num_dict_matches_:Int;	
}
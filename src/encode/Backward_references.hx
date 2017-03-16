package encode;
import encode.hash.*;
import haxe.ds.Vector;
import encode.Hash.*;
import encode.backward_references.*;
import DefaultFunctions.*;
import encode.Prefix.*;
import encode.Port.*;
import encode.Find_match_length.*;
import encode.command.Command;

/**
 * ...
 * @author 
 */
class Backward_references
{
	public static var kInfinity = Math.POSITIVE_INFINITY;
public static function SetDistanceCache(distance:Int,// inline
                             distance_code:Int,
                             max_distance:Int,
                             dist_cache:Vector<Int>,
                             result_dist_cache:Vector<Int>,
                             result_dist_cache_off:Int) {
  if (distance <= max_distance && distance_code > 0) {
    result_dist_cache[0] = distance;
    memcpy(result_dist_cache,result_dist_cache_off+1, dist_cache,0, 3);// * sizeof(dist_cache[0])
  } else {
    memcpy(result_dist_cache,result_dist_cache_off, dist_cache,0, 4);// * sizeof(dist_cache[0])
  }
}

public static function ComputeDistanceCode(distance:Int,
                               max_distance:Int,
                               quality:Int,
                               dist_cache:Vector<Int>):Int {
  if (distance <= max_distance) {
    if (distance == dist_cache[0]) {
      return 0;
    } else if (distance == dist_cache[1]) {
      return 1;
    } else if (distance == dist_cache[2]) {
      return 2;
    } else if (distance == dist_cache[3]) {
      return 3;
    } else if (quality > 3 && distance >= 6) {
      for (k in 4...kNumDistanceShortCodes) {
        var idx:Int = kDistanceCacheIndex[k];
        var candidate:Int = dist_cache[idx] + kDistanceCacheOffset[k];
        var kLimits = [ 0, 0, 0, 0,
                                         6, 6, 11, 11,
                                         11, 11, 11, 11,
                                         12, 12, 12, 12 ];
        if (distance == candidate && distance >= kLimits[k]) {
          return k;
        }
      }
    }
  }
  return distance + 15;
}

public static function UpdateZopfliNode(nodes:Vector<ZopfliNode>,nodes_off:Int, pos:Int, start_pos:Int,// inline
                             len:Int, len_code:Int, dist:Int, dist_code:Int,
                             max_dist:Int, dist_cache:Vector<Int>,
                             cost:Float) {
  var next:ZopfliNode = nodes[nodes_off+pos + len];
  next.length = len;
  next.length_code = len_code;
  next.distance = dist;
  next.distance_code = dist_code;
  next.insert_length = pos - start_pos;
  next.cost = cost;
  SetDistanceCache(dist, dist_code, max_dist, dist_cache,
                   next.distance_cache,0);
}

// Returns the minimum possible copy length that can improve the cost of any
// future position.
public static function ComputeMinimumCopyLength(queue:StartPosQueue,
                             nodes:Vector<ZopfliNode>,
                             model:ZopfliCostModel,
                             pos:Int,
                             min_cost_cmd:Float):Int {
  // Compute the minimum possible cost of reaching any future position.
  var start0:Int = queue.GetStartPos(0);
  var min_cost:Float = (nodes[start0].cost +
                     model.GetLiteralCosts(start0, pos) +
                     min_cost_cmd);
  var len:Int = 2;
  var next_len_bucket:Int = 4;
  var next_len_offset:Int = 10;
  while (pos + len < nodes.length && nodes[pos + len].cost <= min_cost) {
    // We already reached (pos + len) with no more cost than the minimum
    // possible cost of reaching anything from this pos, so there is no point in
    // looking for lengths <= len.
    ++len;
    if (len == next_len_offset) {
      // We reached the next copy length code bucket, so we add one more
      // extra bit to the minimum cost.
      min_cost += 1.0;
      next_len_offset += next_len_bucket;
      next_len_bucket *= 2;
    }
  }
  return len;
}

public static function ZopfliIterate(num_bytes:Int,
                   position:Int,
                   ringbuffer:Vector<UInt>,
                   ringbuffer_mask:Int,
                   max_backward_limit:Int,
                   model:ZopfliCostModel,//&
                   num_matches:Vector<Int>,
                   matches:Array<BackwardMatch>,
                   dist_cache:Vector<Int>,
                   last_insert_len:Array<Int>,
                   commands:Array<Command>,
				   commands_off:Int,
                   num_commands:Array<Int>,
                   num_literals:Array<Int>) {
  var orig_commands:Array<Command> = commands;
  var orig_commands_off:Int = commands_off;

  var nodes=FunctionMalloc.malloc(ZopfliNode,num_bytes + 1);
  nodes[0].length = 0;
  nodes[0].cost = 0;
  memcpy(nodes[0].distance_cache,0 , dist_cache, 0, 4);// * sizeof(dist_cache[0])W

  var queue=new StartPosQueue(3);
  var min_cost_cmd:Float = model.GetMinCostCmd();

  var cur_match_pos:Int = 0;
  var i:Int = 0;
  while (i + 3 < num_bytes) {
    var cur_ix:Int = position + i;
    var cur_ix_masked:Int = cur_ix & ringbuffer_mask;
    var max_distance:Int = Std.int(Math.min(cur_ix, max_backward_limit));
    var max_length:Int = num_bytes - i;

    queue.Push(i, nodes[i].cost - model.GetLiteralCosts(0, i));

    var min_len:Int = ComputeMinimumCopyLength(queue, nodes, model,
                                                 i, min_cost_cmd);

    // Go over the command starting positions in order of increasing cost
    // difference.
	var k:Int = 0;
    while (k < 5 && k < queue.size()) {
      var start:Int = queue.GetStartPos(k);
      var start_costdiff:Float =
          nodes[start].cost - model.GetLiteralCosts(0, start);
      var dist_cache2:Vector<Int> = nodes[start].distance_cache;
      var dist_cache2_off:Int = 0;

      // Look for last distance matches using the distance cache from this
      // starting position.
      var best_len:Int = min_len - 1;
      for (j in 0...kNumDistanceShortCodes) {
        var idx:Int = kDistanceCacheIndex[j];
        var backward:Int = dist_cache2[idx] + kDistanceCacheOffset[j];
        var prev_ix:Int = cur_ix - backward;
        if (prev_ix >= cur_ix) {
          continue;
        }
        if (PREDICT_FALSE(backward > max_distance)) {
          continue;
        }
        prev_ix &= ringbuffer_mask;

        if (cur_ix_masked + best_len > ringbuffer_mask ||
            prev_ix + best_len > ringbuffer_mask ||
            ringbuffer[cur_ix_masked + best_len] !=
            ringbuffer[prev_ix + best_len]) {
          continue;
        }
        var len:Int =
            FindMatchLengthWithLimit(ringbuffer,prev_ix,
                                     ringbuffer,cur_ix_masked,
                                     max_length);
        for (l in best_len + 1...len+1) {
          var cmd_cost:Float = model.GetCommandCost(j, l, i - start);
          var cost:Float = start_costdiff + cmd_cost + model.GetLiteralCosts(0, i);
          if (cost < nodes[i + l].cost) {
            UpdateZopfliNode(nodes,0, i, start, l, l, backward, j,
                             max_distance, dist_cache2, cost);
          }
          best_len = l;
        }
      }

      // At higher iterations look only for new last distance matches, since
      // looking only for new command start positions with the same distances
      // does not help much.
      if (k >= 2) {++k;continue;}

      // Loop through all possible copy lengths at this position.
      var len:Int = min_len;
      for (j in 0...num_matches[i]) {
        var match:BackwardMatch = matches[cur_match_pos + j];
        var dist:Int = match.distance;
        var is_dictionary_match:Bool = dist > max_distance;
        // We already tried all possible last distance matches, so we can use
        // normal distance code here.
        var dist_code:Int = dist + 15;
        // Try all copy lengths up until the maximum copy length corresponding
        // to this distance. If the distance refers to the static dictionary, or
        // the maximum length is long enough, try only one maximum length.
        var max_len:Int = match.length();
        if (len < max_len && (is_dictionary_match || max_len > kMaxZopfliLen)) {
          len = max_len;
        }
        while (len <= max_len) {
          var len_code:Int = is_dictionary_match ? match.length_code() : len;
          var cmd_cost:Float =
              model.GetCommandCost(dist_code, len_code, i - start);
          var cost:Float = start_costdiff + cmd_cost + model.GetLiteralCosts(0, i);
          if (cost < nodes[i + len].cost) {
            UpdateZopfliNode(nodes,0, i, start, len, len_code, dist,
                             dist_code, max_distance, dist_cache2, cost);
          }
		  ++len;
        }
      }
	  ++k;
    }

    cur_match_pos += num_matches[i];

    // The zopflification can be too slow in case of very long lengths, so in
    // such case skip it all, it does not cost a lot of compression ratio.
    if (num_matches[i] == 1 &&
        matches[cur_match_pos - 1].length() > kMaxZopfliLen) {
      i += matches[cur_match_pos - 1].length() - 1;
      queue.Clear();
    }
	i++;
  }

  var backwards:Array<Int>=new Array();
  var index:Int = num_bytes;
  while (nodes[index].cost == kInfinity) --index;
  while (index > 0) {
    var len:Int = nodes[index].length + nodes[index].insert_length;
    backwards.push(len);
    index -= len;
  }

  var path:Array<Int>=new Array();
  var i:Int = backwards.length;
  while (i > 0) {
    path.push(backwards[i - 1]);
	i--;
  }

  var pos:Int = 0;
  for (i in 0...path.length) {
    var next:ZopfliNode = nodes[pos + path[i]];
    var copy_length:Int = next.length;
    var insert_length:Int = next.insert_length;
    pos += insert_length;
    if (i == 0) {
      insert_length += last_insert_len[0];
    }
    var distance:Int = next.distance;
    var len_code:Int = next.length_code;
    var max_distance:Int = Std.int(Math.min(position + pos, max_backward_limit));
    var is_dictionary:Bool = (distance > max_distance);
    var dist_code:Int = next.distance_code;
	
	var command = new Command();
	command.Command4(insert_length, copy_length, len_code, dist_code);
    var cmd=command;
    commands[commands_off++] = cmd;

    if (!is_dictionary && dist_code > 0) {
      dist_cache[3] = dist_cache[2];
      dist_cache[2] = dist_cache[1];
      dist_cache[1] = dist_cache[0];
      dist_cache[0] = distance;
    }

    num_literals[0] += insert_length;
    insert_length = 0;
    pos += copy_length;
  }
  last_insert_len[0] = num_bytes - pos;
  num_commands[0] += (commands_off - orig_commands_off);
}

public static function CreateBackwardReferences_HashLongestMatch(num_bytes:Int,
                              position:Int,
                              ringbuffer:Vector<UInt>,
                              ringbuffer_mask:Int,
                              max_backward_limit:Int,
                              quality:Int,
                              hasher:HashLongestMatch,
                              dist_cache:Vector<Int>,
                              last_insert_len:Array<Int>,
                              commands:Array<Command>,
                              commands_off:Int,
                              num_commands:Array<Int>,
                              num_literals:Array<Int>) {
  if (num_bytes >= 3 && position >= 3) {
    // Prepare the hashes for three last bytes of the last write.
    // These could not be calculated before, since they require knowledge
    // of both the previous and the current block.
    hasher.Store(ringbuffer,(position - 3) & ringbuffer_mask,
                  position - 3);
    hasher.Store(ringbuffer,(position - 2) & ringbuffer_mask,
                  position - 2);
    hasher.Store(ringbuffer,(position - 1) & ringbuffer_mask,
                  position - 1);
  }
  var orig_commands:Array<Command> = commands;
  var orig_commands_off:Int = commands_off+0;
  var insert_length:Int = last_insert_len[0];
  var i:Int = position & ringbuffer_mask;
  var i_diff:Int = position - i;
  var i_end:Int = i + num_bytes;

  // For speed up heuristics for random data.
  var random_heuristics_window_size:Int = quality < 9 ? 64 : 512;
  var apply_random_heuristics:Int = i + random_heuristics_window_size;

  // Minimum score to accept a backward reference.
  var kMinScore:Float = 4.0;

  while (i + 3 < i_end) {
    var max_length:Int = i_end - i;
    var max_distance:Int = Std.int(Math.min(i + i_diff, max_backward_limit));
    var best_len:Array<Int> = [0];
    var best_len_code:Array<Int> = [0];
    var best_dist:Array<Int> = [0];
    var best_score:Array<Float> = [kMinScore];
    var match_found:Bool = hasher.FindLongestMatch(
        ringbuffer, ringbuffer_mask,
        dist_cache, i + i_diff, max_length, max_distance,
        best_len, best_len_code, best_dist, best_score);
    if (match_found) {
      // Found a match. Let's look for something even better ahead.
      var delayed_backward_references_in_row:Int = 0;
      while (true) {
        --max_length;
        var best_len_2:Array<Int> = [quality < 5 ? Std.int(Math.min(best_len[0] - 1, max_length)) : 0];
        var best_len_code_2:Array<Int> = [0];
        var best_dist_2:Array<Int> = [0];
        var best_score_2:Array<Float> = [kMinScore];
        max_distance = Std.int(Math.min(i + i_diff + 1, max_backward_limit));
        hasher.Store(ringbuffer,0 + i, i + i_diff);
        match_found = hasher.FindLongestMatch(
            ringbuffer, ringbuffer_mask,
            dist_cache, i + i_diff + 1, max_length, max_distance,
            best_len_2, best_len_code_2, best_dist_2, best_score_2);
        var cost_diff_lazy:Float = 7.0;
        if (match_found && best_score_2[0] >= best_score[0] + cost_diff_lazy) {
          // Ok, let's just write one byte for now and start a match from the
            // next byte.
          ++i;
          ++insert_length;
          best_len[0] = best_len_2[0];
          best_len_code[0] = best_len_code_2[0];
          best_dist[0] = best_dist_2[0];
          best_score[0] = best_score_2[0];
          if (++delayed_backward_references_in_row < 4) {
            continue;
          }
        }
        break;
      }
      apply_random_heuristics =
          i + 2 * best_len[0] + random_heuristics_window_size;
      max_distance = Std.int(Math.min(i + i_diff, max_backward_limit));
      // The first 16 codes are special shortcodes, and the minimum offset is 1.
      var distance_code:Int =
          ComputeDistanceCode(best_dist[0], max_distance, quality, dist_cache);
      if (best_dist[0] <= max_distance && distance_code > 0) {
        dist_cache[3] = dist_cache[2];
        dist_cache[2] = dist_cache[1];
        dist_cache[1] = dist_cache[0];
        dist_cache[0] = best_dist[0];
      }
	  var command = new Command();
	  command.Command4(insert_length, best_len[0], best_len_code[0], distance_code);
      var cmd=command;
      commands[commands_off++] = cmd;
      num_literals[0] += insert_length;
      insert_length = 0;
      // Put the hash keys into the table, if there are enough
      // bytes left.
      for (j in 1...best_len[0]) {
        hasher.Store(ringbuffer,i + j, i + i_diff + j);
      }
      i += best_len[0];
    } else {
      ++insert_length;
      hasher.Store(ringbuffer,0 + i, i + i_diff);
      ++i;
      // If we have not seen matches for a long time, we can skip some
      // match lookups. Unsuccessful match lookups are very very expensive
      // and this kind of a heuristic speeds up compression quite
      // a lot.
      if (i > apply_random_heuristics) {
        // Going through uncompressible data, jump.
        if (i > apply_random_heuristics + 4 * random_heuristics_window_size) {
          // It is quite a long time since we saw a copy, so we assume
          // that this data is not compressible, and store hashes less
          // often. Hashes of non compressible data are less likely to
          // turn out to be useful in the future, too, so we store less of
          // them to not to flood out the hash table of good compressible
          // data.
          var i_jump:Int = Std.int(Math.min(i + 16, i_end - 4));
          while (i < i_jump) {
            hasher.Store(ringbuffer,0 + i, i + i_diff);
            insert_length += 4;
			i += 4;
          }
        } else {
          var i_jump:Int = Std.int(Math.min(i + 8, i_end - 3));
          while (i < i_jump) {
            hasher.Store(ringbuffer,0 + i, i + i_diff);
            insert_length += 2;
			i += 2;
          }
        }
      }
    }
  }
  insert_length += (i_end - i);
  last_insert_len[0] = insert_length;
  num_commands[0] += (commands_off - orig_commands_off);
}

public static function CreateBackwardReferences_HashLongestMatchQuickly(num_bytes:Int,
                              position:Int,
                              ringbuffer:Vector<UInt>,
                              ringbuffer_mask:Int,
                              max_backward_limit:Int,
                              quality:Int,
                              hasher:HashLongestMatchQuickly,
                              dist_cache:Vector<Int>,
                              last_insert_len:Array<Int>,
                              commands:Array<Command>,
                              commands_off:Int,
                              num_commands:Array<Int>,
                              num_literals:Array<Int>) {
  if (num_bytes >= 3 && position >= 3) {
    // Prepare the hashes for three last bytes of the last write.
    // These could not be calculated before, since they require knowledge
    // of both the previous and the current block.
    hasher.Store(ringbuffer,(position - 3) & ringbuffer_mask,
                  position - 3);
    hasher.Store(ringbuffer,(position - 2) & ringbuffer_mask,
                  position - 2);
    hasher.Store(ringbuffer,(position - 1) & ringbuffer_mask,
                  position - 1);
  }
  var orig_commands:Array<Command> = commands;
  var orig_commands_off:Int = commands_off+0;
  var insert_length:Int = last_insert_len[0];
  var i:Int = position & ringbuffer_mask;
  var i_diff:Int = position - i;
  var i_end:Int = i + num_bytes;

  // For speed up heuristics for random data.
  var random_heuristics_window_size:Int = quality < 9 ? 64 : 512;
  var apply_random_heuristics:Int = i + random_heuristics_window_size;

  // Minimum score to accept a backward reference.
  var kMinScore:Float = 4.0;

  while (i + 3 < i_end) {
    var max_length:Int = i_end - i;
    var max_distance:Int = Std.int(Math.min(i + i_diff, max_backward_limit));
    var best_len:Array<Int> = [0];
    var best_len_code:Array<Int> = [0];
    var best_dist:Array<Int> = [0];
    var best_score:Array<Float> = [kMinScore];
    var match_found:Bool = hasher.FindLongestMatch(
        ringbuffer, ringbuffer_mask,
        dist_cache, i + i_diff, max_length, max_distance,
        best_len, best_len_code, best_dist, best_score);
    if (match_found) {
      // Found a match. Let's look for something even better ahead.
      var delayed_backward_references_in_row:Int = 0;
      while (true) {
        --max_length;
        var best_len_2:Array<Int> = [quality < 5 ? Std.int(Math.min(best_len[0] - 1, max_length)) : 0];
        var best_len_code_2:Array<Int> = [0];
        var best_dist_2:Array<Int> = [0];
        var best_score_2:Array<Float> = [kMinScore];
        max_distance = Std.int(Math.min(i + i_diff + 1, max_backward_limit));
        hasher.Store(ringbuffer,0 + i, i + i_diff);
        match_found = hasher.FindLongestMatch(
            ringbuffer, ringbuffer_mask,
            dist_cache, i + i_diff + 1, max_length, max_distance,
            best_len_2, best_len_code_2, best_dist_2, best_score_2);
        var cost_diff_lazy:Float = 7.0;
        if (match_found && best_score_2[0] >= best_score[0] + cost_diff_lazy) {
          // Ok, let's just write one byte for now and start a match from the
            // next byte.
          ++i;
          ++insert_length;
          best_len[0] = best_len_2[0];
          best_len_code[0] = best_len_code_2[0];
          best_dist[0] = best_dist_2[0];
          best_score[0] = best_score_2[0];
          if (++delayed_backward_references_in_row < 4) {
            continue;
          }
        }
        break;
      }
      apply_random_heuristics =
          i + 2 * best_len[0] + random_heuristics_window_size;
      max_distance = Std.int(Math.min(i + i_diff, max_backward_limit));
      // The first 16 codes are special shortcodes, and the minimum offset is 1.
      var distance_code:Int =
          ComputeDistanceCode(best_dist[0], max_distance, quality, dist_cache);
      if (best_dist[0] <= max_distance && distance_code > 0) {
        dist_cache[3] = dist_cache[2];
        dist_cache[2] = dist_cache[1];
        dist_cache[1] = dist_cache[0];
        dist_cache[0] = best_dist[0];
      }
	  var command = new Command();
	  command.Command4(insert_length, best_len[0], best_len_code[0], distance_code);
      var cmd=command;
      commands[commands_off++] = cmd;
      num_literals[0] += insert_length;
      insert_length = 0;
      // Put the hash keys into the table, if there are enough
      // bytes left.
      for (j in 1...best_len[0]) {
        hasher.Store(ringbuffer,i + j, i + i_diff + j);
      }
      i += best_len[0];
    } else {
      ++insert_length;
      hasher.Store(ringbuffer,0 + i, i + i_diff);
      ++i;
      // If we have not seen matches for a long time, we can skip some
      // match lookups. Unsuccessful match lookups are very very expensive
      // and this kind of a heuristic speeds up compression quite
      // a lot.
      if (i > apply_random_heuristics) {
        // Going through uncompressible data, jump.
        if (i > apply_random_heuristics + 4 * random_heuristics_window_size) {
          // It is quite a long time since we saw a copy, so we assume
          // that this data is not compressible, and store hashes less
          // often. Hashes of non compressible data are less likely to
          // turn out to be useful in the future, too, so we store less of
          // them to not to flood out the hash table of good compressible
          // data.
          var i_jump:Int = Std.int(Math.min(i + 16, i_end - 4));
          while (i < i_jump) {
            hasher.Store(ringbuffer,0 + i, i + i_diff);
            insert_length += 4;
			i += 4;
          }
        } else {
          var i_jump:Int = Std.int(Math.min(i + 8, i_end - 3));
          while (i < i_jump) {
            hasher.Store(ringbuffer,0 + i, i + i_diff);
            insert_length += 2;
			i += 2;
          }
        }
      }
    }
  }
  insert_length += (i_end - i);
  last_insert_len[0] = insert_length;
  num_commands[0] += (commands_off - orig_commands_off);
}

public static function CreateBackwardReferences(num_bytes:Int,
                              position:Int,
                              ringbuffer:Vector<UInt>,
                              ringbuffer_mask:Int,
                              literal_cost:Vector<Float>,
                              literal_cost_mask:Int,
                              max_backward_limit:Int,
                              quality:Int,
                              hashers:Hashers,//*
                              hash_type:Int,
                              dist_cache:Vector<Int>,
                              last_insert_len:Array<Int>,
                              commands:Array<Command>,//*
                              commands_off:Int,
                              num_commands:Array<Int>,
                              num_literals:Array<Int>) {
  var zopflify:Bool = quality > 9;
  if (zopflify) {
    var hasher = hashers.hash_h9;// .get();//Hashers::H9*
    if (num_bytes >= 3 && position >= 3) {
      // Prepare the hashes for three last bytes of the last write.
      // These could not be calculated before, since they require knowledge
      // of both the previous and the current block.
      hasher.Store(ringbuffer,(position - 3) & ringbuffer_mask,
                    position - 3);
      hasher.Store(ringbuffer,(position - 2) & ringbuffer_mask,
                    position - 2);
      hasher.Store(ringbuffer,(position - 1) & ringbuffer_mask,
                    position - 1);
    }
    var num_matches=FunctionMalloc.mallocInt(num_bytes);
    var matches=FunctionMalloc.mallocArray(BackwardMatch,3 * num_bytes);
    var cur_match_pos:Int = 0;
	var i:Int = 0;
    while (i + 3 < num_bytes) {
      var max_distance:Int = Std.int(Math.min(position + i, max_backward_limit));
      var max_length:Int = num_bytes - i;
      // Ensure that we have at least kMaxZopfliLen free slots.
      if (matches.length < cur_match_pos + kMaxZopfliLen) {
        matches.concat(FunctionMalloc.mallocArray(BackwardMatch,cur_match_pos + kMaxZopfliLen-matches.length));
      }
      hasher.FindAllMatches(
          ringbuffer, ringbuffer_mask,
          position + i, max_length, max_distance,
          num_matches,i, matches,cur_match_pos);
      hasher.Store(ringbuffer,(position + i) & ringbuffer_mask,
                    position + i);
      cur_match_pos += num_matches[i];
      if (num_matches[i] == 1) {
        var match_len:Int = matches[cur_match_pos - 1].length();
        if (match_len > kMaxZopfliLen) {
          for (j in 1...match_len) {
            ++i;
            hasher.Store(
                ringbuffer,(position + i) & ringbuffer_mask, position + i);
            num_matches[i] = 0;
          }
        }
      }
	  ++i;
    }
    var orig_num_literals:Int = num_literals[0];
    var orig_last_insert_len:Int = last_insert_len[0];
    var orig_dist_cache=new Vector<Int>(4);
      orig_dist_cache[0] = dist_cache[0]; orig_dist_cache[1] = dist_cache[1]; orig_dist_cache[2] = dist_cache[2]; orig_dist_cache[3] = dist_cache[3];
    var orig_num_commands:Int = num_commands[0];
    var kIterations:Int = 2;
    for (i in 0...kIterations) {
      var model=new ZopfliCostModel();
      if (i == 0) {
        model.SetFromLiteralCosts(num_bytes, position,
                                  literal_cost, literal_cost_mask);
      } else {
        model.SetFromCommands(num_bytes, position,
                              ringbuffer, ringbuffer_mask,
                              commands, commands_off+num_commands[0] - orig_num_commands,
                              orig_last_insert_len);
      }
      num_commands[0] = orig_num_commands;
      num_literals[0] = orig_num_literals;
      last_insert_len[0] = orig_last_insert_len;
      memcpy(dist_cache,0, orig_dist_cache,0, 4);// * sizeof(dist_cache[0])
      ZopfliIterate(num_bytes, position, ringbuffer, ringbuffer_mask,
                    max_backward_limit, model, num_matches, matches, dist_cache,
                    last_insert_len, commands,commands_off+0, num_commands, num_literals);
    }
    return;
  }

  switch (hash_type) {
    case 1:
      CreateBackwardReferences_HashLongestMatchQuickly(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h1, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 2:
      CreateBackwardReferences_HashLongestMatchQuickly(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h2, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 3:
      CreateBackwardReferences_HashLongestMatchQuickly(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h3, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 4:
      CreateBackwardReferences_HashLongestMatchQuickly(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h4, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 5:
      CreateBackwardReferences_HashLongestMatch(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h5, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 6:
      CreateBackwardReferences_HashLongestMatch(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h6, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 7:
      CreateBackwardReferences_HashLongestMatch(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h7, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 8:
      CreateBackwardReferences_HashLongestMatch(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h8, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    case 9:
      CreateBackwardReferences_HashLongestMatch(
          num_bytes, position, ringbuffer, ringbuffer_mask, max_backward_limit,
          quality,hashers.hash_h9, dist_cache, last_insert_len,
          commands,commands_off, num_commands, num_literals);
    default:
  }
}

	public function new() 
	{
		
	}
	
}
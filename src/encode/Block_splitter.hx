package encode;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import encode.metablock.BlockSplit;
import DefaultFunctions.*;
import encode.histogram.Histogram;
import encode.Fast_log.*;
import encode.Cluster.*;
import encode.Histogram_functions.*;
import encode.command.Command;

/**
 * ...
 * @author 
 */
class Block_splitter
{

public static inline var kMaxLiteralHistograms:Int = 100;
public static inline var kMaxCommandHistograms:Int = 50;
public static inline var kLiteralBlockSwitchCost:Float = 28.1;
public static inline var kCommandBlockSwitchCost:Float = 13.5;
public static inline var kDistanceBlockSwitchCost:Float = 14.6;
public static inline var kLiteralStrideLength:Int = 70;
public static inline var kCommandStrideLength:Int = 40;
public static inline var kSymbolsPerLiteralHistogram:Int = 544;
public static inline var kSymbolsPerCommandHistogram:Int = 530;
public static inline var kSymbolsPerDistanceHistogram:Int = 544;
public static inline var kMinLengthForBlockSplitting:Int = 128;
public static inline var kIterMulForRefining:Int = 2;
public static inline var kMinItersForRefining:Int = 100;

public static function CopyLiteralsToByteArray(cmds:Array<Command>,
                             num_commands:Int,
                             data:Vector<UInt>,
                             data_off:Int,
                             literals:Array<UInt>) {
  // Count how many we have.
  var total_length:Int = 0;
  for (i in 0...num_commands) {
    total_length += cmds[i].insert_len_;
  }
  if (total_length == 0) {
    return;
  }

  // Allocate.
  //TODO:literals.resize(total_length);
  while (literals.length > total_length) literals.pop();

  // Loop again, and copy this time.
  var pos:Int = 0;
  var from_pos:Int = 0;
  var i = 0;
  while (i < num_commands && pos < total_length) {
    memcpyArrayVector(literals,pos, data,data_off + from_pos, cmds[i].insert_len_);
    pos += cmds[i].insert_len_;
    from_pos += cmds[i].insert_len_ + cmds[i].copy_len_;
	++i;
  }
}

public static function CopyCommandsToByteArray(cmds:Array<Command>,
                             num_commands:Int,
                             insert_and_copy_codes:Array<UInt>,
                             distance_prefixes:Array<UInt>) {
  for (i in 0...num_commands) {
    var cmd:Command = cmds[i];
    insert_and_copy_codes.push(cmd.cmd_prefix_[0]);
    if (cmd.copy_len_ > 0 && cmd.cmd_prefix_[0] >= 128) {
      distance_prefixes.push(cmd.dist_prefix_[0]);
    }
  }
}

public static inline function MyRand(seed:Array<UInt>):UInt {
  seed[0] *= 16807;
#if !php
  seed[0] >>>= 0;
#else
  seed[0] &= 0xffffffff;
#end
  if (seed[0] == 0) {
    seed[0] = 1;
  }
  return seed[0];
}

public static function InitialEntropyCodes(HistogramTypeInt:Int,data:Array<UInt>, length:Int,
                         literals_per_histogram:Int,
                         max_histograms:Int,
                         stride:Int,
                         vec:Array<Histogram>) {
  var total_histograms:Int = Std.int(length / literals_per_histogram) + 1;
  if (total_histograms > max_histograms) {
    total_histograms = max_histograms;
  }
  var seed:Array<UInt> = [7];
  var block_length:Int = Std.int(length / total_histograms);
  for (i in 0...total_histograms) {
    var pos:Int = Std.int(length * i / total_histograms);
    if (i != 0) {
      pos += MyRand(seed) % block_length;
    }
    if (pos + stride >= length) {
      pos = length - stride - 1;
    }
    var histo=new Histogram(HistogramTypeInt);
    histo.Add2(data, 0+ pos, stride);
    vec.push(histo);
  }
}

public static function RandomSample(seed:Array<UInt>,
                  data:Array<UInt>,
                  length:Int,
                  stride:Int,
                  sample:Histogram) {
  var pos:Int = 0;
  if (stride >= length) {
    pos = 0;
    stride = length;
  } else {
    pos = MyRand(seed) % (length - stride + 1);
  }
  sample.Add2(data,0 + pos, stride);
}

public static function RefineEntropyCodes(HistogramTypeInt:Int,data:Array<UInt>, length:Int,
                        stride:Int,
                        vec:Array<Histogram>) {
  var iters:Int =
      Std.int(kIterMulForRefining * length / stride) + kMinItersForRefining;
  var seed:Array<UInt> = [7];
  iters = Std.int(((iters + vec.length - 1) / vec.length)) * vec.length;
  for (iter in 0...iters) {
    var sample=new Histogram(HistogramTypeInt);
    RandomSample(seed, data, length, stride, sample);
    var ix:Int = iter % vec.length;
    vec[ix].AddHistogram(sample);
  }
}

public static inline function BitCost(count:Int):Float {
  return count == 0 ? -2 : FastLog2(count);
}

public static function FindBlocks(kSize:Int,data:Array<UInt>, length:Int,
                block_switch_bitcost:Float,
                vec:Array<Histogram>,
                block_id:Vector<UInt>,
                block_id_off:Int) {
  if (vec.length <= 1) {
    for (i in 0...length) {
      block_id[i] = 0;
    }
    return;
  }
  var vecsize:Int = vec.length;
  var insert_cost:Vector<Float> = FunctionMalloc.mallocFloat(kSize * vecsize);
  //for (i in 0...kSize * vecsize)
  //insert_cost[i] = 0;
  //memset(insert_cost,0, 0, );
  for (j in 0...vecsize) {
    insert_cost[j] = FastLog2(vec[j].total_count_);
  }
  var i = kSize - 1;
  while (i >= 0) {
    for (j in 0...vecsize) {
      insert_cost[i * vecsize + j] = insert_cost[j] - BitCost(vec[j].data_[i]);
    }
	--i;
  }
  var cost:Vector<Float> = FunctionMalloc.mallocFloat(vecsize);
  //memset(cost,0, 0, vecsize);
  var switch_signal:Vector<Bool> = FunctionMalloc.mallocBool(length * vecsize);
  //memset(switch_signal,0, false, length * vecsize);
  // After each iteration of this loop, cost[k] will contain the difference
  // between the minimum cost of arriving at the current byte position using
  // entropy code k, and the minimum cost of arriving at the current byte
  // position. This difference is capped at the block switch cost, and if it
  // reaches block switch cost, it means that when we trace back from the last
  // position, we need to switch here.
  for (byte_ix in 0...length) {
    var ix:Int = byte_ix * vecsize;
    var insert_cost_ix:Int = data[byte_ix] * vecsize;
    var min_cost:Float = 1e99;
    for (k in 0...vecsize) {
      // We are coding the symbol in data[byte_ix] with entropy code k.
      cost[k] += insert_cost[insert_cost_ix + k];
      if (cost[k] < min_cost) {
        min_cost = cost[k];
        block_id[byte_ix] = k;
      }
    }
    var block_switch_cost:Float = block_switch_bitcost;
    // More blocks for the beginning.
    if (byte_ix < 2000) {
      block_switch_cost *= 0.77 + 0.07 * byte_ix / 2000;
    }
    for (k in 0...vecsize) {
      cost[k] -= min_cost;
      if (cost[k] >= block_switch_cost) {
        cost[k] = block_switch_cost;
        switch_signal[ix + k] = true;
      }
    }
  }
  // Now trace back from the last position and switch at the marked places.
  var byte_ix:Int = length - 1;
  var ix:Int = byte_ix * vecsize;
  var cur_id:Int = block_id[byte_ix];
  while (byte_ix > 0) {
    --byte_ix;
    ix -= vecsize;
    if (switch_signal[ix + cur_id]) {
      cur_id = block_id[byte_ix];
    }
    block_id[byte_ix] = cur_id;
  }
  /*delete[] insert_cost;
  delete[] cost;
  delete[] switch_signal;*/
}

public static function RemapBlockIds(block_ids:Vector<UInt>, length:Int):Int {//TODO:
  var new_id=new IntMap();
  var next_id:Int = 0;
  for (i in 0...length) {
    if (new_id.exists(block_ids[i]) == false) {//.indexOf()-1new_id.end()
      new_id.set(block_ids[i],next_id);// = 
      ++next_id;
    }
  }
  for (i in 0...length) {
    block_ids[i] = new_id.get(block_ids[i]);
  }
  return next_id;
}

public static function BuildBlockHistograms(HistogramTypeInt:Int,data:Array<UInt>, length:Int,
                          block_ids:Vector<UInt>,
                          block_ids_off:Int,
                          histograms:Array<Histogram>) {
  var num_types:Int = RemapBlockIds(block_ids, length);
  while(histograms.length>0) histograms.pop();
  //TODO:histograms.resize(num_types);
  for (i in 0...num_types)
  histograms.push(new Histogram(HistogramTypeInt));
  for (i in 0...length) {
    histograms[block_ids[i]].Add1(data[i]);
  }
}

public static function ClusterBlocks(HistogramTypeInt:Int,data:Array<UInt>, length:Int,
                   block_ids:Vector<UInt>) {
  var histograms:Array<Histogram> = new Array();// new Histogram(HistogramTypeInt);
  var block_index=FunctionMalloc.mallocInt(length);
  var cur_idx:Int = 0;
  var cur_histogram=new Histogram(HistogramTypeInt);
  for (i in 0...length) {
    var block_boundary:Bool = (i + 1 == length || block_ids[i] != block_ids[i + 1]);
    block_index[i] = cur_idx;
    cur_histogram.Add1(data[i]);
    if (block_boundary) {
      histograms.push(cur_histogram);
      //TODO:cur_histogram.Clear();
	  cur_histogram=new Histogram(HistogramTypeInt);
      ++cur_idx;
    }
  }
  var clustered_histograms:Array<Histogram> = new Array();
  var histogram_symbols:Vector<Int>=new Vector(1*histograms.length);//TODO:
  // Block ids need to fit in one byte.
  var kMaxNumberOfBlockTypes:Int = 256;
  ClusterHistograms(histograms, 1, histograms.length,
                    kMaxNumberOfBlockTypes,
                    clustered_histograms,HistogramTypeInt,
                    histogram_symbols);
  for (i in 0...length) {
    block_ids[i] = histogram_symbols[block_index[i]];
  }
}

public static function BuildBlockSplit(block_ids:Vector<UInt>,split:BlockSplit) {
  var cur_id:Int = block_ids[0];
  var cur_length:Int = 1;
  split.num_types = -1;
  for (i in 1...block_ids.length) {
    if (block_ids[i] != cur_id) {
      split.types.push(cur_id);
      split.lengths.push(cur_length);
      split.num_types = Std.int(Math.max(split.num_types, cur_id));
      cur_id = block_ids[i];
      cur_length = 0;
    }
    ++cur_length;
  }
  split.types.push(cur_id);
  split.lengths.push(cur_length);
  split.num_types = Std.int(Math.max(split.num_types, cur_id));
  ++split.num_types;
}

public static function SplitByteVector(HistogramTypeInt:Int,data:Array<UInt>,
                     literals_per_histogram:Int,
                     max_histograms:Int,
                     sampling_stride_length:Int,
                     block_switch_cost:Float,
                     split:BlockSplit) {
  if (data.length==0) {
    split.num_types = 1;
    return;
  } else if (data.length < kMinLengthForBlockSplitting) {
    split.num_types = 1;
    split.types.push(0);
    split.lengths.push(data.length);
    return;
  }
  var histograms:Array<Histogram>=new Array();
  // Find good entropy codes.
  InitialEntropyCodes(HistogramTypeInt,data, data.length,
                      literals_per_histogram,
                      max_histograms,
                      sampling_stride_length,
                      histograms);
  RefineEntropyCodes(HistogramTypeInt,data, data.length,
                     sampling_stride_length,
                     histograms);
  // Find a good path through literals with the good entropy codes.
  var block_ids:Vector<UInt>=FunctionMalloc.mallocUInt(data.length);
  for (i in 0...10) {
    FindBlocks(HistogramTypeInt,data, data.length,
               block_switch_cost,
               histograms,
               block_ids,0);
    BuildBlockHistograms(HistogramTypeInt,data, data.length, block_ids,0, histograms);
  }
  ClusterBlocks(HistogramTypeInt,data, data.length, block_ids);//,0
  BuildBlockSplit(block_ids, split);//, 0
}

public static function SplitBlock(cmds:Array<Command>,
                num_commands:Int,
                data:Vector<UInt>,
                data_off:Int,
                literal_split:BlockSplit,
                insert_and_copy_split:BlockSplit,
                dist_split:BlockSplit) {
  // Create a continuous array of literals.
  var literals:Array<UInt>=new Array();
  CopyLiteralsToByteArray(cmds, num_commands, data,data_off, literals);

  // Compute prefix codes for commands.
  var insert_and_copy_codes:Array<UInt>=new Array();
  var distance_prefixes:Array<UInt>=new Array();
  CopyCommandsToByteArray(cmds, num_commands,
                          insert_and_copy_codes,
                          distance_prefixes);

  SplitByteVector(HistogramLiteralInt,
      literals,
      kSymbolsPerLiteralHistogram, kMaxLiteralHistograms,
      kLiteralStrideLength, kLiteralBlockSwitchCost,
      literal_split);
  SplitByteVector(HistogramCommandInt,
      insert_and_copy_codes,
      kSymbolsPerCommandHistogram, kMaxCommandHistograms,
      kCommandStrideLength, kCommandBlockSwitchCost,
      insert_and_copy_split);
  SplitByteVector(HistogramDistanceInt,
      distance_prefixes,
      kSymbolsPerDistanceHistogram, kMaxCommandHistograms,
      kCommandStrideLength, kDistanceBlockSwitchCost,
      dist_split);
}

	public function new() 
	{
		
	}
	
}
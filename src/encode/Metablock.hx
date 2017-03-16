package encode;
import encode.histogram.Histogram;
import haxe.ds.Vector;
import encode.metablock.*;
import encode.Histogram_functions.*;
import encode.Prefix.*;
import encode.Context.*;
import encode.Block_splitter.*;
import encode.command.Command;
import encode.Cluster.*;
import encode.Entropy_encode.*;

/**
 * ...
 * @author 
 */
class Metablock
{

static public function BuildMetaBlock(ringbuffer:Vector<UInt>,
                    pos:Int,
                    mask:Int,
                    prev_byte:UInt,
                    prev_byte2:UInt,
                    cmds:Array<Command>,
                    num_commands:Int,
                    literal_context_mode,
                    mb:MetaBlockSplit) {
  SplitBlock(cmds, num_commands,
             ringbuffer,pos & mask,
             mb.literal_split,
             mb.command_split,
             mb.distance_split);

  var literal_context_modes = new Array();
  for (i in 0...mb.literal_split.num_types)
  literal_context_modes[i] = literal_context_mode;//TODO:

  var num_literal_contexts:Int =
      mb.literal_split.num_types << kLiteralContextBits;
  var num_distance_contexts:Int =
      mb.distance_split.num_types << kDistanceContextBits;
	var literal_histograms:Array<Histogram>=new Array();
	for(i in 0...num_literal_contexts)
	literal_histograms.push(new Histogram(HistogramLiteralInt));
	mb.command_histograms = [];
	for(i in 0...mb.command_split.num_types)
  mb.command_histograms.push(new Histogram(HistogramCommandInt));//TODO:.resize
	var distance_histograms:Array<Histogram>=new Array();
	for(i in 0...num_distance_contexts)
	distance_histograms.push(new Histogram(HistogramDistanceInt));
  BuildHistograms(cmds, num_commands,
                  mb.literal_split,
                  mb.command_split,
                  mb.distance_split,
                  ringbuffer,
                  pos,
                  mask,
                  prev_byte,
                  prev_byte2,
                  literal_context_modes,
                  literal_histograms,//&
                  mb.command_histograms,//&
                  distance_histograms);//&

  // Histogram ids need to fit in one byte.
	var kMaxNumberOfHistograms:Int = 256;

  for (i in 0...literal_histograms.length) {//TODO:
  mb.literal_histograms[i] = new Histogram(HistogramLiteralInt);
  mb.literal_histograms[i].bit_cost_ = literal_histograms[i].bit_cost_;
  for(a in 0...literal_histograms[i].data_.length)
  mb.literal_histograms[i].data_[a] = literal_histograms[i].data_[a];
  mb.literal_histograms[i].kDataSize = literal_histograms[i].kDataSize;
  mb.literal_histograms[i].total_count_ = literal_histograms[i].total_count_;
  }
  mb.literal_context_map = new Vector((1 << kLiteralContextBits)*mb.literal_split.num_types);//TODO:
  ClusterHistograms(literal_histograms,
                    1 << kLiteralContextBits,
                    mb.literal_split.num_types,
                    kMaxNumberOfHistograms,
                    mb.literal_histograms,HistogramLiteralInt,//&
                    mb.literal_context_map);//&

  //mb.distance_histograms = distance_histograms;
  for (i in 0...distance_histograms.length) {//TODO:
  mb.distance_histograms[i] = new Histogram(HistogramDistanceInt);
  mb.distance_histograms[i].bit_cost_ = distance_histograms[i].bit_cost_;
  for(a in 0...distance_histograms[i].data_.length)
  mb.distance_histograms[i].data_[a] = distance_histograms[i].data_[a];
  mb.distance_histograms[i].kDataSize = distance_histograms[i].kDataSize;
  mb.distance_histograms[i].total_count_ = distance_histograms[i].total_count_;
  }
  mb.distance_context_map = new Vector((1 << kDistanceContextBits)*mb.distance_split.num_types);//TODO:
  ClusterHistograms(distance_histograms,
                    1 << kDistanceContextBits,
                    mb.distance_split.num_types,
                    kMaxNumberOfHistograms,
                    mb.distance_histograms,HistogramDistanceInt,//&
                    mb.distance_context_map);//&
}

static public function BuildMetaBlockGreedy(ringbuffer:Vector<UInt>,
                          pos:Int,
                          mask:Int,
                          commands:Array<Command>,
                          n_commands:Int,
                          mb:MetaBlockSplit) {
  var num_literals:Int = 0;
  for (i in 0...n_commands) {
    num_literals += commands[i].insert_len_;
  }

  var lit_blocks=new BlockSplitter(HistogramLiteralInt,
      256, 512, 400.0, num_literals,
      mb.literal_split, mb.literal_histograms);
  var cmd_blocks=new BlockSplitter(HistogramCommandInt,
      kNumCommandPrefixes, 1024, 500.0, n_commands,
      mb.command_split, mb.command_histograms);
  var dist_blocks=new BlockSplitter(HistogramDistanceInt,
      64, 512, 100.0, n_commands,
      mb.distance_split, mb.distance_histograms);

  for (i in 0...n_commands) {
    var cmd:Command = commands[i];
    cmd_blocks.AddSymbol(cmd.cmd_prefix_[0]);
    for (j in 0...cmd.insert_len_) {
      lit_blocks.AddSymbol(ringbuffer[pos & mask]);
      ++pos;
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0 && cmd.cmd_prefix_[0] >= 128) {
      dist_blocks.AddSymbol(cmd.dist_prefix_[0]);
    }
  }

  lit_blocks.FinishBlock(/* is_final = */ true);
  cmd_blocks.FinishBlock(/* is_final = */ true);
  dist_blocks.FinishBlock(/* is_final = */ true);
}

static public function BuildMetaBlockGreedyWithContexts(ringbuffer:Vector<UInt>,
                                      pos:Int,
                                      mask:Int,
                                      prev_byte:UInt,
                                      prev_byte2:UInt,
                                      literal_context_mode:Int,
                                      num_contexts:Int,
                                      static_context_map:Array<Int>,
                                      commands:Array<Command>,
                                      n_commands:Int,
                                      mb:MetaBlockSplit) {
  var num_literals:Int = 0;
  for (i in 0...n_commands) {
    num_literals += commands[i].insert_len_;
  }

  var lit_blocks=new ContextBlockSplitter(HistogramLiteralInt,
      256, num_contexts, 512, 400.0, num_literals,
      mb.literal_split, mb.literal_histograms);
  var cmd_blocks=new BlockSplitter(HistogramCommandInt,
      kNumCommandPrefixes, 1024, 500.0, n_commands,
      mb.command_split, mb.command_histograms);
  var dist_blocks=new BlockSplitter(HistogramDistanceInt,
      64, 512, 100.0, n_commands,
      mb.distance_split, mb.distance_histograms);

  for (i in 0...n_commands) {
    var cmd:Command = commands[i];
    cmd_blocks.AddSymbol(cmd.cmd_prefix_[0]);
    for (j in 0...cmd.insert_len_) {
      var context:Int = ContextFunction(prev_byte, prev_byte2, literal_context_mode);
      var literal:UInt = ringbuffer[pos & mask];
      lit_blocks.AddSymbol(literal, static_context_map[context]);
      prev_byte2 = prev_byte;
      prev_byte = literal;
      ++pos;
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0) {
      prev_byte2 = ringbuffer[(pos - 2) & mask];
      prev_byte = ringbuffer[(pos - 1) & mask];
	  var cmd_prefix_:Int = cmd.cmd_prefix_[0];
      if (cmd_prefix_ >= 128) {
        dist_blocks.AddSymbol(cmd.dist_prefix_[0]);
      }
    }
  }

  lit_blocks.FinishBlock(/* is_final = */ true);
  cmd_blocks.FinishBlock(/* is_final = */ true);
  dist_blocks.FinishBlock(/* is_final = */ true);

  mb.literal_context_map=FunctionMalloc.mallocInt(//.resize
      mb.literal_split.num_types << kLiteralContextBits);/**/
  for (i in 0...mb.literal_split.num_types) {
    for (j in 0...(1 << kLiteralContextBits)) {
      mb.literal_context_map[(i << kLiteralContextBits) + j] =
          i * num_contexts + static_context_map[j];
    }
  }
}

static public function OptimizeHistograms(num_direct_distance_codes:Int,
                        distance_postfix_bits:Int,
                        mb:MetaBlockSplit) {
  for (i in 0...mb.literal_histograms.length) {
    OptimizeHuffmanCountsForRle(256, mb.literal_histograms[i].data_);//,0
  }
  for (i in 0...mb.command_histograms.length) {
    OptimizeHuffmanCountsForRle(kNumCommandPrefixes,
                                mb.command_histograms[i].data_);//,0
  }
  var num_distance_codes:Int =
      kNumDistanceShortCodes + num_direct_distance_codes +
      (48 << distance_postfix_bits);
  for (i in 0...mb.distance_histograms.length) {
    OptimizeHuffmanCountsForRle(num_distance_codes,
                                mb.distance_histograms[i].data_);//,0
  }
}

	public function new() 
	{
		
	}
	
}
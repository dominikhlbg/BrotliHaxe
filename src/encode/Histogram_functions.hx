package encode;
import encode.histogram.Histogram;
import encode.Prefix.*;
import haxe.ds.Vector;
import encode.metablock.BlockSplit;
import encode.block_splitter.BlockSplitIterator;
import encode.Context.*;
import encode.command.Command;

/**
 * ...
 * @author 
 */
class Histogram_functions
{

// Literal histogram.
public static function HistogramLiteral(){return new Histogram(256);}
public static var HistogramLiteralInt= 256;
// Prefix histograms.
public static function HistogramCommand(){return new Histogram(kNumCommandPrefixes);}
public static var HistogramCommandInt= kNumCommandPrefixes;
public static function HistogramDistance(){return new Histogram(kNumDistancePrefixes);}
public static var HistogramDistanceInt= kNumDistancePrefixes;
public static function HistogramBlockLength(){return new Histogram(kNumBlockLenPrefixes);}
public static var HistogramBlockLengthInt= kNumBlockLenPrefixes;
// Context map histogram, 256 Huffman tree indexes + 16 run length codes.
public static function HistogramContextMap(){return new Histogram(272);}
public static var HistogramContextMapInt= 272;
// Block type histogram, 256 block types + 2 special symbols.
public static function HistogramBlockType(){return new Histogram(258);}
public static var HistogramBlockTypeInt= 258;

public static inline var kLiteralContextBits:Int = 6;
public static inline var kDistanceContextBits:Int = 2;

public static function BuildHistograms(
    cmds:Array<Command>,
    num_commands:Int,
    literal_split:BlockSplit,
    insert_and_copy_split:BlockSplit,
    dist_split:BlockSplit,
    ringbuffer:Vector<UInt>,
    start_pos:Int,
    mask:Int,
    prev_byte:UInt,
    prev_byte2:UInt,
    context_modes:Array<Int>,
    literal_histograms:Array<Histogram>,
    insert_and_copy_histograms:Array<Histogram>,
    copy_dist_histograms:Array<Histogram>) {
  var pos:Int = start_pos;
  var literal_it=new BlockSplitIterator(literal_split);
  var insert_and_copy_it=new BlockSplitIterator(insert_and_copy_split);
  var dist_it=new BlockSplitIterator(dist_split);
  for (i in 0...num_commands) {
    var cmd:Command = cmds[i];
    insert_and_copy_it.Next();
    insert_and_copy_histograms[insert_and_copy_it.type_].Add1(
        cmd.cmd_prefix_[0]);
    for (j in 0...cmd.insert_len_) {
      literal_it.Next();
      var context:Int = (literal_it.type_ << kLiteralContextBits) +
          ContextFunction(prev_byte, prev_byte2, context_modes[literal_it.type_]);
      literal_histograms[context].Add1(ringbuffer[pos & mask]);
      prev_byte2 = prev_byte;
      prev_byte = ringbuffer[pos & mask];
      ++pos;
    }
    pos += cmd.copy_len_;
    if (cmd.copy_len_ > 0) {
      prev_byte2 = ringbuffer[(pos - 2) & mask];
      prev_byte = ringbuffer[(pos - 1) & mask];
      if (cmd.cmd_prefix_[0] >= 128) {
        dist_it.Next();
        var context:Int = (dist_it.type_ << kDistanceContextBits) +
            cmd.DistanceContext();
        copy_dist_histograms[context].Add1(cmd.dist_prefix_[0]);
      }
    }
  }
}

	public function new() 
	{
		
	}
	
}
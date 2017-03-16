package encode;
import encode.encode.BrotliCompressor;
import encode.encode.BrotliParams;
import encode.streams.*;
import encode.streams.BrotliOut;
import DefaultFunctions;
import haxe.ds.Vector;
import encode.Prefix.*;
import encode.Context.*;
import encode.command.Command;
/**
 * ...
 * @author 
 */
class Encode
{
	public static var kMaxWindowBits:Int = 24;
	public static var kMinWindowBits:Int = 16;
	public static var kMinInputBlockBits:Int = 16;
	public static var kMaxInputBlockBits:Int = 24;

	public static var kMinUTF8Ratio:Float = 0.75;
	public static var kMinQualityForBlockSplit:Int = 4;
	public static var kMinQualityForContextModeling:Int = 5;
	public static var kMinQualityForOptimizeHistograms:Int = 4;

//45
	public static function ParseAsUTF8(symbol:Array<Int>, input:Vector<UInt>, input_off:Int, size:Int):Int {
  // ASCII
  if ((input[input_off+0] & 0x80) == 0) {
    symbol[0] = input[input_off+0];
    if (symbol[0] > 0) {
      return 1;
    }
  }
  // 2-byte UTF8
  if (size > 1 &&
      (input[input_off+0] & 0xe0) == 0xc0 &&
      (input[input_off+1] & 0xc0) == 0x80) {
    symbol[0] = (((input[input_off+0] & 0x1f) << 6) |
               (input[input_off+1] & 0x3f));
    if (symbol[0] > 0x7f) {
      return 2;
    }
  }
  // 3-byte UFT8
  if (size > 2 &&
      (input[input_off+0] & 0xf0) == 0xe0 &&
      (input[input_off+1] & 0xc0) == 0x80 &&
      (input[input_off+2] & 0xc0) == 0x80) {
    symbol[0] = (((input[input_off+0] & 0x0f) << 12) |
               ((input[input_off+1] & 0x3f) << 6) |
               (input[input_off+2] & 0x3f));
    if (symbol[0] > 0x7ff) {
      return 3;
    }
  }
  // 4-byte UFT8
  if (size > 3 &&
      (input[input_off+0] & 0xf8) == 0xf0 &&
      (input[input_off+1] & 0xc0) == 0x80 &&
      (input[input_off+2] & 0xc0) == 0x80 &&
      (input[input_off+3] & 0xc0) == 0x80) {
    symbol[0] = (((input[input_off+0] & 0x07) << 18) |
               ((input[input_off+1] & 0x3f) << 12) |
               ((input[input_off+2] & 0x3f) << 6) |
               (input[input_off+3] & 0x3f));
    if (symbol[0] > 0xffff && symbol[0] <= 0x10ffff) {
      return 4;
    }
  }
  // Not UTF8, emit a special symbol above the UTF8-code space
  symbol[0] = 0x110000 | input[input_off+0];
  return 1;
}

//94
// Returns true if at least min_fraction of the data is UTF8-encoded.
public static function IsMostlyUTF8(data:Vector<UInt>, data_off:Int, length:Int, min_fraction:Float):Bool {
  var size_utf8:Int = 0;
  var pos:Int = 0;
  while (pos < length) {
    var symbol:Array<Int>=new Array();
    var bytes_read = ParseAsUTF8(symbol, data,data_off + pos, length - pos);
    pos += bytes_read;
    if (symbol[0] < 0x110000) size_utf8 += bytes_read;
  }
  return size_utf8 > min_fraction * length;
}

public static function RecomputeDistancePrefixes(cmds:Array<Command>,
                               num_commands:Int,
                               num_direct_distance_codes:Int,
                               distance_postfix_bits:Int) {
  if (num_direct_distance_codes == 0 &&
      distance_postfix_bits == 0) {
    return;
  }
  for (i in 0...num_commands) {
    var cmd:Command = cmds[i];
    if (cmd.copy_len_ > 0 && cmd.cmd_prefix_[0] >= 128) {
      PrefixEncodeCopyDistance(cmd.DistanceCode(),
                               num_direct_distance_codes,
                               distance_postfix_bits,
                               cmd.dist_prefix_,//&
                               cmd.dist_extra_);//&
    }
  }
}

public static function DecideOverLiteralContextModeling(input:Vector<UInt>,
                                      start_pos:Int,
                                      length:Int,
                                      mask:Int,
                                      quality:Int,
                                      literal_context_mode:Array<Int>,
                                      num_literal_contexts:Array<Int>,
                                      literal_context_map:Array<Array<Int>>) {
  if (quality < kMinQualityForContextModeling || length < 64) {
    return;
  }
  // Simple heuristics to guess if the data is UTF8 or not. The goal is to
  // recognize non-UTF8 data quickly by searching for the following obvious
  // violations: a continuation byte following an ASCII byte or an ASCII or
  // lead byte following a lead byte. If we find such violation we decide that
  // the data is not UTF8. To make the analysis of UTF8 data faster we only
  // examine 64 byte long strides at every 4kB intervals, if there are no
  // violations found, we assume the whole data is UTF8.
  var end_pos:Int = start_pos + length;
  while (start_pos + 64 < end_pos) {
    var stride_end_pos:Int = start_pos + 64;
    var prev:UInt = input[start_pos & mask];
    for (pos in start_pos + 1...stride_end_pos) {
      var literal:UInt = input[pos & mask];
      if ((prev < 128 && (literal & 0xc0) == 0x80) ||
          (prev >= 192 && (literal & 0xc0) != 0x80)) {
        return;
      }
      prev = literal;
    }
	start_pos += 4096;
  }
  literal_context_mode[0] = CONTEXT_UTF8;
  // If the data is UTF8, this static context map distinguishes between ASCII
  // or lead bytes and continuation bytes: the UTF8 context value based on the
  // last two bytes is 2 or 3 if and only if the next byte is a continuation
  // byte (see table in context.h).
  var kStaticContextMap:Array<Int> = [//[64]
    0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ];
  var kNumLiteralContexts:Int = 2;
  num_literal_contexts[0] = kNumLiteralContexts;
  literal_context_map[0] = kStaticContextMap;
}

//600
	public static function CopyOneBlockToRingBuffer(r:Dynamic, compressor:BrotliCompressor):Int {
  var block_size:Int = compressor.input_block_size();
  var bytes_read:Array<UInt> = [0];
  var data:Vector<UInt> = r.Read(block_size, bytes_read);
  if (data == null) {
    return 0;
  }
  compressor.CopyInputToRingBuffer(bytes_read[0], data);

  // Read more bytes until block_size is filled or an EOF (data == NULL) is
  // received. This is useful to get deterministic compressed output for the
  // same input no matter how r->Read splits the input to chunks.
  var remaining:Int = block_size - bytes_read[0];
  while ( remaining > 0 ) {
    var more_bytes_read:Array<UInt> = [0];
    data = r.Read(remaining, more_bytes_read);
    if (data == null) {
      break;
    }
    compressor.CopyInputToRingBuffer(more_bytes_read[0], data);
    bytes_read[0] += more_bytes_read[0];
    remaining -= more_bytes_read[0];
  }
  return bytes_read[0];
}
//627
static public function BrotliInIsFinished(r:Dynamic):Bool {
  var read_bytes:Array<Int>=new Array();
  return r.Read(0, read_bytes) == null;
}

//632
static public function BrotliCompress(params:BrotliParams, input:Dynamic, output:Dynamic):Bool {
  return BrotliCompressWithCustomDictionary(0, null, params, input, output);
}
//
static public function BrotliCompressWithCustomDictionary( dictsize:Int, dict:Vector<UInt>,//*
                                        params:BrotliParams,
                                       input:Dynamic, output:Dynamic):Bool {
  var in_bytes:Int = 0;
  var out_bytes:Array<Int> = [0];
  var out:Array<Vector<UInt>>=new Array();//*
  var final_block:Bool = false;
  var compressor=new BrotliCompressor(params);
  if (dictsize != 0) compressor.BrotliSetCustomDictionary(dictsize, dict);
  while (!final_block) {
    in_bytes = CopyOneBlockToRingBuffer(input, compressor);
    final_block = in_bytes == 0 || BrotliInIsFinished(input);
    out_bytes[0] = 0;
    if (!compressor.WriteBrotliData(final_block,
                                    /* force_flush = */ false,
                                    out_bytes, out)) {
      return false;
    }
    if (out_bytes[0] > 0 && !output.Write(out[0], out_bytes[0])) {
      return false;
    }
  }
  return true;
}

	public function new() 
	{
		
	}
	
}
package encode;
import haxe.ds.Vector;
import encode.Fast_log.*;
/**
 * ...
 * @author 
 */
class Literal_cost
{

public static function UTF8Position(last:Int, c:Int, clamp:Int):Int {
  if (c < 128) {
    return 0;  // Next one is the 'Byte 1' again.
  } else if (c >= 192) {
    return Std.int(Math.min(1, clamp));  // Next one is the 'Byte 2' of utf-8 encoding.
  } else {
    // Let's decide over the last byte if this ends the sequence.
    if (last < 0xe0) {
      return 0;  // Completed two or three byte coding.
    } else {
      return Std.int(Math.min(2, clamp));  // Next one is the 'Byte 3' of utf-8 encoding.
    }
  }
}

public static function DecideMultiByteStatsLevel(pos:Int, len:Int, mask:Int,
                                     data:Vector<UInt>):Int {
  var counts = [ 0,0,0 ];
  var max_utf8:Int = 1;  // should be 2, but 1 compresses better.
  var last_c:Int = 0;
  var utf8_pos:Int = 0;
  for (i in 0...len) {
    var c:Int = data[(pos + i) & mask];
    utf8_pos = UTF8Position(last_c, c, 2);
    ++counts[utf8_pos];
    last_c = c;
  }
  if (counts[2] < 500) {
    max_utf8 = 1;
  }
  if (counts[1] + counts[2] < 25) {
    max_utf8 = 0;
  }
  return max_utf8;
}

public static function EstimateBitCostsForLiteralsUTF8(pos:Int, len:Int, mask:Int,
                                     cost_mask:Int, data:Vector<UInt>,
                                     cost:Vector<Float>) {

  // max_utf8 is 0 (normal ascii single byte modeling),
  // 1 (for 2-byte utf-8 modeling), or 2 (for 3-byte utf-8 modeling).
  var max_utf8:Int = DecideMultiByteStatsLevel(pos, len, mask, data);
  var histogram:Array<Vector<Int>> = [FunctionMalloc.mallocInt(256),FunctionMalloc.mallocInt(256),FunctionMalloc.mallocInt(256)];// [3][256] = { { 0 } };
  var window_half:Int = 495;
  var in_window:Int = Std.int(Math.min(window_half, len));
  var in_window_utf8:Array<Int> = [ 0,0,0 ];

  // Bootstrap histograms.
  var last_c:Int = 0;
  var utf8_pos:Int = 0;
  for (i in 0...in_window) {
    var c:Int = data[(pos + i) & mask];
    histogram[utf8_pos][c]+=1;
    ++in_window_utf8[utf8_pos];
    utf8_pos = UTF8Position(last_c, c, max_utf8);
    last_c = c;
  }

  // Compute bit costs with sliding window.
  for (i in 0...len) {
    if (i - window_half >= 0) {
      // Remove a byte in the past.
      var c:Int = (i - window_half - 1) < 0 ?
          0 : data[(pos + i - window_half - 1) & mask];
      var last_c:Int = (i - window_half - 2) < 0 ?
          0 : data[(pos + i - window_half - 2) & mask];
      var utf8_pos2:Int = UTF8Position(last_c, c, max_utf8);
      histogram[utf8_pos2][data[(pos + i - window_half) & mask]]-=1;
      --in_window_utf8[utf8_pos2];
    }
    if (i + window_half < len) {
      // Add a byte in the future.
      var c:Int = (i + window_half - 1) < 0 ?
          0 : data[(pos + i + window_half - 1) & mask];
      var last_c:Int = (i + window_half - 2) < 0 ?
          0 : data[(pos + i + window_half - 2) & mask];
      var utf8_pos2:Int = UTF8Position(last_c, c, max_utf8);
      histogram[utf8_pos2][data[(pos + i + window_half) & mask]]+=1;
      ++in_window_utf8[utf8_pos2];
    }
    var c:Int = i < 1 ? 0 : data[(pos + i - 1) & mask];
    var last_c:Int = i < 2 ? 0 : data[(pos + i - 2) & mask];
    var utf8_pos:Int = UTF8Position(last_c, c, max_utf8);
    var masked_pos:Int = (pos + i) & mask;
    var histo:Int = histogram[utf8_pos][data[masked_pos]];
    if (histo == 0) {
      histo = 1;
    }
    var lit_cost:Float = FastLog2(in_window_utf8[utf8_pos]) - FastLog2(histo);
    lit_cost += 0.02905;
    if (lit_cost < 1.0) {
      lit_cost *= 0.5;
      lit_cost += 0.5;
    }
    // Make the first bytes more expensive -- seems to help, not sure why.
    // Perhaps because the entropy source is changing its properties
    // rapidly in the beginning of the file, perhaps because the beginning
    // of the data is a statistical "anomaly".
    if (i < 2000) {
      lit_cost += 0.7 - ((2000 - i) / 2000.0 * 0.35);
    }
    cost[(pos + i) & cost_mask] = lit_cost;
  }
}

public static function EstimateBitCostsForLiterals(pos:Int, len:Int, mask:Int,
                                 cost_mask:Int, data:Vector<UInt>,
                                 cost:Vector<Float>) {
  var histogram = FunctionMalloc.mallocInt(256);// [256] = { 0 };
  var window_half:Int = 2000;
  var in_window:Int = Std.int(Math.min((window_half), len));

  // Bootstrap histogram.
  for (i in 0...in_window) {
    histogram[data[(pos + i) & mask]]+=1;
  }

  // Compute bit costs with sliding window.
  for (i in 0...len) {
    if (i - window_half >= 0) {
      // Remove a byte in the past.
      histogram[data[(pos + i - window_half) & mask]]-=1;
      --in_window;
    }
    if (i + window_half < len) {
      // Add a byte in the future.
      histogram[data[(pos + i + window_half) & mask]]+=1;
      ++in_window;
    }
    var histo:Int = histogram[data[(pos + i) & mask]];
    if (histo == 0) {
      histo = 1;
    }
    var lit_cost:Float = FastLog2(in_window) - FastLog2(histo);
    lit_cost += 0.029;
    if (lit_cost < 1.0) {
      lit_cost *= 0.5;
      lit_cost += 0.5;
    }
    cost[(pos + i) & cost_mask] = lit_cost;
  }
}

	public function new() 
	{
		
	}
	
}
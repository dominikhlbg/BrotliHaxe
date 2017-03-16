package encode.backward_references;
import haxe.ds.Vector;
import encode.Prefix.*;
import encode.Fast_log.*;
import encode.Command_functions.*;
import encode.Backward_references.*;
import encode.command.Command;

/**
 * ...
 * @author 
 */
class ZopfliCostModel
{
	public function SetFromCommands(num_bytes:Int,
                       position:Int,
                       ringbuffer:Vector<UInt>,
                       ringbuffer_mask:Int,
                       commands:Array<Command>,//*
                       num_commands:Int,
                       last_insert_len:Int) {
    var histogram_literal=FunctionMalloc.mallocInt(256);
    var histogram_cmd=FunctionMalloc.mallocInt(kNumCommandPrefixes);
    var histogram_dist=FunctionMalloc.mallocInt(kNumDistancePrefixes);

    var pos:Int = position - last_insert_len;
    for (i in 0...num_commands) {
      var inslength:Int = commands[i].insert_len_;
      var copylength:Int = commands[i].copy_len_;
      var distcode:Int = commands[i].dist_prefix_[0];
      var cmdcode:Int = commands[i].cmd_prefix_[0];

      histogram_cmd[cmdcode]+=1;
      if (cmdcode >= 128) histogram_dist[distcode]+=1;

      for (j in 0...inslength) {
        histogram_literal[ringbuffer[(pos + j) & ringbuffer_mask]]+=1;
      }

      pos += inslength + copylength;
    }

    var cost_literal_:Array<Vector<Float>>=new Array();
    Set(histogram_literal, cost_literal_);
	var cost_literal = cost_literal_[0];
	var cost_cmd = [cost_cmd_];
    Set(histogram_cmd, cost_cmd);
	cost_cmd_ = cost_cmd[0];
	var cost_dist = [cost_dist_];
    Set(histogram_dist, cost_dist);
	cost_dist_ = cost_dist[0];

    min_cost_cmd_ = kInfinity;
    for (i in 0...kNumCommandPrefixes) {
      min_cost_cmd_ = Math.min(min_cost_cmd_, cost_cmd_[i]);
    }

    literal_costs_=new Vector<Float>(num_bytes + 1);
    literal_costs_[0] = 0.0;
    for (i in 0...num_bytes) {
      literal_costs_[i + 1] = literal_costs_[i] +
          cost_literal[ringbuffer[(position + i) & ringbuffer_mask]];
    }
  }

	public function SetFromLiteralCosts(num_bytes:Int,
                           position:Int,
                           literal_cost:Vector<Float>,
                           literal_cost_mask:Int) {
    literal_costs_=FunctionMalloc.mallocFloat(num_bytes + 1);
    literal_costs_[0] = 0.0;
    if (literal_cost!=null) {
      for (i in 0...num_bytes) {
        literal_costs_[i + 1] = literal_costs_[i] +
            literal_cost[(position + i) & literal_cost_mask];
      }
    } else {
      for (i in 1...num_bytes+1) {
        literal_costs_[i] = i * 5.4;
      }
    }
    cost_cmd_=new Vector<Float>(kNumCommandPrefixes);
    cost_dist_=new Vector<Float>(kNumDistancePrefixes);
    for (i in 0...kNumCommandPrefixes) {
      cost_cmd_[i] = FastLog2(11 + i);
    }
    for (i in 0...kNumDistancePrefixes) {
      cost_dist_[i] = FastLog2(20 + i);
    }
    min_cost_cmd_ = FastLog2(11);
  }

  public function GetCommandCost(
      dist_code:Int, length_code:Int, insert_length:Int):Float {
    var inscode:Int = GetInsertLengthCode(insert_length);
    var copycode:Int = GetCopyLengthCode(length_code);
    var cmdcode:UInt = CombineLengthCodes(inscode, copycode, dist_code);
    var insnumextra:UInt = insextra[inscode];
    var copynumextra:UInt = copyextra[copycode];
    var dist_symbol:Array<UInt>=new Array();
    var distextra:Array<UInt>=new Array();
    GetDistCode(dist_code, dist_symbol, distextra);
    var distnumextra:UInt = distextra[0] >> 24;

    var result:Float = insnumextra + copynumextra + distnumextra;
    result += cost_cmd_[cmdcode];
    if (cmdcode >= 128) result += cost_dist_[dist_symbol[0]];
    return result;
  }

  public function GetLiteralCosts(from:Int, to:Int):Float {
    return literal_costs_[to] - literal_costs_[from];
  }

  public function GetMinCostCmd():Float {
    return min_cost_cmd_;
  }
  
  function Set(histogram:Vector<Int>, cost:Array<Vector<Float>>) {
    cost[0]=new Vector<Float>(histogram.length);
    var sum:Int = 0;
    for (i in 0...histogram.length) {
      sum += histogram[i];
    }
    var log2sum:Float = FastLog2(sum);
    for (i in 0...histogram.length) {
      if (histogram[i] == 0) {
        cost[0][i] = log2sum + 2;
        continue;
      }

      // Shannon bits for this symbol.
      cost[0][i] = log2sum - FastLog2(histogram[i]);

      // Cannot be coded with less than 1 bit
      if (cost[0][i] < 1) cost[0][i] = 1;
    }
  }
	var cost_cmd_:Vector<Float>;  // The insert and copy length symbols.
  var cost_dist_:Vector<Float>;
  // Cumulative costs of literals per position in the stream.
  var literal_costs_:Vector<Float>;
  var min_cost_cmd_:Float;
	public function new() 
	{
		
	}
	
}
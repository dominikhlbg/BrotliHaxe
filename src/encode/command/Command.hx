package encode.command;
import haxe.ds.Vector;
import encode.Command_functions.*;

/**
 * ...
 * @author 
 */
class Command
{

	public var insert_len_:Int;
	public var copy_len_:Int;
	public var cmd_prefix_:Array<UInt>=new Array();
	public var dist_prefix_:Array<UInt>=new Array();
	public var cmd_extra_:Array<UInt>=new Array();
	public var dist_extra_:Array<UInt>=new Array();

  public function Command0() {}

  // distance_code is e.g. 0 for same-as-last short code, or 16 for offset 1.
  public function Command4(insertlen:Int, copylen:Int, copylen_code:Int, distance_code:Int)
     { insert_len_ = insertlen; copy_len_ = copylen;
    GetDistCode(distance_code, dist_prefix_, dist_extra_);
    GetLengthCode(insertlen, copylen_code, dist_prefix_[0],
                  cmd_prefix_, cmd_extra_);
  }

  public function Command1(insertlen:Int)
      { insert_len_ = insertlen; copy_len_ = 0; dist_prefix_[0] = 16; dist_extra_[0] = 0;
    GetLengthCode(insertlen, 4, dist_prefix_[0], cmd_prefix_, cmd_extra_);
  }

  public function DistanceCode():Int {
    if (dist_prefix_[0] < 16) {
      return dist_prefix_[0];
    }
    var nbits:Int = dist_extra_[0] >> 24;
    var extra:Int = dist_extra_[0] & 0xffffff;
    var prefix:Int = dist_prefix_[0] - 12 - 2 * nbits;
    return (prefix << nbits) + extra + 12;
  }

  public function DistanceContext():Int {
    var c:Int = cmd_prefix_[0] & 7;
    var r:Int = cmd_prefix_[0] >> 6;
    if ((r == 0 || r == 2 || r == 4 || r == 7) && (c <= 2)) {
      return c;
    }
    return 3;
  }

	public function new() 
	{
		
	}
	
}
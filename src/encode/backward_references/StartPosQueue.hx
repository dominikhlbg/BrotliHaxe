package encode.backward_references;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class Pair
{

	public function new(first:Int,second:Float) 
	{
		this.first = first;
		this.second = second;		
	}
	public var first:Int;
	public var second:Float;	
}
class StartPosQueue
{

	public function new(bits:Int) 
	{
		mask_ = (1 << bits) - 1; q_ = FunctionMalloc.malloc2_(Pair,1 << bits); idx_ = 0;
	}
	public function Clear() {
    idx_ = 0;
  }

  public function Push(pos:Int, costdiff:Float) {
    q_[idx_ & mask_] = new Pair(pos, costdiff);
    // Restore the sorted order.
	var i = idx_;
    while (i > 0 && i > idx_ - mask_) {
      if (q_[i & mask_].second > q_[(i - 1) & mask_].second) {
        var t1 = q_[i & mask_].first;
        var t2 = q_[i & mask_].second;
        q_[i & mask_].first = q_[(i - 1) & mask_].first;
        q_[i & mask_].second = q_[(i - 1) & mask_].second;
        q_[(i - 1) & mask_].first = t1;
        q_[(i - 1) & mask_].second = t2;
      }
	  --i;
    }
    ++idx_;
  }

  public function size():Int { return Std.int(Math.min(idx_, mask_ + 1)); }
  
  public function GetStartPos(k:Int) {
    return q_[(idx_ - k - 1) & mask_].first;
  }
  var mask_:Int;
	var q_:Vector<Pair>;//<Int,Float>;
  var idx_:Int;
	
}
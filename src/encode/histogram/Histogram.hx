package encode.histogram;
import DefaultFunctions.*;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class Histogram
{

  public function Clear() {
    memset(data_,0 , 0, data_.length);
    total_count_ = 0;
  }
  public function Add1(val:Int) {
    data_[val]+=1;
    ++total_count_;
  }
  public function Remove(val:Int) {
    data_[val]-=1;
    --total_count_;
  }

  public function Add2(p:Array<UInt>, p_off:Int, n:Int) {//TODO: 
    total_count_ += n;
    n += 1;
    while(--n>0) data_[p[p_off++]]+=1;
  }
  public function AddHistogram(v:Histogram) {
    total_count_ += v.total_count_;
    for (i in 0...kDataSize) {
      data_[i] += v.data_[i];
    }
  }

  public var kDataSize:Int;
  public var data_:Vector<Int>;
  public var total_count_:Int;
  public var bit_cost_:Float;

	public function new(kDataSize:Int) 
	{
	this.kDataSize = kDataSize;
	this.data_=new Vector<Int>(kDataSize);
    Clear();
	}
	
}
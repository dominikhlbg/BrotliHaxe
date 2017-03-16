package encode.backward_references;
import haxe.ds.Vector;
import encode.Backward_references.*;

/**
 * ...
 * @author 
 */
class ZopfliNode
{

  // best length to get up to this byte (not including this byte itself)
	public var length:Int;
  // distance associated with the length
  public var distance:Int;
  public var distance_code:Int;
  public var distance_cache:Vector<Int>=FunctionMalloc.mallocInt(4);
  // length code associated with the length - usually the same as length,
  // except in case of length-changing dictionary transformation.
  public var length_code:Int;
  // number of literal inserts before this copy
  public var insert_length:Int;
  // smallest cost to get to this byte from the beginning, as found so far
	public var cost:Float;
	public function new() 
	{
                 this.length = 1;
                 this.distance=0;
                 this.distance_code=0;
                 this.length_code=0;
                 this.insert_length=0;
                 this.cost=kInfinity;	
	}
	
}
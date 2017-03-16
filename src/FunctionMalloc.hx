package;
import haxe.ds.Vector;
import DefaultFunctions;

/**
 * ...
 * @author 
 */
typedef Constructible = {
  public function new():Void;
}

typedef Constructible2 = {
  public function new(args1:Int,args2:Int):Void;
}

typedef Constructible2_ = {
  public function new(args1:Int,args2:Float):Void;
}

class FunctionMalloc
{
	public static function mallocUInt(a):Vector<UInt> {
		var arr:Vector<UInt> = new Vector<UInt>(a);
		for (i in 0...a)
		arr[i] = 0;
		return arr;
	}
	public static function mallocInt(a):Vector<Int> {
		var arr:Vector<Int> = new Vector<Int>(a);
		for (i in 0...a)
		arr[i] = 0;
		return arr;
	}
	public static function mallocFloat(a):Vector<Float> {
		var arr:Vector<Float> = new Vector<Float>(a);
		for (i in 0...a)
		arr[i] = 0;
		return arr;
	}
	public static function mallocBool(a):Vector<Bool> {
		var arr:Vector<Bool> = new Vector<Bool>(a);
		for (i in 0...a)
		arr[i] = false;
		return arr;
	}
	@:generic public static function malloc<T:Constructible>(t:Class<T>, a):Vector<T> {
		var arr:Vector<T> = new Vector<T>(a);
		for (i in 0...a)
		arr[i] = new T();
		return arr;
	}
	@:generic public static function mallocArray<T:Constructible>(t:Class<T>, a):Array<T> {
		var arr:Array<T> = new Array<T>();
		for (i in 0...a)
		arr[i] = new T();
		return arr;
	}
	@:generic public static function malloc2<T:Constructible2>(t:Class<T>, a):Vector<T> {
		var arr:Vector<T> = new Vector<T>(a);
		for (i in 0...a)
		arr[i] = new T(0,0);
		return arr;
	}
	@:generic public static function malloc2_<T:Constructible2_>(t:Class<T>, a):Vector<T> {
		var arr:Vector<T> = new Vector<T>(a);
		for (i in 0...a)
		arr[i] = new T(0,0);
		return arr;
	}
	public function new() 
	{
		
	}
	
}
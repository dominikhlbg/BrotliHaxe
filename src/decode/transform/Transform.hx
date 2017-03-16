package decode.transform;

/**
 * ...
 * @author 
 */
class Transform
{

	public var prefix:Array<UInt>;//const char*
  public var transform:Int;// WordTransformType;
  public var suffix:Array<UInt>;
	public function new(prefix:String,transform:Int,suffix:String) 
	{
		this.prefix = new Array<UInt>();
		for(i in 0...prefix.length)
		this.prefix[i] = prefix.charCodeAt(i);
		this.transform = transform;
		this.suffix = new Array<UInt>();
		for(i in 0...suffix.length)
		this.suffix[i] = suffix.charCodeAt(i);
	}
	
}
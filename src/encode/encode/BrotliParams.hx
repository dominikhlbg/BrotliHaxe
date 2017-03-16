package encode.encode;

/**
 * ...
 * @author 
 */
  @:enum
abstract Mode(Int) {
    // Default compression mode. The compressor does not know anything in
    // advance about the properties of the input.
    var MODE_GENERIC = 0;
    // Compression mode for UTF-8 format text input.
    var MODE_TEXT = 1;
    // Compression mode used in WOFF 2.0.
    var MODE_FONT = 2;
  }
class BrotliParams
{
	public var mode:Mode;

  // Controls the compression-speed vs compression-density tradeoffs. The higher
  // the quality, the slower the compression. Range is 0 to 11.
  public var quality:Int;
  // Base 2 logarithm of the sliding window size. Range is 16 to 24.
  public var lgwin:Int;
  // Base 2 logarithm of the maximum input block size. Range is 16 to 24.
  // If set to 0, the value will be set based on the quality.
  public var lgblock:Int;

  // These settings are deprecated and will be ignored.
  // All speed vs. size compromises are controlled by the quality param.
  public var enable_dictionary:Bool;
  public var enable_transforms:Bool;
  public var greedy_block_split:Bool;
  public var enable_context_modeling:Bool;
	public function new() 
	{
        this.mode = MODE_GENERIC;
        this.quality=11;
        this.lgwin=22;
        this.lgblock=0;
        this.enable_dictionary=true;
        this.enable_transforms=false;
        this.greedy_block_split=false;
        this.enable_context_modeling=true;
	}
	
}
package encode.hash;
import haxe.ds.Vector;
import DefaultFunctions;

/**
 * ...
 * @author 
 */
class Hashers
{
  // For kBucketSweep == 1, enabling the dictionary lookup makes compression
  // a little faster (0.5% - 1%) and it compresses 0.15% better on small text
  // and html inputs.
  /*var H1=HashLongestMatchQuickly(16, 1, true);
  var H2=HashLongestMatchQuickly(16, 2, false);
  var H3=HashLongestMatchQuickly(16, 4, false);
  var H4=HashLongestMatchQuickly(17, 4, true);
  var H5=HashLongestMatch(14, 4, 4);
  var H6=HashLongestMatch(14, 5, 4);
  var H7=HashLongestMatch(15, 6, 10);
  var H8=HashLongestMatch(15, 7, 10);
  var H9=HashLongestMatch(15, 8, 16);*/

  public function Init(type:Int) {
    switch (type) {
      case 1: this.hash_h1=new HashLongestMatchQuickly(16, 1, true);
      case 2: this.hash_h2=new HashLongestMatchQuickly(16, 2, false);
      case 3: this.hash_h3=new HashLongestMatchQuickly(16, 4, false);
      case 4: this.hash_h4=new HashLongestMatchQuickly(17, 4, true);
      case 5: this.hash_h5=new HashLongestMatch(14, 4, 4);
      case 6: this.hash_h6=new HashLongestMatch(14, 5, 4);
      case 7: this.hash_h7=new HashLongestMatch(15, 6, 10);
      case 8: this.hash_h8=new HashLongestMatch(15, 7, 10);
      case 9: this.hash_h9=new HashLongestMatch(15, 8, 16);
      default:
    }
  }
  public function WarmupHashHashLongestMatchQuickly(size:Int, dict:Vector<UInt>, hasher:HashLongestMatchQuickly) {
    for (i in 0...size) {
      hasher.Store(dict,0, i);
    }
  }
  public function WarmupHashHashLongestMatch(size:Int, dict:Vector<UInt>, hasher:HashLongestMatch) {
    for (i in 0...size) {
      hasher.Store(dict,0, i);
    }
  }

  // Custom LZ77 window.
  public function PrependCustomDictionary(
      type:Int, size:Int, dict:Vector<UInt>) {
    switch (type) {
      case 1: WarmupHashHashLongestMatchQuickly(size, dict, this.hash_h1);
      case 2: WarmupHashHashLongestMatchQuickly(size, dict, this.hash_h2);
      case 3: WarmupHashHashLongestMatchQuickly(size, dict, this.hash_h3);
      case 4: WarmupHashHashLongestMatchQuickly(size, dict, this.hash_h4);
      case 5: WarmupHashHashLongestMatch(size, dict, this.hash_h5);
      case 6: WarmupHashHashLongestMatch(size, dict, this.hash_h6);
      case 7: WarmupHashHashLongestMatch(size, dict, this.hash_h7);
      case 8: WarmupHashHashLongestMatch(size, dict, this.hash_h8);
      case 9: WarmupHashHashLongestMatch(size, dict, this.hash_h9);
      default:
    }
  }

  public var hash_h1:HashLongestMatchQuickly;
  public var hash_h2:HashLongestMatchQuickly;
  public var hash_h3:HashLongestMatchQuickly;
  public var hash_h4:HashLongestMatchQuickly;
  public var hash_h5:HashLongestMatch;
  public var hash_h6:HashLongestMatch;
  public var hash_h7:HashLongestMatch;
  public var hash_h8:HashLongestMatch;
  public var hash_h9:HashLongestMatch;
	public function new() 
	{
		
	}
	
}
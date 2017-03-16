package encode;

/**
 * ...
 * @author 
 */
class BinaryHeap<T>
{

function HistogramPairComparator(p1:Dynamic, p2:Dynamic):Int {
    if (p1.cost_diff != p2.cost_diff) {
      return p1.cost_diff < p2.cost_diff?1:0;
    }
    return Math.abs(p1.idx1 - p1.idx2) < Math.abs(p2.idx1 - p2.idx2)?1:0;
  }
	public function new() //?comp
	{
	  //comp = comp!=null?comp:HistogramPairComparator;	
	  comp = HistogramPairComparator;
	}
  var comp:Dynamic;
  public var arr:Array<Dynamic> = [];
  
  function swap(a, b) {
    var temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
  };

  function bubbleDown(pos) {
    var left = 2 * pos + 1;
    var right = left + 1;
    var largest = pos;
    if (left < arr.length && comp(arr[left], arr[largest])>0) {
      largest = left;
    }
    if (right < arr.length && comp(arr[right], arr[largest])>0) {
      largest = right;
    }
    if (largest != pos) {
      swap(largest, pos);
      bubbleDown(largest);
    }
  };

  function bubbleUp(pos) {
    if (pos <= 0) {
      return;
    }
    var parent = Math.floor((pos - 1) / 2);
    if (comp(arr[pos], arr[parent])>0) {
      swap(pos, parent);
      bubbleUp(parent);
    }
  };
	public function pop():Dynamic {
    if (arr.length == 0) {
      //throw new Error("pop() called on emtpy binary heap");
	  return null;
    }
    var value:Dynamic = arr[0];
    var last = arr.length - 1;
    arr[0] = arr[last];
    arr.pop();// arr.length = last;
    if (last > 0) {
      bubbleDown(0);
    }
    return value;
  };

	public function push(value) {
    arr.push(value);
    bubbleUp(arr.length - 1);
  };

	public function size() {
    return arr.length;
  };	
}
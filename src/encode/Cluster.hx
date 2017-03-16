package encode;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import encode.histogram.Histogram;
import DefaultFunctions.*;
import encode.Bit_cost.*;
import encode.cluster.HistogramPair;
import encode.Fast_log.*;
import encode.BinaryHeap.*;

/**
 * ...
 * @author 
 */
class Cluster
{

public static function HistogramPairComparator(p1:HistogramPair, p2:HistogramPair) {
    if (p1.cost_diff != p2.cost_diff) {
      return p1.cost_diff > p2.cost_diff?1:-1;
    }
    return Math.abs(p1.idx1 - p1.idx2) > Math.abs(p2.idx1 - p2.idx2)?1:-1;
  }

// Returns entropy reduction of the context map when we combine two clusters.
public static function ClusterCostDiff(size_a:Int, size_b:Int):Float {// inline
  var size_c:Int = size_a + size_b;
  return size_a * FastLog2(size_a) + size_b * FastLog2(size_b) -
      size_c * FastLog2(size_c);
}

// Computes the bit cost reduction by combining out[idx1] and out[idx2] and if
// it is below a threshold, stores the pair (idx1, idx2) in the *pairs heap.
public static function CompareAndPushToHeap(out:Array<Histogram>,
                          cluster_size:Vector<Int>,
                          idx1:Int, idx2:Int,
                          pairs:BinaryHeap<HistogramPair>) {
  if (idx1 == idx2) {
    return;
  }
  if (idx2 < idx1) {
    var t:Int = idx2;
    idx2 = idx1;
    idx1 = t;
  }
  var store_pair:Bool = false;
  var p:HistogramPair=new HistogramPair();
  p.idx1 = idx1;
  p.idx2 = idx2;
  p.valid = true;
  p.cost_diff = 0.5 * ClusterCostDiff(cluster_size[idx1], cluster_size[idx2]);
  p.cost_diff -= out[idx1].bit_cost_;
  p.cost_diff -= out[idx2].bit_cost_;

  if (out[idx1].total_count_ == 0) {
    p.cost_combo = out[idx2].bit_cost_;
    store_pair = true;
  } else if (out[idx2].total_count_ == 0) {
    p.cost_combo = out[idx1].bit_cost_;
    store_pair = true;
  } else {
    var threshold:Float = pairs.size()==0 ? 1e99 :
        Math.max(0.0, pairs.arr[0].cost_diff);
    var combo:Histogram = new Histogram(out[idx1].data_.length);//HistogramType
	combo.bit_cost_ = out[idx1].bit_cost_;
	for(a in 0...out[idx1].data_.length)
	combo.data_[a] = out[idx1].data_[a];
	combo.kDataSize = out[idx1].kDataSize;
	combo.total_count_ = out[idx1].total_count_;
    combo.AddHistogram(out[idx2]);
    var cost_combo:Float = PopulationCost(combo);
    if (cost_combo < threshold - p.cost_diff) {
      p.cost_combo = cost_combo;
      store_pair = true;
    }
  }
  if (store_pair) {
    p.cost_diff += p.cost_combo;
    pairs.push(p);
	//pairs.sort(HistogramPairComparator);
    //TOPDO:std::push_heap(pairs->begin(), pairs->end(), HistogramPairComparator());
  }
}

public static function HistogramCombine(out:Array<Histogram>,
                      cluster_size:Vector<Int>,
                      symbols:Vector<Int>,
                      symbols_off:Int,
                      symbols_size:Int,
                      max_clusters:Int) {
  var cost_diff_threshold:Float = 0.0;
  var min_cluster_size:Int = 1;
  var all_symbols:Array<Int>=new Array();//TODO:std::set<int>
  var clusters:Array<Int>=new Array();
  for (i in 0...symbols_size) {
    if (all_symbols.indexOf(symbols[symbols_off+i]) == -1) {//all_symbols.end()
	  if(all_symbols.indexOf(symbols[symbols_off+i])==-1)
      all_symbols.push(symbols[symbols_off+i]);
      clusters.push(symbols[symbols_off+i]);
    }
  }

  // We maintain a heap of histogram pairs, ordered by the bit cost reduction.
  var pairs:BinaryHeap<HistogramPair>=new BinaryHeap();
  for (idx1 in 0...clusters.length) {
    for (idx2 in idx1 + 1...clusters.length) {
      CompareAndPushToHeap(out, cluster_size, clusters[idx1], clusters[idx2],
                           pairs);
    }
  }

  while (clusters.length > min_cluster_size) {
    if (pairs.arr[0].cost_diff >= cost_diff_threshold) {
      cost_diff_threshold = 1e99;
      min_cluster_size = max_clusters;
      continue;
    }
    // Take the best pair from the top of heap.
    var best_idx1:Int = pairs.arr[0].idx1;
    var best_idx2:Int = pairs.arr[0].idx2;
    out[best_idx1].AddHistogram(out[best_idx2]);
    out[best_idx1].bit_cost_ = pairs.arr[0].cost_combo;
    cluster_size[best_idx1] += cluster_size[best_idx2];
    for (i in 0...symbols_size) {
      if (symbols[symbols_off+i] == best_idx2) {
        symbols[symbols_off+i] = best_idx1;
      }
    }
    for (i in 0...clusters.length) {
      if (clusters[i] >= best_idx2) {
        clusters[i] = clusters[i + 1];
      }
    }
    clusters.pop();
    // Invalidate pairs intersecting the just combined best pair.
    for (i in 0...pairs.size()) {
      var p:HistogramPair = pairs.arr[i];
      if (p.idx1 == best_idx1 || p.idx2 == best_idx1 ||
          p.idx1 == best_idx2 || p.idx2 == best_idx2) {
        p.valid = false;
      }
    }
    // Pop invalid pairs from the top of the heap.
    while (!(pairs.size()==0) && !pairs.arr[0].valid) {
      //TODO:std::pop_heap(pairs.begin(), pairs.end(), HistogramPairComparator());
      pairs.pop();
    }
    // Push new pairs formed with the combined histogram to the heap.
    for (i in 0...clusters.length) {
      CompareAndPushToHeap(out, cluster_size, best_idx1, clusters[i], pairs);
    }
  }
}

// -----------------------------------------------------------------------------
// Histogram refinement

// What is the bit cost of moving histogram from cur_symbol to candidate.
public static function HistogramBitCostDistance(histogram:Histogram,
                                candidate:Histogram) {
  if (histogram.total_count_ == 0) {
    return 0.0;
  }
  var tmp:Histogram = new Histogram(histogram.data_.length);
  tmp.bit_cost_ = histogram.bit_cost_;
  for(a in 0...histogram.data_.length)
  tmp.data_[a] = histogram.data_[a];
  tmp.kDataSize = histogram.kDataSize;
  tmp.total_count_ = histogram.total_count_;
  tmp.AddHistogram(candidate);
  return PopulationCost(tmp) - candidate.bit_cost_;
}

// Find the best 'out' histogram for each of the 'in' histograms.
// Note: we assume that out[]->bit_cost_ is already up-to-date.
public static function HistogramRemap(input:Array<Histogram>, in_size:Int,
                    output:Array<Histogram>, symbols:Vector<Int>) {
  var all_symbols:Array<Int>=new Array();//std::set<int>
  for (i in 0...in_size) {
	  if(all_symbols.indexOf(symbols[i])==-1)
    all_symbols.push(symbols[i]);
  }
  for (i in 0...in_size) {
    var best_out:Int = i == 0 ? symbols[0] : symbols[i - 1];
    var best_bits:Float = HistogramBitCostDistance(input[i], output[best_out]);
	//var k = 0; all_symbols.begin();!=
    for (k in 0...all_symbols.length) {
      var cur_bits:Float = HistogramBitCostDistance(input[i], output[all_symbols[k]]);
      if (cur_bits < best_bits) {
        best_bits = cur_bits;
        best_out = all_symbols[k];
      }
    }
    symbols[i] = best_out;
  }

  // Recompute each out based on raw and symbols.
  //var k = 0; all_symbols.begin();!=
  for (k in 0...all_symbols.length) {
    output[all_symbols[k]].Clear();
  }
  for (i in 0...in_size) {
    output[symbols[i]].AddHistogram(input[i]);
  }
}

public static function HistogramReindex(out:Array<Histogram>,
                      symbols:Vector<Int>) {
  var tmp:Array<Histogram>=new Array();//TODO
  for(i in 0...out.length) {
	  tmp[i] = new Histogram(out[i].data_.length);
	  tmp[i].bit_cost_=out[i].bit_cost_;
	  for(a in 0...out[i].data_.length)
		tmp[i].data_[a]=out[i].data_[a];
	  tmp[i].kDataSize=out[i].kDataSize;
	  tmp[i].total_count_ = out[i].total_count_;
  }
  var new_index=new IntMap();
  var next_index:Int = 0;
  for (i in 0...symbols.length) {
    if (new_index.exists(symbols[i]) == false) {//.indexOf()-1new_index.end()
      new_index.set(symbols[i],next_index);// = 
	  out[next_index].bit_cost_=tmp[symbols[i]].bit_cost_;
	  for(a in 0...tmp[symbols[i]].data_.length)
		out[next_index].data_[a]=tmp[symbols[i]].data_[a];
	  out[next_index].kDataSize=tmp[symbols[i]].kDataSize;
	  out[next_index].total_count_ = tmp[symbols[i]].total_count_;
      ++next_index;
    }
  }
  while (out.length > next_index) out.pop();//TODO:out.resize(next_index);
  for (i in 0...symbols.length) {
    symbols[i] = new_index.get(symbols[i]);
  }
}

public static function ClusterHistograms(input:Array<Histogram>,
                       num_contexts:Int, num_blocks:Int,
                       max_histograms:Int,
                       output:Array<Histogram>,
                       outputInt:Int,
                       histogram_symbols:Vector<Int>) {
  var in_size:Int = num_contexts * num_blocks;
  var cluster_size = new Vector<Int>(in_size);
  memset(cluster_size, 0, 1, in_size);
  while (output.length > in_size) output.pop();
  for(i in 0...in_size)
  output[i]=new Histogram(outputInt);//TODO:.resize
  //TODO:histogram_symbols.resize(in_size);
  for (i in 0...in_size) {
	  for(a in 0...input[i].data_.length)
    output[i].data_[a] = input[i].data_[a];
    output[i].kDataSize = input[i].kDataSize;
    output[i].total_count_ = input[i].total_count_;
    output[i].bit_cost_ = PopulationCost(input[i]);
    histogram_symbols[i] = i;
  }

  var max_input_histograms:Int = 64;
  var i = 0;
  while (i < in_size) {
    var num_to_combine:Int = Std.int(Math.min(in_size - i, max_input_histograms));
    HistogramCombine(output, cluster_size,//,0,0
                     histogram_symbols,i, num_to_combine,
                     max_histograms);
	i += max_input_histograms;
  }

  // Collapse similar histograms.
  HistogramCombine(output, cluster_size,//,0,0
                   histogram_symbols,0, in_size,
                   max_histograms);

  // Find the optimal map from original histograms to the final ones.
  HistogramRemap(input, in_size, output, histogram_symbols);//,0,0,0

  // Convert the context map to a canonical form.
  HistogramReindex(output, histogram_symbols);
}

	public function new() 
	{
		
	}
	
}
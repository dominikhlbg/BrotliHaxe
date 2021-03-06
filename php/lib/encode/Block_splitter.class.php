<?php

// Generated by Haxe 3.4.0
class encode_Block_splitter {
	public function __construct() {}
	static $kMaxLiteralHistograms = 100;
	static $kMaxCommandHistograms = 50;
	static $kLiteralBlockSwitchCost = 28.1;
	static $kCommandBlockSwitchCost = 13.5;
	static $kDistanceBlockSwitchCost = 14.6;
	static $kLiteralStrideLength = 70;
	static $kCommandStrideLength = 40;
	static $kSymbolsPerLiteralHistogram = 544;
	static $kSymbolsPerCommandHistogram = 530;
	static $kSymbolsPerDistanceHistogram = 544;
	static $kMinLengthForBlockSplitting = 128;
	static $kIterMulForRefining = 2;
	static $kMinItersForRefining = 100;
	static function CopyLiteralsToByteArray($cmds, $num_commands, $data, $data_off, $literals) {
		$total_length = 0;
		{
			$_g1 = 0;
			while($_g1 < $num_commands) {
				$_g1 = $_g1 + 1;
				$total_length = $total_length + _hx_array_get($cmds, $_g1 - 1)->insert_len_;
			}
		}
		if($total_length === 0) {
			return;
		}
		while($literals->length > $total_length) {
			$literals->pop();
		}
		$pos = 0;
		$from_pos = 0;
		$i = 0;
		while(true) {
			$tmp = null;
			if($i < $num_commands) {
				$tmp = $pos < $total_length;
			} else {
				$tmp = false;
			}
			if(!$tmp) {
				break;
			}
			DefaultFunctions::memcpyArrayVector($literals, $pos, $data, $data_off + $from_pos, _hx_array_get($cmds, $i)->insert_len_);
			$pos = $pos + _hx_array_get($cmds, $i)->insert_len_;
			$from_pos = $from_pos + (_hx_array_get($cmds, $i)->insert_len_ + _hx_array_get($cmds, $i)->copy_len_);
			$i = $i + 1;
			unset($tmp);
		}
	}
	static function CopyCommandsToByteArray($cmds, $num_commands, $insert_and_copy_codes, $distance_prefixes) {
		$_g1 = 0;
		while($_g1 < $num_commands) {
			$_g1 = $_g1 + 1;
			$cmd = $cmds[$_g1 - 1];
			$insert_and_copy_codes->push($cmd->cmd_prefix_[0]);
			$tmp = null;
			if($cmd->copy_len_ > 0) {
				$a = $cmd->cmd_prefix_[0];
				$aNeg = $a < 0;
				if($aNeg !== false) {
					$tmp = $aNeg;
				} else {
					$tmp = $a >= 128;
				}
				unset($aNeg,$a);
			} else {
				$tmp = false;
			}
			if($tmp) {
				$distance_prefixes->push($cmd->dist_prefix_[0]);
			}
			unset($tmp,$cmd);
		}
	}
	static function MyRand($seed) {
		$seed[0] = $seed[0] * 16807;
		$seed[0] = $seed[0] & -1;
		if($seed[0] === 0) {
			$seed[0] = 1;
		}
		return $seed[0];
	}
	static function InitialEntropyCodes($HistogramTypeInt, $data, $length, $literals_per_histogram, $max_histograms, $stride, $vec) {
		$total_histograms = Std::int($length / $literals_per_histogram) + 1;
		if($total_histograms > $max_histograms) {
			$total_histograms = $max_histograms;
		}
		$seed_0 = 7;
		$block_length = Std::int($length / $total_histograms);
		{
			$_g1 = 0;
			$_g = $total_histograms;
			while($_g1 < $_g) {
				$_g1 = $_g1 + 1;
				$i = $_g1 - 1;
				$pos = Std::int($length * $i / $total_histograms);
				if($i !== 0) {
					$seed_0 = $seed_0 * 16807;
					$seed_0 = $seed_0 & -1;
					if($seed_0 === 0) {
						$seed_0 = 1;
					}
					$int = $seed_0;
					$b = null;
					if($int < 0) {
						$b = 4294967296.0 + $int;
					} else {
						$b = $int + 0.0;
					}
					$b1 = null;
					if($block_length < 0) {
						$b1 = 4294967296.0 + $block_length;
					} else {
						$b1 = $block_length + 0.0;
					}
					$pos = $pos + Std::int(_hx_mod($b, $b1));
					unset($int,$b1,$b);
				}
				if($pos + $stride >= $length) {
					$pos = $length - $stride - 1;
				}
				$histo = new encode_histogram_Histogram($HistogramTypeInt);
				$histo->Add2($data, $pos, $stride);
				$vec->push($histo);
				unset($pos,$i,$histo);
			}
		}
	}
	static function RandomSample($seed, $data, $length, $stride, $sample) {
		$pos = 0;
		if($stride >= $length) {
			$pos = 0;
			$stride = $length;
		} else {
			$seed[0] = $seed[0] * 16807;
			$seed[0] = $seed[0] & -1;
			if($seed[0] === 0) {
				$seed[0] = 1;
			}
			$int = $seed[0];
			$pos1 = null;
			if($int < 0) {
				$pos1 = 4294967296.0 + $int;
			} else {
				$pos1 = $int + 0.0;
			}
			$int1 = $length - $stride + 1;
			$pos2 = null;
			if($int1 < 0) {
				$pos2 = 4294967296.0 + $int1;
			} else {
				$pos2 = $int1 + 0.0;
			}
			$pos = Std::int(_hx_mod($pos1, $pos2));
		}
		$sample->Add2($data, $pos, $stride);
	}
	static function RefineEntropyCodes($HistogramTypeInt, $data, $length, $stride, $vec) {
		$iters = Std::int(2 * $length / $stride) + 100;
		$seed = (new _hx_array(array(7)));
		$iters1 = Std::int(($iters + $vec->length - 1) / $vec->length);
		$iters = $iters1 * $vec->length;
		{
			$_g1 = 0;
			$_g = $iters;
			while($_g1 < $_g) {
				$_g1 = $_g1 + 1;
				$sample = new encode_histogram_Histogram($HistogramTypeInt);
				encode_Block_splitter::RandomSample($seed, $data, $length, $stride, $sample);
				_hx_array_get($vec, _hx_mod(($_g1 - 1), $vec->length))->AddHistogram($sample);
				unset($sample);
			}
		}
	}
	static function BitCost($count) {
		if($count === 0) {
			return -2;
		} else {
			return encode_Fast_log::FastLog2($count);
		}
	}
	static function FindBlocks($kSize, $data, $length, $block_switch_bitcost, $vec, $block_id, $block_id_off) {
		if($vec->length <= 1) {
			{
				$_g1 = 0;
				while($_g1 < $length) {
					$_g1 = $_g1 + 1;
					$block_id[$_g1 - 1] = 0;
				}
			}
			return;
		}
		$vecsize = $vec->length;
		$insert_cost = FunctionMalloc::mallocFloat($kSize * $vecsize);
		{
			$_g11 = 0;
			while($_g11 < $vecsize) {
				$_g11 = $_g11 + 1;
				$j = $_g11 - 1;
				$insert_cost[$j] = encode_Fast_log::FastLog2(_hx_array_get($vec, $j)->total_count_);
				unset($j);
			}
		}
		$i = $kSize - 1;
		while($i >= 0) {
			{
				$_g12 = 0;
				while($_g12 < $vecsize) {
					$_g12 = $_g12 + 1;
					$j1 = $_g12 - 1;
					{
						$count = _hx_array_get($vec, $j1)->data_[$i];
						$val = null;
						if($count === 0) {
							$val = -2;
						} else {
							$val = encode_Fast_log::FastLog2($count);
						}
						$insert_cost[$i * $vecsize + $j1] = $insert_cost[$j1] - $val;
						unset($val,$count);
					}
					unset($j1);
				}
				unset($_g12);
			}
			$i = $i - 1;
		}
		$cost = FunctionMalloc::mallocFloat($vecsize);
		$switch_signal = FunctionMalloc::mallocBool($length * $vecsize);
		{
			$_g13 = 0;
			while($_g13 < $length) {
				$_g13 = $_g13 + 1;
				$byte_ix = $_g13 - 1;
				$ix = $byte_ix * $vecsize;
				$insert_cost_ix = $data[$byte_ix] * $vecsize;
				$min_cost = 1e99;
				{
					$_g3 = 0;
					while($_g3 < $vecsize) {
						$_g3 = $_g3 + 1;
						$k = $_g3 - 1;
						$cost[$k] = $cost[$k] + $insert_cost[$insert_cost_ix + $k];
						if($cost[$k] < $min_cost) {
							$min_cost = $cost[$k];
							$block_id[$byte_ix] = $k;
						}
						unset($k);
					}
					unset($_g3);
				}
				$block_switch_cost = $block_switch_bitcost;
				if($byte_ix < 2000) {
					$block_switch_cost = $block_switch_bitcost * (0.77 + 0.07 * $byte_ix / 2000);
				}
				{
					$_g31 = 0;
					while($_g31 < $vecsize) {
						$_g31 = $_g31 + 1;
						$k1 = $_g31 - 1;
						$cost[$k1] = $cost[$k1] - $min_cost;
						if($cost[$k1] >= $block_switch_cost) {
							$cost[$k1] = $block_switch_cost;
							$switch_signal[$ix + $k1] = true;
						}
						unset($k1);
					}
					unset($_g31);
				}
				unset($min_cost,$ix,$insert_cost_ix,$byte_ix,$block_switch_cost);
			}
		}
		$byte_ix1 = $length - 1;
		$ix1 = $byte_ix1 * $vecsize;
		$cur_id = $block_id[$byte_ix1];
		while($byte_ix1 > 0) {
			$byte_ix1 = $byte_ix1 - 1;
			$ix1 = $ix1 - $vecsize;
			if($switch_signal[$ix1 + $cur_id]) {
				$cur_id = $block_id[$byte_ix1];
			}
			$block_id[$byte_ix1] = $cur_id;
		}
	}
	static function RemapBlockIds($block_ids, $length) {
		$new_id = new haxe_ds_IntMap();
		$next_id = 0;
		{
			$_g1 = 0;
			while($_g1 < $length) {
				$_g1 = $_g1 + 1;
				$i = $_g1 - 1;
				if($new_id->exists($block_ids[$i]) === false) {
					$new_id->set($block_ids[$i], $next_id);
					$next_id = $next_id + 1;
				}
				unset($i);
			}
		}
		{
			$_g11 = 0;
			while($_g11 < $length) {
				$_g11 = $_g11 + 1;
				$i1 = $_g11 - 1;
				$block_ids[$i1] = $new_id->get($block_ids[$i1]);
				unset($i1);
			}
		}
		return $next_id;
	}
	static function BuildBlockHistograms($HistogramTypeInt, $data, $length, $block_ids, $block_ids_off, $histograms) {
		$num_types = encode_Block_splitter::RemapBlockIds($block_ids, $length);
		while($histograms->length > 0) {
			$histograms->pop();
		}
		{
			$_g1 = 0;
			while($_g1 < $num_types) {
				$_g1 = $_g1 + 1;
				$histograms->push(new encode_histogram_Histogram($HistogramTypeInt));
			}
		}
		{
			$_g11 = 0;
			while($_g11 < $length) {
				$_g11 = $_g11 + 1;
				$i = $_g11 - 1;
				_hx_array_get($histograms, $block_ids[$i])->Add1($data[$i]);
				unset($i);
			}
		}
	}
	static function ClusterBlocks($HistogramTypeInt, $data, $length, $block_ids) {
		$histograms = new _hx_array(array());
		$block_index = FunctionMalloc::mallocInt($length);
		$cur_idx = 0;
		$cur_histogram = new encode_histogram_Histogram($HistogramTypeInt);
		{
			$_g1 = 0;
			while($_g1 < $length) {
				$_g1 = $_g1 + 1;
				$i = $_g1 - 1;
				$block_boundary = null;
				if($i + 1 !== $length) {
					$block_boundary = $block_ids[$i] !== $block_ids[$i + 1];
				} else {
					$block_boundary = true;
				}
				$block_index[$i] = $cur_idx;
				$cur_histogram->Add1($data[$i]);
				if($block_boundary) {
					$histograms->push($cur_histogram);
					$cur_histogram = new encode_histogram_Histogram($HistogramTypeInt);
					$cur_idx = $cur_idx + 1;
				}
				unset($i,$block_boundary);
			}
		}
		$clustered_histograms = new _hx_array(array());
		$this1 = (new _hx_array(array()));
		$this1->length = $histograms->length;
		$histogram_symbols = $this1;
		encode_Cluster::ClusterHistograms($histograms, 1, $histograms->length, 256, $clustered_histograms, $HistogramTypeInt, $histogram_symbols);
		{
			$_g11 = 0;
			while($_g11 < $length) {
				$_g11 = $_g11 + 1;
				$i1 = $_g11 - 1;
				$block_ids[$i1] = $histogram_symbols[$block_index[$i1]];
				unset($i1);
			}
		}
	}
	static function BuildBlockSplit($block_ids, $split) {
		$cur_id = $block_ids[0];
		$cur_length = 1;
		$split->num_types = -1;
		{
			$_g1 = 1;
			$_g = $block_ids->length;
			while($_g1 < $_g) {
				$_g1 = $_g1 + 1;
				$i = $_g1 - 1;
				if($block_ids[$i] !== $cur_id) {
					$split->types->push($cur_id);
					$split->lengths->push($cur_length);
					$split->num_types = Std::int(Math::max($split->num_types, $cur_id));
					$cur_id = $block_ids[$i];
					$cur_length = 0;
				}
				$cur_length = $cur_length + 1;
				unset($i);
			}
		}
		$split->types->push($cur_id);
		$split->lengths->push($cur_length);
		$split->num_types = Std::int(Math::max($split->num_types, $cur_id));
		++$split->num_types;
	}
	static function SplitByteVector($HistogramTypeInt, $data, $literals_per_histogram, $max_histograms, $sampling_stride_length, $block_switch_cost, $split) {
		if($data->length === 0) {
			$split->num_types = 1;
			return;
		} else {
			if($data->length < 128) {
				$split->num_types = 1;
				$split->types->push(0);
				$split->lengths->push($data->length);
				return;
			}
		}
		$histograms = new _hx_array(array());
		encode_Block_splitter::InitialEntropyCodes($HistogramTypeInt, $data, $data->length, $literals_per_histogram, $max_histograms, $sampling_stride_length, $histograms);
		encode_Block_splitter::RefineEntropyCodes($HistogramTypeInt, $data, $data->length, $sampling_stride_length, $histograms);
		$block_ids = FunctionMalloc::mallocUInt($data->length);
		{
			$_g = 0;
			while($_g < 10) {
				$_g = $_g + 1;
				encode_Block_splitter::FindBlocks($HistogramTypeInt, $data, $data->length, $block_switch_cost, $histograms, $block_ids, 0);
				encode_Block_splitter::BuildBlockHistograms($HistogramTypeInt, $data, $data->length, $block_ids, 0, $histograms);
			}
		}
		encode_Block_splitter::ClusterBlocks($HistogramTypeInt, $data, $data->length, $block_ids);
		encode_Block_splitter::BuildBlockSplit($block_ids, $split);
	}
	static function SplitBlock($cmds, $num_commands, $data, $data_off, $literal_split, $insert_and_copy_split, $dist_split) {
		$literals = new _hx_array(array());
		encode_Block_splitter::CopyLiteralsToByteArray($cmds, $num_commands, $data, $data_off, $literals);
		$insert_and_copy_codes = new _hx_array(array());
		$distance_prefixes = new _hx_array(array());
		encode_Block_splitter::CopyCommandsToByteArray($cmds, $num_commands, $insert_and_copy_codes, $distance_prefixes);
		encode_Block_splitter::SplitByteVector(encode_Histogram_functions::$HistogramLiteralInt, $literals, 544, 100, 70, 28.1, $literal_split);
		encode_Block_splitter::SplitByteVector(encode_Histogram_functions::$HistogramCommandInt, $insert_and_copy_codes, 530, 50, 40, 13.5, $insert_and_copy_split);
		encode_Block_splitter::SplitByteVector(encode_Histogram_functions::$HistogramDistanceInt, $distance_prefixes, 544, 50, 40, 14.6, $dist_split);
	}
	function __toString() { return 'encode.Block_splitter'; }
}

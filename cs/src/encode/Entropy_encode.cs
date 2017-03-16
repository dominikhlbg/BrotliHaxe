// Generated by Haxe 3.4.0

#pragma warning disable 109, 114, 219, 429, 168, 162
namespace encode {
	public class Entropy_encode : global::haxe.lang.HxObject {
		
		static Entropy_encode() {
			unchecked {
				global::encode.Entropy_encode.kCodeLengthCodes = 18;
			}
		}
		
		
		public Entropy_encode(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public Entropy_encode() {
			global::encode.Entropy_encode.__hx_ctor_encode_Entropy_encode(this);
		}
		
		
		public static void __hx_ctor_encode_Entropy_encode(global::encode.Entropy_encode __hx_this) {
		}
		
		
		public static int kCodeLengthCodes;
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeLiteral() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (256) ));
			}
		}
		
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeCommand() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (704) ));
			}
		}
		
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeDistance() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (520) ));
			}
		}
		
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeBlockLength() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (26) ));
			}
		}
		
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeContextMap() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (272) ));
			}
		}
		
		
		public static global::encode.entropy_encode.EntropyCode EntropyCodeBlockType() {
			unchecked {
				return new global::encode.entropy_encode.EntropyCode(((int) (258) ));
			}
		}
		
		
		public static int SortHuffmanTree(global::encode.entropy_encode.HuffmanTree v0, global::encode.entropy_encode.HuffmanTree v1) {
			unchecked {
				if (( v0.total_count_ == v1.total_count_ )) {
					return ( v1.index_right_or_value_ - v0.index_right_or_value_ );
				}
				
				if (( v0.total_count_ < v1.total_count_ )) {
					return -1;
				}
				
				return 1;
			}
		}
		
		
		public static void SetDepth(global::encode.entropy_encode.HuffmanTree p, global::Array<object> pool, int pool_off, uint[] depth, int depth_off, int level) {
			if (( p.index_left_ >= 0 )) {
				 ++ level;
				global::encode.Entropy_encode.SetDepth(((global::encode.entropy_encode.HuffmanTree) (pool[( pool_off + p.index_left_ )]) ), pool, pool_off, depth, depth_off, level);
				global::encode.Entropy_encode.SetDepth(((global::encode.entropy_encode.HuffmanTree) (pool[( pool_off + p.index_right_or_value_ )]) ), pool, pool_off, depth, depth_off, level);
			}
			else {
				((uint[]) (depth) )[( depth_off + p.index_right_or_value_ )] = ((uint) (level) );
			}
			
		}
		
		
		public static void CreateHuffmanTree(int[] data, int data_off, int length, int tree_limit, uint[] depth, int depth_off) {
			unchecked {
				int count_limit = 1;
				while (true) {
					global::Array<object> tree = new global::Array<object>();
					int tree_off = 0;
					int i = ( length - 1 );
					while (( i >= 0 )) {
						if (( ((int) (((int[]) (data) )[i]) ) > 0 )) {
							int count = ((int) (global::System.Math.Max(((double) (((int) (((int[]) (data) )[i]) )) ), ((double) (count_limit) ))) );
							global::encode.entropy_encode.HuffmanTree huffmantree = new global::encode.entropy_encode.HuffmanTree();
							huffmantree.HuffmanTree3(count, -1, i);
							tree[tree_off++] = huffmantree;
						}
						
						 -- i;
					}
					
					int n = tree.length;
					if (( n == 1 )) {
						((uint[]) (depth) )[( depth_off + ((global::encode.entropy_encode.HuffmanTree) (tree[0]) ).index_right_or_value_ )] = ((uint) (1) );
						break;
					}
					
					tree.sort(((global::haxe.lang.Function) (new global::haxe.lang.Closure(typeof(global::encode.Entropy_encode), "SortHuffmanTree", 323217485)) ));
					global::encode.entropy_encode.HuffmanTree huffmantree1 = new global::encode.entropy_encode.HuffmanTree();
					huffmantree1.HuffmanTree3(2147483647, -1, -1);
					tree[tree_off++] = huffmantree1;
					global::encode.entropy_encode.HuffmanTree huffmantree2 = new global::encode.entropy_encode.HuffmanTree();
					huffmantree2.HuffmanTree3(2147483647, -1, -1);
					tree[tree_off++] = huffmantree2;
					int i1 = 0;
					int j = ( n + 1 );
					int k = ( n - 1 );
					while (( k > 0 )) {
						int left = default(int);
						int right = default(int);
						if (( ((global::encode.entropy_encode.HuffmanTree) (tree[i1]) ).total_count_ <= ((global::encode.entropy_encode.HuffmanTree) (tree[j]) ).total_count_ )) {
							left = i1;
							 ++ i1;
						}
						else {
							left = j;
							 ++ j;
						}
						
						if (( ((global::encode.entropy_encode.HuffmanTree) (tree[i1]) ).total_count_ <= ((global::encode.entropy_encode.HuffmanTree) (tree[j]) ).total_count_ )) {
							right = i1;
							 ++ i1;
						}
						else {
							right = j;
							 ++ j;
						}
						
						int j_end = ( tree.length - 1 );
						((global::encode.entropy_encode.HuffmanTree) (tree[j_end]) ).total_count_ = ( ((global::encode.entropy_encode.HuffmanTree) (tree[left]) ).total_count_ + ((global::encode.entropy_encode.HuffmanTree) (tree[right]) ).total_count_ );
						((global::encode.entropy_encode.HuffmanTree) (tree[j_end]) ).index_left_ = left;
						((global::encode.entropy_encode.HuffmanTree) (tree[j_end]) ).index_right_or_value_ = right;
						global::encode.entropy_encode.HuffmanTree huffmantree3 = new global::encode.entropy_encode.HuffmanTree();
						huffmantree3.HuffmanTree3(2147483647, -1, -1);
						tree[tree_off++] = huffmantree3;
						 -- k;
					}
					
					global::encode.Entropy_encode.SetDepth(((global::encode.entropy_encode.HuffmanTree) (tree[( ( 2 * n ) - 1 )]) ), tree, 0, depth, depth_off, 0);
					int max_element = 0;
					{
						int _g1 = depth_off;
						int _g = ( depth_off + length );
						while (( _g1 < _g )) {
							int i2 = _g1++;
							if (((bool) (( ((uint) (((uint[]) (depth) )[i2]) ) > max_element )) )) {
								max_element = ((int) (((uint) (((uint[]) (depth) )[i2]) )) );
							}
							
						}
						
					}
					
					if (( max_element <= tree_limit )) {
						break;
					}
					
					count_limit *= 2;
				}
				
			}
		}
		
		
		public static void Reverse(global::Array<uint> v, int start, int end) {
			 -- end;
			while (( start < end )) {
				int tmp = ((int) (v[start]) );
				v[start] = v[end];
				v[end] = ((uint) (tmp) );
				 ++ start;
				 -- end;
			}
			
		}
		
		
		public static void WriteHuffmanTreeRepetitions(int previous_value, int @value, int repetitions, global::Array<uint> tree, global::Array<uint> extra_bits_data) {
			unchecked {
				if (( previous_value != @value )) {
					tree.push(((uint) (@value) ));
					extra_bits_data.push(((uint) (0) ));
					 -- repetitions;
				}
				
				if (( repetitions == 7 )) {
					tree.push(((uint) (@value) ));
					extra_bits_data.push(((uint) (0) ));
					 -- repetitions;
				}
				
				if (( repetitions < 3 )) {
					int _g1 = 0;
					int _g = repetitions;
					while (( _g1 < _g )) {
						 ++ _g1;
						tree.push(((uint) (@value) ));
						extra_bits_data.push(((uint) (0) ));
					}
					
				}
				else {
					repetitions -= 3;
					int start = tree.length;
					while (( repetitions >= 0 )) {
						tree.push(((uint) (16) ));
						extra_bits_data.push(((uint) (( repetitions & 3 )) ));
						repetitions >>= 2;
						 -- repetitions;
					}
					
					global::encode.Entropy_encode.Reverse(tree, start, tree.length);
					global::encode.Entropy_encode.Reverse(extra_bits_data, start, tree.length);
				}
				
			}
		}
		
		
		public static void WriteHuffmanTreeRepetitionsZeros(int repetitions, global::Array<uint> tree, global::Array<uint> extra_bits_data) {
			unchecked {
				if (( repetitions == 11 )) {
					tree.push(((uint) (0) ));
					extra_bits_data.push(((uint) (0) ));
					 -- repetitions;
				}
				
				if (( repetitions < 3 )) {
					int _g1 = 0;
					int _g = repetitions;
					while (( _g1 < _g )) {
						 ++ _g1;
						tree.push(((uint) (0) ));
						extra_bits_data.push(((uint) (0) ));
					}
					
				}
				else {
					repetitions -= 3;
					int start = tree.length;
					while (( repetitions >= 0 )) {
						tree.push(((uint) (17) ));
						extra_bits_data.push(((uint) (( repetitions & 7 )) ));
						repetitions >>= 3;
						 -- repetitions;
					}
					
					global::encode.Entropy_encode.Reverse(tree, start, tree.length);
					global::encode.Entropy_encode.Reverse(extra_bits_data, start, tree.length);
				}
				
			}
		}
		
		
		public static int OptimizeHuffmanCountsForRle(int length, int[] counts) {
			unchecked {
				int nonzero_count = 0;
				int stride = default(int);
				int limit = default(int);
				int sum = default(int);
				uint[] good_for_rle = null;
				{
					int _g1 = 0;
					int _g = length;
					while (( _g1 < _g )) {
						if (( ((int) (((int[]) (counts) )[_g1++]) ) > 0 )) {
							 ++ nonzero_count;
						}
						
					}
					
				}
				
				if (( nonzero_count < 16 )) {
					return 1;
				}
				
				while (( length >= 0 )) {
					if (( length == 0 )) {
						return 1;
					}
					
					if (( ((int) (((int[]) (counts) )[( length - 1 )]) ) != 0 )) {
						break;
					}
					
					 -- length;
				}
				
				{
					int nonzeros = 0;
					int smallest_nonzero = 1073741824;
					{
						int _g11 = 0;
						int _g2 = length;
						while (( _g11 < _g2 )) {
							int i = _g11++;
							if (( ((int) (((int[]) (counts) )[i]) ) != 0 )) {
								 ++ nonzeros;
								if (( smallest_nonzero > ((int) (((int[]) (counts) )[i]) ) )) {
									smallest_nonzero = ((int) (((int[]) (counts) )[i]) );
								}
								
							}
							
						}
						
					}
					
					if (( nonzeros < 5 )) {
						return 1;
					}
					
					if (( smallest_nonzero < 4 )) {
						if (( ( length - nonzeros ) < 6 )) {
							int _g12 = 1;
							int _g3 = ( length - 1 );
							while (( _g12 < _g3 )) {
								int i1 = _g12++;
								if (( ( ( ((int) (((int[]) (counts) )[( i1 - 1 )]) ) != 0 ) && ( ((int) (((int[]) (counts) )[i1]) ) == 0 ) ) && ( ((int) (((int[]) (counts) )[( i1 + 1 )]) ) != 0 ) )) {
									((int[]) (counts) )[i1] = 1;
								}
								
							}
							
						}
						
					}
					
					if (( nonzeros < 28 )) {
						return 1;
					}
					
				}
				
				good_for_rle = global::FunctionMalloc.mallocUInt(length);
				if (( good_for_rle == null )) {
					return 0;
				}
				
				{
					int symbol = ((int) (((int[]) (counts) )[0]) );
					int stride1 = 0;
					{
						int _g13 = 0;
						int _g4 = ( length + 1 );
						while (( _g13 < _g4 )) {
							int i2 = _g13++;
							if (( ( i2 == length ) || ( ((int) (((int[]) (counts) )[i2]) ) != symbol ) )) {
								if (( ( ( symbol == 0 ) && ( stride1 >= 5 ) ) || ( ( symbol != 0 ) && ( stride1 >= 7 ) ) )) {
									int _g31 = 0;
									int _g21 = stride1;
									while (( _g31 < _g21 )) {
										((uint[]) (good_for_rle) )[( ( i2 - _g31++ ) - 1 )] = ((uint) (1) );
									}
									
								}
								
								stride1 = 1;
								if (( i2 != length )) {
									symbol = ((int) (((int[]) (counts) )[i2]) );
								}
								
							}
							else {
								 ++ stride1;
							}
							
						}
						
					}
					
				}
				
				stride = 0;
				limit = ( ( ( 256 * (( ( ((int) (((int[]) (counts) )[0]) ) + ((int) (((int[]) (counts) )[1]) ) ) + ((int) (((int[]) (counts) )[2]) ) )) ) / 3 ) + 420 );
				sum = 0;
				{
					int _g14 = 0;
					int _g5 = ( length + 1 );
					while (( _g14 < _g5 )) {
						int i3 = _g14++;
						if (( ( ( ( i3 == length ) || ((bool) (( ((uint) (((uint[]) (good_for_rle) )[i3]) ) > 0 )) ) ) || ( ( i3 != 0 ) && ((bool) (( ((uint) (((uint[]) (good_for_rle) )[( i3 - 1 )]) ) > 0 )) ) ) ) || ( global::System.Math.Abs(((double) (( ( 256 * ((int) (((int[]) (counts) )[i3]) ) ) - limit )) )) >= 1240 ) )) {
							if (( ( stride >= 4 ) || ( ( stride >= 3 ) && ( sum == 0 ) ) )) {
								int count = ( (( sum + ( stride / 2 ) )) / stride );
								if (( count < 1 )) {
									count = 1;
								}
								
								if (( sum == 0 )) {
									count = 0;
								}
								
								{
									int _g32 = 0;
									int _g22 = stride;
									while (( _g32 < _g22 )) {
										((int[]) (counts) )[( ( i3 - _g32++ ) - 1 )] = count;
									}
									
								}
								
							}
							
							stride = 0;
							sum = 0;
							if (( i3 < ( length - 2 ) )) {
								limit = ( ( ( 256 * (( ( ((int) (((int[]) (counts) )[i3]) ) + ((int) (((int[]) (counts) )[( i3 + 1 )]) ) ) + ((int) (((int[]) (counts) )[( i3 + 2 )]) ) )) ) / 3 ) + 420 );
							}
							else if (( i3 < length )) {
								limit = ( 256 * ((int) (((int[]) (counts) )[i3]) ) );
							}
							else {
								limit = 0;
							}
							
						}
						
						 ++ stride;
						if (( i3 != length )) {
							sum += ((int) (((int[]) (counts) )[i3]) );
							if (( stride >= 4 )) {
								limit = ( (( ( 256 * sum ) + ( stride / 2 ) )) / stride );
							}
							
							if (( stride == 4 )) {
								limit += 120;
							}
							
						}
						
					}
					
				}
				
				return 1;
			}
		}
		
		
		public static void DecideOverRleUse(uint[] depth, int depth_off, int length, global::Array<bool> use_rle_for_non_zero, global::Array<bool> use_rle_for_zero) {
			unchecked {
				int total_reps_zero = 0;
				int total_reps_non_zero = 0;
				int count_reps_zero = 0;
				int count_reps_non_zero = 0;
				int i = 0;
				while (( i < length )) {
					int @value = ((int) (((uint) (((uint[]) (depth) )[( depth_off + i )]) )) );
					int reps = 1;
					int k = ( i + 1 );
					while (( ( k < length ) && ((bool) (( ((uint) (((uint[]) (depth) )[( depth_off + k )]) ) == @value )) ) )) {
						 ++ reps;
						 ++ k;
					}
					
					if (( ( reps >= 3 ) && ( @value == 0 ) )) {
						total_reps_zero += reps;
						 ++ count_reps_zero;
					}
					
					if (( ( reps >= 4 ) && ( @value != 0 ) )) {
						total_reps_non_zero += reps;
						 ++ count_reps_non_zero;
					}
					
					i += reps;
				}
				
				total_reps_non_zero -= ( count_reps_non_zero * 2 );
				total_reps_zero -= ( count_reps_zero * 2 );
				use_rle_for_non_zero[0] = ( total_reps_non_zero > 2 );
				use_rle_for_zero[0] = ( total_reps_zero > 2 );
			}
		}
		
		
		public static void WriteHuffmanTree(uint[] depth, int depth_off, uint length, global::Array<uint> tree, global::Array<uint> extra_bits_data) {
			unchecked {
				int previous_value = 8;
				int new_length = ((int) (length) );
				{
					int _g1 = 0;
					int _g = ((int) (length) );
					while (( _g1 < _g )) {
						if (((bool) (( ((uint) (((uint[]) (depth) )[((int) (((uint) (( ((uint) (( ((uint) (( length + depth_off )) ) - _g1++ )) ) - 1 )) )) )]) ) == 0 )) )) {
							 -- new_length;
						}
						else {
							break;
						}
						
					}
					
				}
				
				global::Array<bool> use_rle_for_non_zero = new global::Array<bool>(new bool[]{false});
				global::Array<bool> use_rle_for_zero = new global::Array<bool>(new bool[]{false});
				if (((bool) (( length > 50 )) )) {
					global::encode.Entropy_encode.DecideOverRleUse(depth, depth_off, new_length, use_rle_for_non_zero, use_rle_for_zero);
				}
				
				int i = 0;
				while (( i < new_length )) {
					int @value = ((int) (((uint) (((uint[]) (depth) )[( depth_off + i )]) )) );
					int reps = 1;
					if (( ( ( @value != 0 ) && use_rle_for_non_zero[0] ) || ( ( @value == 0 ) && use_rle_for_zero[0] ) )) {
						int k = ( i + 1 );
						while (( ( k < new_length ) && ((bool) (( ((uint) (((uint[]) (depth) )[( depth_off + k )]) ) == @value )) ) )) {
							 ++ reps;
							 ++ k;
						}
						
					}
					
					if (( @value == 0 )) {
						global::encode.Entropy_encode.WriteHuffmanTreeRepetitionsZeros(reps, tree, extra_bits_data);
					}
					else {
						global::encode.Entropy_encode.WriteHuffmanTreeRepetitions(previous_value, @value, reps, tree, extra_bits_data);
						previous_value = @value;
					}
					
					i += reps;
				}
				
			}
		}
		
		
		public static uint ReverseBits(int num_bits, uint bits) {
			unchecked {
				global::Array<int> kLut = new global::Array<int>(new int[]{0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15});
				int retval = kLut[((int) (((uint) (( bits & 15 )) )) )];
				int i = 4;
				while (( i < num_bits )) {
					retval <<= 4;
					bits = ((uint) (((uint) (( ((uint) (bits) ) >> 4 )) )) );
					retval |= kLut[((int) (((uint) (( bits & 15 )) )) )];
					i += 4;
				}
				
				retval >>= (  - (num_bits)  & 3 );
				return ((uint) (retval) );
			}
		}
		
		
		public static void ConvertBitDepthsToSymbols(uint[] depth, int depth_off, int len, uint[] bits, int bits_off) {
			unchecked {
				uint[] bl_count = global::FunctionMalloc.mallocUInt(16);
				{
					{
						int _g1 = 0;
						while (( _g1 < len )) {
							uint _g2 = ((uint) (((uint[]) (depth) )[( depth_off + _g1++ )]) );
							((uint[]) (bl_count) )[((int) (_g2) )] = ((uint) (( ((uint) (((uint[]) (bl_count) )[((int) (_g2) )]) ) + 1 )) );
						}
						
					}
					
					((uint[]) (bl_count) )[0] = ((uint) (0) );
				}
				
				uint[] next_code = ((uint[]) (new uint[16]) );
				((uint[]) (next_code) )[0] = ((uint) (0) );
				{
					int code = 0;
					{
						int _g11 = 1;
						while (( _g11 < 16 )) {
							int _bits = _g11++;
							code = ((int) (((uint) (( ((uint) (( ((uint) (((uint[]) (bl_count) )[( _bits - 1 )]) ) + code )) ) << 1 )) )) );
							((uint[]) (next_code) )[_bits] = ((uint) (code) );
						}
						
					}
					
				}
				
				{
					int _g12 = 0;
					while (( _g12 < len )) {
						int i = _g12++;
						if (((bool) (( ((uint) (((uint[]) (depth) )[( depth_off + i )]) ) > 0 )) )) {
							((uint[]) (bits) )[( bits_off + i )] = global::encode.Entropy_encode.ReverseBits(((int) (((uint) (((uint[]) (depth) )[( depth_off + i )]) )) ), ((uint) (((uint[]) (next_code) )[((int) (((uint) (((uint[]) (depth) )[( depth_off + i )]) )) )]) ));
							{
								uint _g21 = ((uint) (((uint[]) (depth) )[( depth_off + i )]) );
								((uint[]) (next_code) )[((int) (_g21) )] = ((uint) (( ((uint) (((uint[]) (next_code) )[((int) (_g21) )]) ) + 1 )) );
							}
							
						}
						
					}
					
				}
				
			}
		}
		
		
	}
}


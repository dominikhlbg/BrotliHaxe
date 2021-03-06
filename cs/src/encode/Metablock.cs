// Generated by Haxe 3.4.0

#pragma warning disable 109, 114, 219, 429, 168, 162
namespace encode {
	public class Metablock : global::haxe.lang.HxObject {
		
		public Metablock(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public Metablock() {
			global::encode.Metablock.__hx_ctor_encode_Metablock(this);
		}
		
		
		public static void __hx_ctor_encode_Metablock(global::encode.Metablock __hx_this) {
		}
		
		
		public static void BuildMetaBlock(uint[] ringbuffer, int pos, int mask, uint prev_byte, uint prev_byte2, global::Array<object> cmds, int num_commands, int literal_context_mode, global::encode.metablock.MetaBlockSplit mb) {
			unchecked {
				global::encode.Block_splitter.SplitBlock(cmds, num_commands, ringbuffer, ( pos & mask ), mb.literal_split, mb.command_split, mb.distance_split);
				global::Array<int> literal_context_modes = new global::Array<int>();
				{
					int _g1 = 0;
					int _g = mb.literal_split.num_types;
					while (( _g1 < _g )) {
						literal_context_modes[_g1++] = literal_context_mode;
					}
					
				}
				
				int num_literal_contexts = ( mb.literal_split.num_types << 6 );
				int num_distance_contexts = ( mb.distance_split.num_types << 2 );
				global::Array<object> literal_histograms = new global::Array<object>();
				{
					int _g11 = 0;
					while (( _g11 < num_literal_contexts )) {
						 ++ _g11;
						literal_histograms.push(new global::encode.histogram.Histogram(((int) (global::encode.Histogram_functions.HistogramLiteralInt) )));
					}
					
				}
				
				mb.command_histograms = new global::Array<object>(new object[]{});
				{
					int _g12 = 0;
					int _g2 = mb.command_split.num_types;
					while (( _g12 < _g2 )) {
						 ++ _g12;
						mb.command_histograms.push(new global::encode.histogram.Histogram(((int) (global::encode.Histogram_functions.HistogramCommandInt) )));
					}
					
				}
				
				global::Array<object> distance_histograms = new global::Array<object>();
				{
					int _g13 = 0;
					while (( _g13 < num_distance_contexts )) {
						 ++ _g13;
						distance_histograms.push(new global::encode.histogram.Histogram(((int) (global::encode.Histogram_functions.HistogramDistanceInt) )));
					}
					
				}
				
				global::encode.Histogram_functions.BuildHistograms(cmds, num_commands, mb.literal_split, mb.command_split, mb.distance_split, ringbuffer, pos, mask, prev_byte, prev_byte2, literal_context_modes, literal_histograms, mb.command_histograms, distance_histograms);
				{
					int _g14 = 0;
					int _g3 = literal_histograms.length;
					while (( _g14 < _g3 )) {
						int i = _g14++;
						mb.literal_histograms[i] = new global::encode.histogram.Histogram(((int) (global::encode.Histogram_functions.HistogramLiteralInt) ));
						((global::encode.histogram.Histogram) (mb.literal_histograms[i]) ).bit_cost_ = ((global::encode.histogram.Histogram) (literal_histograms[i]) ).bit_cost_;
						{
							int _g31 = 0;
							int _g21 = ( ((int[]) (((global::encode.histogram.Histogram) (literal_histograms[i]) ).data_) ) as global::System.Array ).Length;
							while (( _g31 < _g21 )) {
								int a = _g31++;
								((int[]) (((global::encode.histogram.Histogram) (mb.literal_histograms[i]) ).data_) )[a] = ((int[]) (((global::encode.histogram.Histogram) (literal_histograms[i]) ).data_) )[a];
							}
							
						}
						
						((global::encode.histogram.Histogram) (mb.literal_histograms[i]) ).kDataSize = ((global::encode.histogram.Histogram) (literal_histograms[i]) ).kDataSize;
						((global::encode.histogram.Histogram) (mb.literal_histograms[i]) ).total_count_ = ((global::encode.histogram.Histogram) (literal_histograms[i]) ).total_count_;
					}
					
				}
				
				mb.literal_context_map = ((int[]) (new int[( 64 * mb.literal_split.num_types )]) );
				global::encode.Cluster.ClusterHistograms(literal_histograms, 64, mb.literal_split.num_types, 256, mb.literal_histograms, global::encode.Histogram_functions.HistogramLiteralInt, mb.literal_context_map);
				{
					int _g15 = 0;
					int _g4 = distance_histograms.length;
					while (( _g15 < _g4 )) {
						int i1 = _g15++;
						mb.distance_histograms[i1] = new global::encode.histogram.Histogram(((int) (global::encode.Histogram_functions.HistogramDistanceInt) ));
						((global::encode.histogram.Histogram) (mb.distance_histograms[i1]) ).bit_cost_ = ((global::encode.histogram.Histogram) (distance_histograms[i1]) ).bit_cost_;
						{
							int _g32 = 0;
							int _g22 = ( ((int[]) (((global::encode.histogram.Histogram) (distance_histograms[i1]) ).data_) ) as global::System.Array ).Length;
							while (( _g32 < _g22 )) {
								int a1 = _g32++;
								((int[]) (((global::encode.histogram.Histogram) (mb.distance_histograms[i1]) ).data_) )[a1] = ((int[]) (((global::encode.histogram.Histogram) (distance_histograms[i1]) ).data_) )[a1];
							}
							
						}
						
						((global::encode.histogram.Histogram) (mb.distance_histograms[i1]) ).kDataSize = ((global::encode.histogram.Histogram) (distance_histograms[i1]) ).kDataSize;
						((global::encode.histogram.Histogram) (mb.distance_histograms[i1]) ).total_count_ = ((global::encode.histogram.Histogram) (distance_histograms[i1]) ).total_count_;
					}
					
				}
				
				mb.distance_context_map = ((int[]) (new int[( 4 * mb.distance_split.num_types )]) );
				global::encode.Cluster.ClusterHistograms(distance_histograms, 4, mb.distance_split.num_types, 256, mb.distance_histograms, global::encode.Histogram_functions.HistogramDistanceInt, mb.distance_context_map);
			}
		}
		
		
		public static void BuildMetaBlockGreedy(uint[] ringbuffer, int pos, int mask, global::Array<object> commands, int n_commands, global::encode.metablock.MetaBlockSplit mb) {
			unchecked {
				int num_literals = 0;
				{
					int _g1 = 0;
					while (( _g1 < n_commands )) {
						num_literals += ((global::encode.command.Command) (commands[_g1++]) ).insert_len_;
					}
					
				}
				
				global::encode.metablock.BlockSplitter lit_blocks = new global::encode.metablock.BlockSplitter(global::encode.Histogram_functions.HistogramLiteralInt, 256, 512, 400.0, num_literals, mb.literal_split, mb.literal_histograms);
				global::encode.metablock.BlockSplitter cmd_blocks = new global::encode.metablock.BlockSplitter(global::encode.Histogram_functions.HistogramCommandInt, 704, 1024, 500.0, n_commands, mb.command_split, mb.command_histograms);
				global::encode.metablock.BlockSplitter dist_blocks = new global::encode.metablock.BlockSplitter(global::encode.Histogram_functions.HistogramDistanceInt, 64, 512, 100.0, n_commands, mb.distance_split, mb.distance_histograms);
				{
					int _g11 = 0;
					while (( _g11 < n_commands )) {
						global::encode.command.Command cmd = ((global::encode.command.Command) (commands[_g11++]) );
						cmd_blocks.AddSymbol(((int) (cmd.cmd_prefix_[0]) ));
						{
							int _g3 = 0;
							int _g2 = cmd.insert_len_;
							while (( _g3 < _g2 )) {
								 ++ _g3;
								lit_blocks.AddSymbol(((int) (((uint) (((uint[]) (ringbuffer) )[( pos & mask )]) )) ));
								 ++ pos;
							}
							
						}
						
						pos += cmd.copy_len_;
						if (( ( cmd.copy_len_ > 0 ) && ((bool) (( cmd.cmd_prefix_[0] >= 128 )) ) )) {
							dist_blocks.AddSymbol(((int) (cmd.dist_prefix_[0]) ));
						}
						
					}
					
				}
				
				lit_blocks.FinishBlock(true);
				cmd_blocks.FinishBlock(true);
				dist_blocks.FinishBlock(true);
			}
		}
		
		
		public static void BuildMetaBlockGreedyWithContexts(uint[] ringbuffer, int pos, int mask, uint prev_byte, uint prev_byte2, int literal_context_mode, int num_contexts, global::Array<int> static_context_map, global::Array<object> commands, int n_commands, global::encode.metablock.MetaBlockSplit mb) {
			unchecked {
				int num_literals = 0;
				{
					int _g1 = 0;
					while (( _g1 < n_commands )) {
						num_literals += ((global::encode.command.Command) (commands[_g1++]) ).insert_len_;
					}
					
				}
				
				global::encode.metablock.ContextBlockSplitter lit_blocks = new global::encode.metablock.ContextBlockSplitter(global::encode.Histogram_functions.HistogramLiteralInt, 256, num_contexts, 512, 400.0, num_literals, mb.literal_split, mb.literal_histograms);
				global::encode.metablock.BlockSplitter cmd_blocks = new global::encode.metablock.BlockSplitter(global::encode.Histogram_functions.HistogramCommandInt, 704, 1024, 500.0, n_commands, mb.command_split, mb.command_histograms);
				global::encode.metablock.BlockSplitter dist_blocks = new global::encode.metablock.BlockSplitter(global::encode.Histogram_functions.HistogramDistanceInt, 64, 512, 100.0, n_commands, mb.distance_split, mb.distance_histograms);
				{
					int _g11 = 0;
					while (( _g11 < n_commands )) {
						global::encode.command.Command cmd = ((global::encode.command.Command) (commands[_g11++]) );
						cmd_blocks.AddSymbol(((int) (cmd.cmd_prefix_[0]) ));
						{
							int _g3 = 0;
							int _g2 = cmd.insert_len_;
							while (( _g3 < _g2 )) {
								 ++ _g3;
								uint literal = ((uint) (((uint[]) (ringbuffer) )[( pos & mask )]) );
								lit_blocks.AddSymbol(((int) (literal) ), static_context_map[((int) (global::encode.Context.ContextFunction(prev_byte, prev_byte2, literal_context_mode)) )]);
								prev_byte2 = prev_byte;
								prev_byte = literal;
								 ++ pos;
							}
							
						}
						
						pos += cmd.copy_len_;
						if (( cmd.copy_len_ > 0 )) {
							prev_byte2 = ((uint) (((uint[]) (ringbuffer) )[( ( pos - 2 ) & mask )]) );
							prev_byte = ((uint) (((uint[]) (ringbuffer) )[( ( pos - 1 ) & mask )]) );
							if (( ((int) (cmd.cmd_prefix_[0]) ) >= 128 )) {
								dist_blocks.AddSymbol(((int) (cmd.dist_prefix_[0]) ));
							}
							
						}
						
					}
					
				}
				
				lit_blocks.FinishBlock(true);
				cmd_blocks.FinishBlock(true);
				dist_blocks.FinishBlock(true);
				mb.literal_context_map = global::FunctionMalloc.mallocInt(( mb.literal_split.num_types << 6 ));
				{
					int _g12 = 0;
					int _g = mb.literal_split.num_types;
					while (( _g12 < _g )) {
						int i = _g12++;
						{
							int _g31 = 0;
							while (( _g31 < 64 )) {
								int j = _g31++;
								((int[]) (mb.literal_context_map) )[( (( i << 6 )) + j )] = ( ( i * num_contexts ) + static_context_map[j] );
							}
							
						}
						
					}
					
				}
				
			}
		}
		
		
		public static void OptimizeHistograms(int num_direct_distance_codes, int distance_postfix_bits, global::encode.metablock.MetaBlockSplit mb) {
			unchecked {
				{
					int _g1 = 0;
					int _g = mb.literal_histograms.length;
					while (( _g1 < _g )) {
						global::encode.Entropy_encode.OptimizeHuffmanCountsForRle(256, ((global::encode.histogram.Histogram) (mb.literal_histograms[_g1++]) ).data_);
					}
					
				}
				
				{
					int _g11 = 0;
					int _g2 = mb.command_histograms.length;
					while (( _g11 < _g2 )) {
						global::encode.Entropy_encode.OptimizeHuffmanCountsForRle(704, ((global::encode.histogram.Histogram) (mb.command_histograms[_g11++]) ).data_);
					}
					
				}
				
				int num_distance_codes = ( ( 16 + num_direct_distance_codes ) + (( 48 << distance_postfix_bits )) );
				{
					int _g12 = 0;
					int _g3 = mb.distance_histograms.length;
					while (( _g12 < _g3 )) {
						global::encode.Entropy_encode.OptimizeHuffmanCountsForRle(num_distance_codes, ((global::encode.histogram.Histogram) (mb.distance_histograms[_g12++]) ).data_);
					}
					
				}
				
			}
		}
		
		
	}
}



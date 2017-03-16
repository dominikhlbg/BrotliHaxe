package decode.bit_reader;
import haxe.ds.Vector;
import decode.streams.BrotliInput;
import decode.BitReader.BROTLI_IBUF_SIZE;

/**
 * ...
 * @author 
 */
class BrotliBitReader
{
	public var val_:UInt;//uint32_t          /* pre-fetched bits */
	public var pos_:UInt; //uint32_t         /* byte position in stream */
	public var bit_pos_:UInt;//uint32_t      /* current bit-reading position in val_ */
	public var bit_end_pos_:UInt;//uint32_t  /* bit-reading end position from LSB of val_ */
	public var eos_:Int;          /* input stream is finished */
	public var buf_ptr_:Vector<UInt>;//uint8_t*      /* next input will write here */
	public var buf_ptr_off:Int;//
	public var input_:BrotliInput;        /* input callback */

	/* Set to 0 to support partial data streaming. Set to 1 to expect full data or
	 for the last chunk of partial data. */
	public var finish_:Int;
	/* indicates how much bytes already read when reading partial data */
	public var tmp_bytes_read_:Int;

	/* Input byte buffer, consist of a ringbuffer and a "slack" region where */
	/* bytes from the start of the ringbuffer are copied. */
	public var buf_:Vector<UInt>=new Vector<UInt>(BROTLI_IBUF_SIZE);//uint8_t;
	public var buf_off:Int=0;//
	
	public function new() 
	{
		
	}
	
}
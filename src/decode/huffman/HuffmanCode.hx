package decode.huffman;

/**
 * ...
 * @author 
 */
class HuffmanCode
{

	public var bits:UInt;//uint8_t     /* number of bits used for this symbol */
	public var value:UInt;//uint16_t   /* symbol value or table offset */
	public function new(bits,value) 
	{
		this.bits = bits;
		this.value = value;
	}
	
}
// Generated by Haxe 3.4.0

#pragma warning disable 109, 114, 219, 429, 168, 162
namespace decode.transform {
	public class Transform : global::haxe.lang.HxObject {
		
		public Transform(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public Transform(string prefix, int transform, string suffix) {
			global::decode.transform.Transform.__hx_ctor_decode_transform_Transform(this, prefix, transform, suffix);
		}
		
		
		public static void __hx_ctor_decode_transform_Transform(global::decode.transform.Transform __hx_this, string prefix, int transform, string suffix) {
			__hx_this.prefix = new global::Array<uint>();
			{
				int _g1 = 0;
				int _g = prefix.Length;
				while (( _g1 < _g )) {
					int i = _g1++;
					__hx_this.prefix[i] = ((uint) ((global::haxe.lang.StringExt.charCodeAt(prefix, i)).@value) );
				}
				
			}
			
			__hx_this.transform = transform;
			__hx_this.suffix = new global::Array<uint>();
			{
				int _g11 = 0;
				int _g2 = suffix.Length;
				while (( _g11 < _g2 )) {
					int i1 = _g11++;
					__hx_this.suffix[i1] = ((uint) ((global::haxe.lang.StringExt.charCodeAt(suffix, i1)).@value) );
				}
				
			}
			
		}
		
		
		public global::Array<uint> prefix;
		
		public int transform;
		
		public global::Array<uint> suffix;
		
		public override double __hx_setField_f(string field, int hash, double @value, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 1167273324:
					{
						this.transform = ((int) (@value) );
						return @value;
					}
					
					
					default:
					{
						return base.__hx_setField_f(field, hash, @value, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override object __hx_setField(string field, int hash, object @value, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 480633553:
					{
						this.suffix = ((global::Array<uint>) (global::Array<object>.__hx_cast<uint>(((global::Array) (@value) ))) );
						return @value;
					}
					
					
					case 1167273324:
					{
						this.transform = ((int) (global::haxe.lang.Runtime.toInt(@value)) );
						return @value;
					}
					
					
					case 783735186:
					{
						this.prefix = ((global::Array<uint>) (global::Array<object>.__hx_cast<uint>(((global::Array) (@value) ))) );
						return @value;
					}
					
					
					default:
					{
						return base.__hx_setField(field, hash, @value, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override object __hx_getField(string field, int hash, bool throwErrors, bool isCheck, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 480633553:
					{
						return this.suffix;
					}
					
					
					case 1167273324:
					{
						return this.transform;
					}
					
					
					case 783735186:
					{
						return this.prefix;
					}
					
					
					default:
					{
						return base.__hx_getField(field, hash, throwErrors, isCheck, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override double __hx_getField_f(string field, int hash, bool throwErrors, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 1167273324:
					{
						return ((double) (this.transform) );
					}
					
					
					default:
					{
						return base.__hx_getField_f(field, hash, throwErrors, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override void __hx_getFields(global::Array<object> baseArr) {
			baseArr.push("suffix");
			baseArr.push("transform");
			baseArr.push("prefix");
			base.__hx_getFields(baseArr);
		}
		
		
	}
}



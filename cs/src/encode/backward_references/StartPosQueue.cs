// Generated by Haxe 3.4.0

#pragma warning disable 109, 114, 219, 429, 168, 162
namespace encode.backward_references {
	public class Pair : global::haxe.lang.HxObject {
		
		public Pair(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public Pair(int first, double second) {
			global::encode.backward_references.Pair.__hx_ctor_encode_backward_references_Pair(this, first, second);
		}
		
		
		public static void __hx_ctor_encode_backward_references_Pair(global::encode.backward_references.Pair __hx_this, int first, double second) {
			__hx_this.first = first;
			__hx_this.second = second;
		}
		
		
		public int first;
		
		public double second;
		
		public override double __hx_setField_f(string field, int hash, double @value, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 1682427764:
					{
						this.second = ((double) (@value) );
						return @value;
					}
					
					
					case 10319920:
					{
						this.first = ((int) (@value) );
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
					case 1682427764:
					{
						this.second = ((double) (global::haxe.lang.Runtime.toDouble(@value)) );
						return @value;
					}
					
					
					case 10319920:
					{
						this.first = ((int) (global::haxe.lang.Runtime.toInt(@value)) );
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
					case 1682427764:
					{
						return this.second;
					}
					
					
					case 10319920:
					{
						return this.first;
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
					case 1682427764:
					{
						return this.second;
					}
					
					
					case 10319920:
					{
						return ((double) (this.first) );
					}
					
					
					default:
					{
						return base.__hx_getField_f(field, hash, throwErrors, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override void __hx_getFields(global::Array<object> baseArr) {
			baseArr.push("second");
			baseArr.push("first");
			base.__hx_getFields(baseArr);
		}
		
		
	}
}



#pragma warning disable 109, 114, 219, 429, 168, 162
namespace encode.backward_references {
	public class StartPosQueue : global::haxe.lang.HxObject {
		
		public StartPosQueue(global::haxe.lang.EmptyObject empty) {
		}
		
		
		public StartPosQueue(int bits) {
			global::encode.backward_references.StartPosQueue.__hx_ctor_encode_backward_references_StartPosQueue(this, bits);
		}
		
		
		public static void __hx_ctor_encode_backward_references_StartPosQueue(global::encode.backward_references.StartPosQueue __hx_this, int bits) {
			unchecked {
				__hx_this.mask_ = ( (( 1 << bits )) - 1 );
				__hx_this.q_ = global::FunctionMalloc.malloc2__encode_backward_references_Pair(typeof(global::encode.backward_references.Pair), ( 1 << bits ));
				__hx_this.idx_ = 0;
			}
		}
		
		
		public virtual void Clear() {
			this.idx_ = 0;
		}
		
		
		public virtual void Push(int pos, double costdiff) {
			unchecked {
				((global::encode.backward_references.Pair[]) (this.q_) )[( this.idx_ & this.mask_ )] = new global::encode.backward_references.Pair(pos, costdiff);
				int i = this.idx_;
				while (( ( i > 0 ) && ( i > ( this.idx_ - this.mask_ ) ) )) {
					if (( ((global::encode.backward_references.Pair[]) (this.q_) )[( i & this.mask_ )].second > ((global::encode.backward_references.Pair[]) (this.q_) )[( ( i - 1 ) & this.mask_ )].second )) {
						int t1 = ((global::encode.backward_references.Pair[]) (this.q_) )[( i & this.mask_ )].first;
						double t2 = ((global::encode.backward_references.Pair[]) (this.q_) )[( i & this.mask_ )].second;
						((global::encode.backward_references.Pair[]) (this.q_) )[( i & this.mask_ )].first = ((global::encode.backward_references.Pair[]) (this.q_) )[( ( i - 1 ) & this.mask_ )].first;
						((global::encode.backward_references.Pair[]) (this.q_) )[( i & this.mask_ )].second = ((global::encode.backward_references.Pair[]) (this.q_) )[( ( i - 1 ) & this.mask_ )].second;
						((global::encode.backward_references.Pair[]) (this.q_) )[( ( i - 1 ) & this.mask_ )].first = t1;
						((global::encode.backward_references.Pair[]) (this.q_) )[( ( i - 1 ) & this.mask_ )].second = t2;
					}
					
					 -- i;
				}
				
				 ++ this.idx_;
			}
		}
		
		
		public virtual int size() {
			unchecked {
				return ((int) (global::System.Math.Min(((double) (this.idx_) ), ((double) (( this.mask_ + 1 )) ))) );
			}
		}
		
		
		public virtual int GetStartPos(int k) {
			unchecked {
				return ((global::encode.backward_references.Pair[]) (this.q_) )[( ( ( this.idx_ - k ) - 1 ) & this.mask_ )].first;
			}
		}
		
		
		public int mask_;
		
		public global::encode.backward_references.Pair[] q_;
		
		public int idx_;
		
		public override double __hx_setField_f(string field, int hash, double @value, bool handleProperties) {
			unchecked {
				switch (hash) {
					case 1169404290:
					{
						this.idx_ = ((int) (@value) );
						return @value;
					}
					
					
					case 52596211:
					{
						this.mask_ = ((int) (@value) );
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
					case 1169404290:
					{
						this.idx_ = ((int) (global::haxe.lang.Runtime.toInt(@value)) );
						return @value;
					}
					
					
					case 25294:
					{
						this.q_ = ((global::encode.backward_references.Pair[]) (@value) );
						return @value;
					}
					
					
					case 52596211:
					{
						this.mask_ = ((int) (global::haxe.lang.Runtime.toInt(@value)) );
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
					case 1169404290:
					{
						return this.idx_;
					}
					
					
					case 25294:
					{
						return this.q_;
					}
					
					
					case 52596211:
					{
						return this.mask_;
					}
					
					
					case 1287611624:
					{
						return ((global::haxe.lang.Function) (new global::haxe.lang.Closure(this, "GetStartPos", 1287611624)) );
					}
					
					
					case 1280549057:
					{
						return ((global::haxe.lang.Function) (new global::haxe.lang.Closure(this, "size", 1280549057)) );
					}
					
					
					case 893009402:
					{
						return ((global::haxe.lang.Function) (new global::haxe.lang.Closure(this, "Push", 893009402)) );
					}
					
					
					case 1535697261:
					{
						return ((global::haxe.lang.Function) (new global::haxe.lang.Closure(this, "Clear", 1535697261)) );
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
					case 1169404290:
					{
						return ((double) (this.idx_) );
					}
					
					
					case 52596211:
					{
						return ((double) (this.mask_) );
					}
					
					
					default:
					{
						return base.__hx_getField_f(field, hash, throwErrors, handleProperties);
					}
					
				}
				
			}
		}
		
		
		public override object __hx_invokeField(string field, int hash, global::Array dynargs) {
			unchecked {
				switch (hash) {
					case 1287611624:
					{
						return this.GetStartPos(((int) (global::haxe.lang.Runtime.toInt(dynargs[0])) ));
					}
					
					
					case 1280549057:
					{
						return this.size();
					}
					
					
					case 893009402:
					{
						this.Push(((int) (global::haxe.lang.Runtime.toInt(dynargs[0])) ), ((double) (global::haxe.lang.Runtime.toDouble(dynargs[1])) ));
						break;
					}
					
					
					case 1535697261:
					{
						this.Clear();
						break;
					}
					
					
					default:
					{
						return base.__hx_invokeField(field, hash, dynargs);
					}
					
				}
				
				return null;
			}
		}
		
		
		public override void __hx_getFields(global::Array<object> baseArr) {
			baseArr.push("idx_");
			baseArr.push("q_");
			baseArr.push("mask_");
			base.__hx_getFields(baseArr);
		}
		
		
	}
}


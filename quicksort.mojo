from array import Array

# Comparison 'operator' for SIMD vectors.
@always_inline
fn lessthan[width: Int, AType: DType, steps: Int = width](lhs: SIMD[AType, width], rhs: SIMD[AType, width]) -> Bool:
    for i in range(steps):
        if lhs[i] < rhs[i]:
            return True
        if lhs[i] > rhs[i]:
            return False
    return False

# Implements Quicksort for SIMD vectors (not _using_ SIMD for anything, just sorting SIMD data)
# Supports partial sorting (set steps to less than width)
fn qsort[width: Int, AType: DType, steps: Int = width](inout a : Array[AType], start: Int = 0, end: Int = -1):
    var tend = end    
    if tend < 0:
        tend = a.dynamic_size // width
    if tend - start < 2:
        return
    # Use Lomuto-like midpoint scheme which also helps us sort 2/3 element ranges 'for free'
    mp = (start + tend)//2
    var a1 = a.load[width=width](start * width)
    var a2 = a.load[width=width](mp * width)
    # compare [mid] vs [lo]
    var s = 0
    if lessthan[width, AType, steps](a2, a1):
        t = a2
        a2 = a1
        a1 = t
        s += 1
    if tend - start == 2:
        if s > 0:
            a.store[width=width](start * width, a1)
            a.store[width=width](mp * width,a2)
        # print(a1,a2)
        return
    var a3 = a.load[width=width]((tend - 1) * width)
    # compare [hi] vs [lo]
    if lessthan[width, AType, steps](a3, a1):
        t = a3
        a3 = a1
        a1 = t
        s += 1
    # compare [mid] vs [lo]
    if lessthan[width, AType, steps](a3, a2):
        t = a3
        a3 = a2
        a2 = t
        s += 1
    if s > 0:        
        a.store[width=width](start * width, a1)
        a.store[width=width](mp * width, a2)
        a.store[width=width]((tend - 1) * width,a3)
    if tend - start == 3:
        return

    # Handle the rest with Hoare partitioning. 
    # The 3-point method above places the midpoint in the middle, 
    # rather than the end like normal Lomuto
    var i = start 
    var j = tend - 1
    while True:
        while lessthan(a1, a2):
            i += 1
            a1 = a.load[width=width](i * width)
        while lessthan(a2, a3):
            j -= 1
            a3 = a.load[width=width](j * width)
        if i >= j:
            break
        t = a3
        a3 = a1
        a1 = t
        a.store[width=width](i * width, a1)
        a.store[width=width](j * width, a3)
    
    # Recursive calls
    qsort[width, AType, steps](a, start, j + 1)
    qsort[width, AType, steps](a, j + 1, tend)


fn main():
    var buf = Array[DType.int32](40)
    for i in range(10):
        t = SIMD[DType.int32, 4](1000 - i//2, 1000 - i//3, i, 100 - i)
        buf.store[width=4](i * 4, t)
        print(t)
    print()
    qsort[4](buf)
    for i in range(10):
        print(buf.load[width=4](i*4))

    

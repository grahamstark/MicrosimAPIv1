using SHA

"""
    struct_hash(x) -> UInt64

Compute a hash value for any struct based on its field values.
Supports nested structs, arrays, and other collections.
Two instances will have equal hashes iff all their fields are recursively equal.
"""
function struct_hash(x)::UInt64
    _hash_to_u64(recursive_hash(x))
end

# Convert a SHA256 digest (Vector{UInt8}) to UInt64
function _hash_to_u64(digest::Vector{UInt8})::UInt64
    result = zero(UInt64)
    for i in 1:8
        result |= UInt64(digest[i]) << (8 * (i - 1))
    end
    return result
end

# Fallback: use Julia's built-in hash for primitives, then SHA-wrap it
function recursive_hash(x)::Vector{UInt8}
    if isa(x, Union{AbstractArray, AbstractSet, Tuple, NamedTuple})
        _hash_collection(x)
    elseif isa(x, AbstractDict)
        _hash_dict(x)
    elseif isstructtype(typeof(x)) && !isa(x, String) && !isa(x, Symbol)
        _hash_struct(x)
    else
        # Primitive or other — use Julia's built-in hash
        _hash_primitive(x)
    end
end

# Hash a struct by hashing its type name and each field recursively
function _hash_struct(x)::Vector{UInt8}
    ctx = SHA.SHA2_256_CTX()
    # Include the type name to distinguish structs with identical field values but different types
    SHA.update!(ctx, Vector{UInt8}(string(typeof(x))))
    for fname in fieldnames(typeof(x))
        field_val = getfield(x, fname)
        SHA.update!(ctx, recursive_hash(field_val))
    end
    return SHA.digest!(ctx)
end

# Hash any ordered collection (Array, Tuple, NamedTuple, Set, etc.)
function _hash_collection(x)::Vector{UInt8}
    ctx = SHA.SHA2_256_CTX()
    SHA.update!(ctx, Vector{UInt8}(string(typeof(x))))
    for item in x
        SHA.update!(ctx, recursive_hash(item))
    end
    return SHA.digest!(ctx)
end

# Hash a Dict — sort by key hash for determinism
function _hash_dict(x::AbstractDict)::Vector{UInt8}
    ctx = SHA.SHA2_256_CTX()
    SHA.update!(ctx, Vector{UInt8}(string(typeof(x))))
    # Sort entries by the hash of each key for a stable ordering
    sorted_pairs = sort(collect(x), by = kv -> recursive_hash(kv[1]))
    for (k, v) in sorted_pairs
        SHA.update!(ctx, recursive_hash(k))
        SHA.update!(ctx, recursive_hash(v))
    end
    return SHA.digest!(ctx)
end

# Hash a primitive via Julia's built-in hash, then encode to bytes
function _hash_primitive(x)::Vector{UInt8}
    h = hash(x)  # Julia's built-in hash -> UInt64
    return [UInt8((h >> (8 * i)) & 0xFF) for i in 0:7]
end

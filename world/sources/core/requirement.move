/// A `Requirement` is the atomic checkbox of the request/requirement pattern:
/// a `(TypeName, bytes)` pair that names the service authorised to satisfy it
/// and carries any data that service needs (e.g. expected item id and qty).
///
/// Only the module that declares `T` can mint `internal::Permit<T>`, and only a
/// holder of that permit can tick a requirement of type `T` off a request. The
/// payload bytes are opaque to the core: services BCS-encode whatever shape
/// they need.
module world::requirement;

use std::{bcs, type_name::{Self, TypeName}};

/// A requirement is a tuple of a type name and a vector of bytes.
/// Bytes can be anything: a bcs-encoded data, a hash or a simple boolean.
public struct Requirement(TypeName, vector<u8>) has copy, drop, store;

/// Create a new requirement for the given type and data.
public fun new<T>(data: vector<u8>): Requirement {
    Requirement(type_name::with_original_ids<T>(), data)
}

/// Create a new requirement from a config object.
public fun from_config<T: drop>(c: T): Requirement {
    new<T>(bcs::to_bytes(&c))
}

/// Check if the requirement is for the given type.
public fun is<T>(r: &Requirement): bool {
    r.0 == type_name::with_original_ids<T>()
}

/// Get the type name of the requirement.
public fun type_name(r: &Requirement): TypeName { r.0 }

/// Get the data of the requirement.
public fun data(r: &Requirement): vector<u8> { r.1 }

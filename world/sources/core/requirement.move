/// A `Requirement` is the atomic checkbox of the request/requirement pattern:
/// a `(TypeName, bytes)` pair that names the service authorised to satisfy it
/// and carries any data that service needs (e.g. expected item id and qty).
///
/// Only the module that declares `T` can mint `internal::Permit<T>`, and only a
/// holder of that permit can tick a requirement of type `T` off a request. The
/// payload bytes are opaque to the core: services BCS-encode whatever shape
/// they need.
module world::requirement;

use std::type_name::{Self, TypeName};

public struct Requirement(TypeName, vector<u8>) has copy, drop, store;

public fun new<T>(data: vector<u8>): Requirement {
    Requirement(type_name::with_original_ids<T>(), data)
}

public fun is<T>(r: &Requirement): bool {
    r.0 == type_name::with_original_ids<T>()
}

public fun type_name(r: &Requirement): TypeName { r.0 }

public fun data(r: &Requirement): vector<u8> { r.1 }

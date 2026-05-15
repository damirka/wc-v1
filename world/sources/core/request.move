/// `Request` is a hot-potato carrying the open requirements for an
/// action. It has no `drop`; the only legal disposal is `complete`, which
/// aborts unless every requirement was ticked. This guarantees that a
/// state-mutating action cannot proceed past tx boundaries with rules unmet.
///
/// Construction is `public(package)`: only hardware/firmware modules in this
/// package may open a request. Verifiers tick slots with `complete_requirement<T>`
/// using a `Permit<T>` that only the declaring module can mint.
module world::request;

use std::string::String;
use world::requirement::Requirement;

const VERSION: u64 = 1;

#[error(code = 1)]
const ERequirementsRemain: vector<u8> = "Cannot complete: requirements remain";
#[error(code = 2)]
const ERequirementNotFound: vector<u8> = "No matching requirement to complete";
#[error(code = 3)]
const EVersionMismatch: vector<u8> = "Request version mismatch";

/// Request is a hot-potato carrying the open requirements for an action.
public struct Request {
    action: String, // TODO: having string is vulnerable, can we have TypeName instead ?
    version: u64,
    structure_id: Option<ID>,
    requires: vector<Requirement>,
}

/// Service-side: tick off the first requirement matching type `T`. Aborts if
/// none exists. The `Permit<T>` argument means only the declaring module can
/// call this for `T`.
public fun complete_requirement<T>(req: &mut Request, _: internal::Permit<T>): Requirement {
    let idx = req.requires.find_index!(|r| r.is<T>());
    assert!(idx.is_some(), ERequirementNotFound);
    req.requires.swap_remove(idx.destroy_some())
}

/// Dispose of the hot potato. Aborts if any requirement remains.
public fun complete(req: Request) {
    let Request { requires, version, .. } = req;
    assert!(requires.length() == 0, ERequirementsRemain);
    assert!(version == VERSION, EVersionMismatch);
}

/// Get the `version` of the Request.
public fun version(req: &Request): u64 { req.version }

/// Get the `action` of the Request.
public fun action(req: &Request): String { req.action }

/// Get the `structure_id` of the Request.
public fun structure_id(req: &Request): Option<ID> { req.structure_id }

/// Get the length of the requirements vector.
public fun remaining(req: &Request): u64 { req.requires.length() }

// === Builder API ===

/// A builder for `ApplicationRequest`.
public struct RequestBuilder {
    action: String,
    version: Option<u64>,
    structure_id: Option<ID>,
    requires: vector<Requirement>,
}

/// Initialize a new `RequestBuilder` with the given action.
public fun new(action: String): RequestBuilder {
    RequestBuilder {
        action,
        structure_id: option::none(),
        requires: vector[],
        version: option::none(),
    }
}

/// Set the assembly ID of the request.
public fun with_structure_id(mut builder: RequestBuilder, structure_id: ID): RequestBuilder {
    builder.structure_id = option::some(structure_id);
    builder
}

/// Add a requirement to the request.
public fun with_requirement(mut builder: RequestBuilder, requirement: Requirement): RequestBuilder {
    builder.requires.push_back(requirement);
    builder
}

/// Set the version of the request. If not set, the default version will be used.
public fun with_version(mut builder: RequestBuilder, version: u64): RequestBuilder {
    builder.version.fill(version); // will fail if already set
    builder
}

/// Build the `ApplicationRequest` from the builder.
public fun build(builder: RequestBuilder, _ctx: &mut TxContext): Request {
    let RequestBuilder { action, structure_id, requires, version } = builder;

    Request {
        action,
        requires,
        structure_id,
        version: version.destroy_or!(VERSION),
    }
}

// === For Testing ===

public(package) fun complete_ignore(r: Request) {
    let Request { .. } = r;
}

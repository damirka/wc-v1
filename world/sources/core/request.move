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

#[error(code = 1)]
const ERequirementsRemain: vector<u8> = b"Cannot complete: requirements remain";

#[error(code = 2)]
const ERequirementNotFound: vector<u8> = b"No matching requirement to complete";

/// Request is a hot-potato carrying the open requirements for an action.
public struct Request {
    action: String, // TODO: having string is vulenrable,  can we have TypeName instead ?
    structure_id: Option<ID>,
    requires: vector<Requirement>,
}

public(package) fun new(
    action: String, 
    structure_id: Option<ID>,
    requires: vector<Requirement>, 
): Request {
    Request { action, structure_id, requires }
}

/// Append a firmware default requirement after the request has been opened.
/// Used by firmware code to add per-action rules that the action cannot run
/// without (e.g. `HasItem` on `deposit`), on top of the base + owner-attached
/// requirements folded in by `interact_module`.
public fun add_default_requirement(req: &mut Request, r: Requirement) {
    req.requires.push_back(r);
}

/// Service-side: tick off the first requirement matching type `T`. Aborts if
/// none exists. The `Permit<T>` argument means only the declaring module can
/// call this for `T`.
public fun complete_requirement<T>(
    req: &mut Request,
    _: internal::Permit<T>,
): Requirement {
    let idx = req.requires.find_index!(|r| r.is<T>());
    assert!(idx.is_some(), ERequirementNotFound);
    req.requires.swap_remove(idx.destroy_some())
}

/// Dispose of the hot potato. Aborts if any requirement remains.
public fun complete(req: Request) {
    let Request { requires, .. } = req;
    assert!(requires.length() == 0, ERequirementsRemain);
}

public fun action(req: &Request): String { req.action }
public fun structure_id(req: &Request): Option<ID> { req.structure_id }
public fun remaining(req: &Request): u64 { req.requires.length() }

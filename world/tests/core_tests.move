#[test_only]
module world::core_tests;

use world::request;
use world::requirement;

/// Two unrelated marker types acting as stand-in services. Only this test
/// module can mint `Permit<RuleA>` / `Permit<RuleB>`.
public struct RuleA has drop {}
public struct RuleB has drop {}

fun open_request(rs: vector<vector<u8>>): request::Request {
    let mut requires = vector[];
    let mut i = 0;
    while (i < rs.length()) {
        let tag = rs[i];
        if (tag == b"A") requires.push_back(requirement::new<RuleA>(vector[]))
        else requires.push_back(requirement::new<RuleB>(vector[]));
        i = i + 1;
    };
    request::new(b"test:action".to_string(), option::none(), requires)
}

#[test]
fun complete_after_all_requirements_ticked() {
    let mut req = open_request(vector[b"A", b"B"]);
    assert!(req.remaining() == 2);

    req.complete_requirement<RuleA>(internal::permit());
    req.complete_requirement<RuleB>(internal::permit());
    assert!(req.remaining() == 0);

    req.complete();
}

#[test]
fun add_default_requirement_extends_request() {
    let mut req = open_request(vector[b"A"]);
    req.add_default_requirement(requirement::new<RuleB>(vector[1, 2, 3]));
    assert!(req.remaining() == 2);

    req.complete_requirement<RuleA>(internal::permit());
    let r = req.complete_requirement<RuleB>(internal::permit());
    assert!(r.data() == vector[1, 2, 3]);
    req.complete();
}

#[test, expected_failure(abort_code = request::ERequirementsRemain)]
fun complete_aborts_when_requirements_remain() {
    let req = open_request(vector[b"A"]);
    req.complete();
}

#[test, expected_failure(abort_code = request::ERequirementNotFound)]
fun complete_requirement_aborts_when_type_absent() {
    let mut req = open_request(vector[b"A"]);
    req.complete_requirement<RuleB>(internal::permit());
    abort
}

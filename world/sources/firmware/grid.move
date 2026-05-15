#[allow(unused)]
module world::grid;

use ptb::ptb;
use world::{requirement::{Self, Requirement}, structure::Structure};

public struct Grid has store {
    supply: u32,
    used_supply: u32,
    // stores connected structures, normally should be self, but
    // in case a module in S1 connects to Grid in S2, we want to
    // catch and program against this behavior
    connections: vector<ID>,
}

public struct Link(ID, u32)

public(package) fun new(_ctx: &mut TxContext): Grid {
    Grid {
        supply: 1000, // TODO: make me 0
        used_supply: 0,
        connections: vector<ID>,
    }
}

public(package) fun add_power(g: &mut Grid, supply: u32) {
    g.supply = g.supply + supply;
}

public(package) fun reserve(g: &mut Grid, reserve_amt: u32) {
    assert!(g.supply >= reserve_amt);
    g.used_supply = g.used_supply + reserve_amt;
}

// === Requirement ===

public struct IsPowered() has drop;
public struct AvailablePower(u32) has drop;

public fun is_powered_requirement(): Requirement {
    requirement::from_config(IsPowered())
}

public fun available_power(num: u32): Requirement {
    requirement::from_config(AvailablePower(num))
}

// === PTB Templates ===

#[allow(unused_function)]
fun ptb_available_power(s: &Structure, mut ptb: ptb::Transaction): ptb::Transaction {
    let package_id = std::type_name::defining_id<AvailablePower>();

    ptb.command(
        ptb::move_call(
            package_id.to_string(),
            "grid",
            "verify_available_power",
            vector[],
            vector[],
        ),
    );

    ptb
}

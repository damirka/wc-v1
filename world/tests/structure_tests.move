// #[test_only]
// module world::structure_tests;

// use sui::test_scenario as ts;
// use world::structure::{Self, Structure, StructureConfig, Anchor, OwnerCap};
// use world::system_service;
// use world::admin_acl;
// use world::transport::{Self, Jump};
// use world::location_service::{Self, IsProximity};
// use world::jump_permit::{Self, JumpPermit};

// const ADMIN: address = @0xA071;
// const PLAYER: address = @0xA11CE;

// #[test]
// fun anchor() {
//     let mut sc = ts::begin(ADMIN);
//     structure::init_for_testing(sc.ctx()); // shares StructureConfig, adds SystemAuthorization
//     sc.next_tx(PLAYER);

//     let cfg = sc.take_shared<StructureConfig>();
//     let (s, mut req) = structure::anchor(&cfg, sc.ctx());

//     assert!(req.remaining() == 1);                   // SystemAuthorization

//     let acl = admin_acl::init_for_testing(sc.ctx());
//     system_service::is_authorized(&mut req, &acl, sc.ctx());
//     req.complete();

//     structure::share(s);
//     ts::return_shared(cfg);
//     admin_acl::destroy_for_testing(acl);
//     sc.end();
// }

// #[test, expected_failure(abort_code = world::structure::ENotAuthorized)]
// fun non_admin_cannot_add_rule() {
//     let mut sc = ts::begin(ADMIN);
//     let acl = admin_acl::init_for_testing(sc.ctx());
//     structure::init_for_testing(sc.ctx());
//     sc.next_tx(PLAYER);

//     let mut cfg = sc.take_shared<StructureConfig>();
//     structure::add_requirement<Anchor>(
//         &mut cfg, &acl, system_service::requirement(), sc.ctx(),
//     );

//     abort
// }

// #[test]
// fun admin_can_remove_seeded_rule_so_anchor_has_zero_requirements() {
//     let mut sc = ts::begin(ADMIN);
//     let acl = admin_acl::init_for_testing(sc.ctx());
//     structure::init_for_testing(sc.ctx());
//     sc.next_tx(ADMIN);

//     let mut cfg = sc.take_shared<StructureConfig>();
//     structure::remove_requirement<Anchor>(
//         &mut cfg, &acl, system_service::requirement(), sc.ctx(),
//     );
//     sc.next_tx(PLAYER);
//     let (s, req) = structure::anchor(&cfg, sc.ctx());
//     assert!(req.remaining() == 0);
//     req.complete();

//     admin_acl::destroy_for_testing(acl);
//     ts::return_shared(cfg);
//     structure::share(s);
//     sc.end();
// }

// #[test]
// fun transport_can_be_attached_to_structure() {
//     let mut sc = ts::begin(ADMIN);
//     let acl = admin_acl::init_for_testing(sc.ctx());
//     structure::init_for_testing(sc.ctx());

//     sc.next_tx(ADMIN);
//     let cfg = sc.take_shared<StructureConfig>();
//     let (mut s, mut req) = structure::anchor(&cfg, sc.ctx());

//     system_service::is_authorized(&mut req, &acl, sc.ctx());
//     req.complete();
//     ts::return_shared(cfg);
//     structure::share(s);

//     sc.next_tx(ADMIN);
//     let owner_cap = sc.take_from_sender<OwnerCap>();
//     transfer::public_transfer(owner_cap, PLAYER);
//     let mut s = sc.take_shared<Structure>();
//     transport::attach(&mut s, &acl, sc.ctx());
//     transport::add_default_requirement<Jump>(&mut s, &acl, location_service::requirement(), sc.ctx());
//     ts::return_shared(s);

//     sc.next_tx(PLAYER);
//     let mut s = sc.take_shared<Structure>();

//     // add custom requirement by a player to the transport module
//     let permit = jump_permit::mint_jump_permit(&s, sc.ctx());
//     let owner_cap = sc.take_from_sender<OwnerCap>();
//     transport::add_custom_requirement<Jump>(&mut s, &owner_cap, jump_permit::requirement(), sc.ctx());

//     let mut req = transport::jump(&s, sc.ctx());
//     location_service::verify_proximity(&mut req, sc.ctx());
//     jump_permit::verify_need_jump_permit(&mut req, &permit, sc.ctx());
//     req.complete();
//     ts::return_shared(s);
//     transfer::public_transfer(permit, PLAYER);
//     sc.return_to_sender(owner_cap);

//     admin_acl::destroy_for_testing(acl);
//     sc.end();
// }

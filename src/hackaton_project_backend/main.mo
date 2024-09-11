import Icrc1Ledger "canister:icrc1_ledger_canister";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Array "mo:base/Array"

actor {

  var allowedPrincipal : ?Principal = null;

  public func getAllowedPrincipal() : async ?Principal {
    return allowedPrincipal;
  };

  type TransferArgs = {
    amounts : [Nat];
    toAccounts : [Icrc1Ledger.Account];
  };

  public shared ({ caller }) func transferPrivilege(newPrincipal : Principal) {
    switch (allowedPrincipal) {
      case (?currentPrincipal) {
        if (caller != currentPrincipal) {
          throw Error.reject("Unauthorized.");
        };
      };
      case null {
        //If there is no allowed Principal: Authorized.
      };
    };
    Debug.print(
        "Transferring Privilege to: "
        # debug_show (newPrincipal)
      );
    allowedPrincipal := ?newPrincipal;
  };

  public shared ({ caller }) func bulkTransfer(args : TransferArgs) : async [Result.Result<Icrc1Ledger.BlockIndex, Text>] {

    assert (args.amounts.size() == args.toAccounts.size());

    switch (allowedPrincipal) {
      case (?currentPrincipal) {
        if (caller != currentPrincipal) {
          throw Error.reject("Unauthorized.");
        };
      };
      case null {
        throw Error.reject("No principal is currently allowed.");
      };
    };

    var results : [Result.Result<Icrc1Ledger.BlockIndex, Text>] = [];

    for (i in args.amounts.keys()) {

      Debug.print(
        "Transferring "
        # debug_show (args.amounts[i])
        # " tokens to account"
        # debug_show (args.toAccounts[i])
      );

      let transferArgs : Icrc1Ledger.TransferArg = {
        memo = null;
        amount = args.amounts[i];
        from_subaccount = null;
        fee = null;
        to = args.toAccounts[i];
        created_at_time = null;
      };

      try {
        let transferResult = await Icrc1Ledger.icrc1_transfer(transferArgs);

        switch (transferResult) {
          case (#Err(transferError)) {
            results := Array.append(results, [#err("Couldn't transfer funds:\n" # debug_show (transferError))]);
          };
          case (#Ok(blockIndex)) {
            results := Array.append(results, [#ok blockIndex]);
          };
        };
      } catch (error : Error) {
        results := Array.append(results, [#err("Reject message: " # Error.message(error))]);
      };

    };

    return results;
  };
};

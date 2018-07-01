/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./StandardToken.sol";
import "./UpgradeableToken.sol";
import "./ReleasableToken.sol";
import "./MintableTokenExt.sol";


/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract CrowdsaleTokenExt_v1 is ReleasableToken, MintableTokenExt, UpgradeableToken {

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string newName, string newSymbol);

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

  string public name;

  string public symbol;

  uint public decimals;

  /* Minimum ammount of tokens every buyer can buy. */
  uint public minCap;

  uint public originalSupply;

  address public oldTokenAddress;

  bool public isUpgradeAgent = false;
  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   */
  function CrowdsaleTokenExt_v1(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap, address _oldTokenAddress)
    UpgradeableToken(msg.sender) {

    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    // also remember to call setUpgradeMaster()
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    originalSupply = _initialSupply;
    oldTokenAddress = _oldTokenAddress;

    decimals = _decimals;

    minCap = _globalMinCap;

    // Create initially all balance on the team multisig
    balances[owner] = totalSupply;
    isUpgradeAgent = true;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw; // Cannot create a token without supply and no minting
      }
    }
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  /**
   * Allow upgrade agent functionality kick in only if the crowdsale was success.
   */
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

  /**
   * Owner can update token information here.
   *
   * It is often useful to conceal the actual token association, until
   * the token operations, like central issuance or reissuance have been completed.
   *
   * This function allows the token owner to rename the token after the operations
   * have been completed and then point the audience to use the token contract.
   */
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

  /**
   * Claim tokens that were accidentally sent to this contract.
   *
   * @param _token The address of the token contract that you want to recover.
   */
  function claimTokens(address _token) public onlyOwner {
    require(_token != address(0));

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);

    ClaimedTokens(_token, owner, balance);
  }

  function upgradeFrom(address _from, uint256 value) public {
      // Make sure the call is from old token contract
      require(msg.sender == oldTokenAddress);
      // Validate input value.
      balances[_from] = safeAdd(balances[_from], value);
      // Take tokens out from circulation
      totalSupply = safeAdd(totalSupply, value);
    }

}

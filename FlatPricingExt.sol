/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.12;

import "./Ownable.sol";
import "./PricingStrategy.sol";
import "./SafeMathLibExt.sol";


/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract FlatPricingExt is PricingStrategy, Ownable {
  using SafeMathLibExt for uint;

  /* How many weis one token costs */
  uint public oneTokenInWei;

  // Crowdsale rate has been changed
  event RateChanged(uint newOneTokenInWei);

  modifier onlyTier() {
    if (msg.sender != address(tier)) throw;
    _;
  }

  function setTier(address _tier) onlyOwner {
    assert(_tier != address(0));
    assert(tier == address(0));
    tier = _tier;
  }

  function FlatPricingExt(uint _oneTokenInWei) onlyOwner {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;
  }

  function updateRate(uint newOneTokenInWei) onlyTier {
    oneTokenInWei = newOneTokenInWei;
    RateChanged(newOneTokenInWei);
  }

  /**
   * Calculate the current price for buy in amount.
   *
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.times(multiplier) / oneTokenInWei;
  }

}

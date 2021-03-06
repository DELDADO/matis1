pragma solidity 0.6.4;

import "./IRelayerIncentivize.sol";


contract RelayerIncentivize is IRelayerIncentivize {

  uint256 constant roundSize=1000;
  uint256 constant maximumWeight=400;

  mapping( uint256 => mapping(address => uint256) ) public _headerRelayersSubmitCount;
  mapping( uint256 => address payable[] ) public _headerRelayerAddressRecord;

  mapping( uint256 => mapping(address => uint256) ) public _transferRelayersSubmitCount;
  mapping( uint256 => address payable[] ) public _transferRelayerAddressRecord;

  mapping( uint256 => uint256) public _collectedRewardForHeaderRelayerPerRound;
  mapping( uint256 => uint256) public _collectedRewardForTransferRelayerPerRound;

  uint256 public _roundSequence = 0;
  uint256 public _countInRound=0;

  event LogRewardPeriodExpire(uint256 sequence, uint256 roundHeaderRelayerReward, uint256 roundTransferRelayerReward);

  function addReward(address payable headerRelayerAddr, address payable caller) external override payable returns (bool) {
    _countInRound++;

    uint256 reward = calculateRewardForHeaderRelayer(msg.value);
    _collectedRewardForHeaderRelayerPerRound[_roundSequence] += reward;
    _collectedRewardForTransferRelayerPerRound[_roundSequence] += msg.value - reward;

    if (_headerRelayersSubmitCount[_roundSequence][headerRelayerAddr]==0){
      _headerRelayerAddressRecord[_roundSequence].push(headerRelayerAddr);
    }
    _headerRelayersSubmitCount[_roundSequence][headerRelayerAddr]++;

    if (_transferRelayersSubmitCount[_roundSequence][caller]==0){
      _transferRelayerAddressRecord[_roundSequence].push(caller);
    }
    _transferRelayersSubmitCount[_roundSequence][caller]++;

    if (_countInRound==roundSize){
      emit LogRewardPeriodExpire(_roundSequence, _collectedRewardForHeaderRelayerPerRound[_roundSequence], _collectedRewardForTransferRelayerPerRound[_roundSequence]);

      claimHeaderRelayerReward(_roundSequence, caller);
      claimTransferRelayerReward(_roundSequence, caller);

      _roundSequence++;
      _countInRound = 0;
    }
    return true;
  }

  //TODO need further discussion
  function calculateRewardForHeaderRelayer(uint256 reward) internal pure returns (uint256) {
    return reward/5; //20%
  }

  function claimHeaderRelayerReward(uint256 sequence, address payable caller) internal returns (bool) {
    uint256 totalReward = _collectedRewardForHeaderRelayerPerRound[sequence];

    address payable[] memory relayers = _headerRelayerAddressRecord[sequence];
    uint256[] memory relayerWeight = new uint256[](relayers.length);
    for(uint256 index = 0; index < relayers.length; index++) {
      address relayer = relayers[index];
      uint256 weight = calculateHeaderRelayerWeight(_headerRelayersSubmitCount[sequence][relayer]);
      relayerWeight[index] = weight;
    }

    uint256 callerReward = totalReward * 5/100; //TODO need further discussion
    totalReward = totalReward - callerReward;
    uint256 remainReward = totalReward;
    for(uint256 index = 1; index < relayers.length; index++) {
      uint256 reward = relayerWeight[index]*totalReward/roundSize;
      relayers[index].transfer(reward);
      remainReward = remainReward-reward;
    }
    relayers[0].transfer(remainReward);
    caller.transfer(callerReward);

    delete _collectedRewardForHeaderRelayerPerRound[sequence];
    for (uint256 index = 0; index < relayers.length; index++){
      delete _headerRelayersSubmitCount[sequence][relayers[index]];
    }
    delete _headerRelayerAddressRecord[sequence];
    return true;
  }

  function claimTransferRelayerReward(uint256 sequence, address payable caller) internal returns (bool) {
    uint256 totalReward = _collectedRewardForTransferRelayerPerRound[sequence];

    address payable[] memory relayers = _transferRelayerAddressRecord[sequence];
    uint256[] memory relayerWeight = new uint256[](relayers.length);
    for(uint256 index = 0; index < relayers.length; index++) {
      address relayer = relayers[index];
      uint256 weight = calculateTransferRelayerWeight(_transferRelayersSubmitCount[sequence][relayer]);
      relayerWeight[index] = weight;
    }

    uint256 callerReward = totalReward * 5/100; //TODO need further discussion
    totalReward = totalReward - callerReward;
    uint256 remainReward = totalReward;
    for(uint256 index = 1; index < relayers.length; index++) {
      uint256 reward = relayerWeight[index]*totalReward/roundSize;
      relayers[index].transfer(reward);
      remainReward = remainReward-reward;
    }
    relayers[0].transfer(remainReward);
    caller.transfer(callerReward);

    delete _collectedRewardForTransferRelayerPerRound[sequence];
    for (uint256 index = 0; index < relayers.length; index++){
      delete _transferRelayersSubmitCount[sequence][relayers[index]];
    }
    delete _transferRelayerAddressRecord[sequence];
    return true;
  }

  function calculateTransferRelayerWeight(uint256 count) public pure returns(uint256) {
    if (count <= maximumWeight) {
      return count;
    } else if (maximumWeight < count && count <= 2*maximumWeight) {
      return maximumWeight;
    } else if (2*maximumWeight < count && count <= (2*maximumWeight + 3*maximumWeight/4 )) {
      return 3*maximumWeight - count;
    } else {
      return count/4;
    }
  }

  function calculateHeaderRelayerWeight(uint256 count) public pure returns(uint256) {
    if (count <= maximumWeight) {
      return count;
    } else if (maximumWeight < count && count <= 2*maximumWeight) {
      return maximumWeight;
    } else {
      return maximumWeight;
    }
  }
}
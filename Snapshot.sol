// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

// Interface for the Staker contract
interface IStaker {
    function balances(address _staker) external view returns (uint256);
    function participants(uint256 _index) external view returns (address);
    function numberOfParticipants() external view returns (uint256);
}

contract farmSnapshot is Ownable {
    using ABDKMath64x64 for uint256;

    address public harvester;
    uint256 public activeFarmersLength;
    
    struct Record {
        uint256 balance;
        uint256 timestamp;
    }

    mapping(address => bool) public ActiveFarmers;
    mapping(address => Record) public Records; 

    constructor(
        address harvester_
    ) {
        harvester = harvester_;
    }

    function snapShot() external onlyOwner {
        IStaker staker = IStaker(harvester);
        uint256 numberOfParticipants = staker.numberOfParticipants(); 

        for (uint256 i = 0; i < numberOfParticipants; i++) {
            address participant = staker.participants(i);
            uint256 balance = staker.balances(participant);
            uint256 threshold = 1_000_000 * 1e18;

            if (balance > threshold) {
                ActiveFarmers[participant] = true;
                Records[participant] = Record(balance, block.timestamp);
                ++activeFarmersLength;
            }
        }
    }

}
